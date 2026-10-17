## Version control

- If a repo is jj-colocated, use `jj`, not `git`, as the authoritative interface.
- Never append `Co-Authored-By` or any AI attribution to commit messages.
- Make focused commits, one per logical change or milestone.
- Do not add deep unnecessarily technical descriptions unless warranted to explain why a non-obvious change occurred.

## Coding Style

- When reading or writing Rust code, you MUST first read `RUST.md` beside this file: `~/.config/claude-code/RUST.md` for Claude Code, `~/.codex/RUST.md` for Codex. Its rules add to these.

### Types and data modeling

- Prefer newtypes over raw primitives for domain values, even when the value arrives as a primitive. Wrap identifiers and any quantities that could be confused with each other (angles together with their unit, bitflags, durations, indices, weapon groups) in distinct newtypes so the type system rejects mixing them.
- Model "absent" or "unlimited" with an optional type or an enum, never sentinel values like `-1`, `0`, or empty string.
- Propagate optional and fallible values as far as practical. Resolve them at the boundary where there is enough context to handle them correctly.
- Typestates over runtime checks where state transitions are known at compile time. The login flow (`SteamClient<Encrypted>` to `SteamClient<LoggedIn>`) is the model.
- No bare tuples for anything with more than two fields, or two fields that are confusable. Use a struct with named fields.

### Defaults and missing data

- Do not paper over malformed or absent input with a default unless that default is genuinely correct. When it is, document why at the call site. Otherwise propagate the error or the option.

### Errors

- Use typed errors with structured fields.
- Never parse an error's message to recover data. If meaningful data is only reachable that way, the error type is wrong. Add a field.

### Comments

- Comments explain non-obvious intent only. Keep them terse and DRY.
- No salesmanship or filler wording.
- No historical framing ("now X", "was Y, now Z"). Describe current behavior.
- No numbered step-recaps of the implementation. Short WHY lines only.

### Text and formatting

- ASCII only in code, comments, UI strings, and commit messages. No emdash, endash, ellipsis, arrows, or other unicode symbols.
- No separator or banner comments (`// ---`, `// ===`, long dashed/equals rules, section dividers). Structure code with modules, functions, and blank lines, not comment dividers.
- Use only technical language you'd find in an IBM manual from the 1970s. No slang, casual shorthand, cute or clever names, no borrowed words from chat culture. Be succinct and clear. For example, do not use phrases like "golden snapshot". Another example: a script which updates build data should be named `update_build_data.sh` and not `push_build_data.sh`.
- Do not include unnecessary details. No, "The X describes the Y" type phrases or "caveats" unless asked for it.
- Commit messages should be short. Do not include unnecessary details in the longform commit message. Generally the commit details should just not even be included unless there is necessary context behind a change. Otherwise the commit title should speak for itself.

### Tests

- Snapshot tests should be preferred in scenarios where data is being deserialized or parsed.
- Tautological tests considered harmful.
- If using `buck2`, prefer to use `InternalRunnerTestInfo` for making tests first-class buck citizens

### Build systems

- Generally we'll use `buck2` for first-party projects (Rust, C++, C). If starting a new project and you aren't sure, ask.
- When using `buck2`, it should drive as much as it can.

## User-facing docs (README and similar)

- Open with a short `tl;dr` bullet list of what the project does for the reader. Put usage first and build/contributor material last.
- Write for someone using the project, not someone auditing it. Leave out internal detail such as addresses, flags, module inventories, feature tables, exhaustive protocol or version ranges, test counts and benchmark results. Link to a developer doc instead.
- Leave out rare setup steps and exhaustive lists. Give the common case and one example.
- Write in a plain voice. Use "you" for the reader and "we"/"I" for the author. Avoid stilted "the X of Y" phrasing ("the optimizations of the release profile").
- One idea per sentence. Do not chain clauses with semicolons or colons; split them into sentences or bullets.
- Say why something exists when it isn't obvious.
- Link external tools and projects the first time they appear.
- Do not hard-wrap prose. Write one line per paragraph.

## Commit Style

- Changes should be rolled into one commit where it makes sense, as if sending patches to Phabricator (stacked diffs) or Gerrit.
- When working on a sequence of uncommitted changes, prefer to edit prior commits to contain new requirements rather than creating a new commit.
- One isolated change per commit. Each commit should stand on its own and be reviewable.

### Review

- At the end of each milestone, run an adversarial code review with a fresh subagent before committing.
