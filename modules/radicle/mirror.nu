# Mirrors every non-fork GitHub repository owned by the account behind the
# token into the local Radicle node. Runs as the radicle user with RAD_HOME
# pointing at the node's home.
#
# GitHub private repositories become private Radicle repositories with a
# "block" seeding policy, so the node keeps them in storage but serves them to
# no peer. Radicle 1.x transport sends data in plaintext and lets a peer claim
# any Node ID, including this node's own, which is the allow-listed delegate:
# https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol

def clip-bytes [max: int]: string -> string {
  mut chars = $in | split chars
  while ($chars | str join | encode utf8 | bytes length) > $max {
    $chars = $chars | drop 1
  }
  $chars | str join
}

# Radicle visibility for a GitHub visibility. Internal repositories are not
# public, so they are treated as private.
def radicle-visibility []: string -> string {
  match $in {
    "PUBLIC" => "public"
    "PRIVATE" | "INTERNAL" => "private"
    $other => { error make {msg: $"unknown visibility ($other)"} }
  }
}

def mirror [repo: record, repos_dir: path] {
  let slug = $repo.nameWithOwner
  let branch = $repo.defaultBranchRef.name
  # Radicle rejects descriptions over 255 bytes; GitHub allows 350 characters.
  let description = $repo.description | default "" | clip-bytes 255

  # Keyed by the GitHub node ID so that a renamed repository keeps its RID.
  # Hex because legacy node IDs are base64 and can contain '/'.
  let git_dir = $repos_dir | path join $"($repo.id | into binary | encode hex).git"
  let origin = $"https://github.com/($slug).git"
  if not ($git_dir | path exists) {
    ^git init --quiet --bare $git_dir
    ^git --git-dir $git_dir remote add origin $origin
  }
  ^git --git-dir $git_dir remote set-url origin $origin
  ^git --git-dir $git_dir symbolic-ref HEAD $"refs/heads/($branch)"

  # Heads and tags only: GitHub also serves refs/pull/*, which are not ours.
  let refspecs = ["+refs/heads/*:refs/heads/*" "+refs/tags/*:refs/tags/*"]
  (^git --git-dir $git_dir -c credential.helper= -c "credential.helper=!gh auth git-credential"
    fetch --quiet --prune origin ...$refspecs)

  # Read after the fetch rather than from the listing, which a long run can
  # reach an hour later: every fetched commit was public when this ran.
  let visibility = (^gh api graphql
    -f 'query=query($id: ID!) { node(id: $id) { ... on Repository { visibility } } }'
    -f $"id=($repo.id)" --jq .data.node.visibility)
    | str trim
    | radicle-visibility

  if (^git --git-dir $git_dir config get --default "" remote.rad.url | str trim | is-empty) {
    print $"($slug): creating ($visibility) repository"
    # The `=` forms keep a value starting with '-' from parsing as a flag.
    (^rad init $"--name=($repo.name)" $"--description=($description)"
      $"--default-branch=($branch)" $"--($visibility)" --no-seed --no-confirm $git_dir)
  }
  let rid = (^git --git-dir $git_dir config get remote.rad.url
    | str trim
    | str replace --regex '^rad://' 'rad:')

  let doc = ^rad inspect --identity $rid | from json
  # The identity document omits visibility for public repositories.
  let current_visibility = $doc.visibility?.type? | default "public"

  # Blocked before the push so that a repository made private on GitHub is not
  # served while its new commits reach the node. `rad seed` leaves an existing
  # block in place, so a repository made public has its block removed here and
  # is seeded after the push. Until then the node's default policy, block,
  # applies. Output goes to /dev/null rather than through `ignore`, which
  # discards a non-zero exit.
  if $visibility == "private" {
    ^rad block $rid o> /dev/null
  } else if $current_visibility == "private" {
    ^rad unseed $rid o> /dev/null
  }

  # A new default branch must be named in the identity before the push below
  # can prune the old one.
  let project = $doc.payload."xyz.radicle.project"
  let payload_args = {name: $repo.name, description: $description, defaultBranch: $branch}
    | items {|key, value|
      if ($project | get --optional $key) == $value { [] } else {
        [--payload xyz.radicle.project $key ($value | to json --raw)]
      }
    }
    | flatten
  let visibility_args = if $current_visibility == $visibility { [] } else {
    [--visibility $visibility]
  }
  let update = $visibility_args ++ $payload_args
  if ($update | is-not-empty) {
    print $"($slug): updating identity: ($update | str join ' ')"
    ^rad id update --repo $rid --title "Synchronize with GitHub" --no-confirm --quiet ...$update
  }

  # The node refuses to delete the old default branch until the new one has
  # been pushed, so pruning waits for a second push.
  ^git --git-dir $git_dir push --quiet rad ...$refspecs
  ^git --git-dir $git_dir push --quiet --prune rad ...$refspecs

  if $visibility == "public" {
    ^rad seed --no-fetch --scope all $rid o> /dev/null
  }
}

def main [] {
  $env.GH_TOKEN = open --raw ($env.CREDENTIALS_DIRECTORY | path join github-token) | str trim
  let repos_dir = $env.STATE_DIRECTORY | path join repos
  mkdir $repos_dir

  let repos = (^gh repo list --source --limit 100000
    --json id,name,nameWithOwner,isEmpty,description,defaultBranchRef)
    | from json
    | where not isEmpty

  let failed = $repos | each {|repo|
    try {
      mirror $repo $repos_dir
      null
    } catch {|err|
      print --stderr $"($repo.nameWithOwner): ($err.msg)"
      $repo.nameWithOwner
    }
  } | compact

  if ($failed | is-not-empty) {
    error make {msg: $"failed to mirror: ($failed | str join ', ')"}
  }
}
