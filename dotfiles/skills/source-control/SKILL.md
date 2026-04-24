---
name: source-control
description: Source control skill for how to use source control functionality
---

## General Principles

- Never commit directly to a repository.
- Never reset changes to a repository unless you have verified that only the changes you intend to remove would be impacted.
- Always use jujutsu (`jj`) when available and the repo has `jj` initialized. Fall back to `git` otherwise.

## Using `jj`

### Avoiding Pagers

A lot of `jj` commands run with a TUI that might invoke a pager. Try to temporarily specify config options that avoid paging. Some commands support `--no-pager` while some tools like `jj diff` take a `--tool` argument which allows you to specify the diff tool.

### Temp changes

You _can_ do temp before/after changes by stashing/popping or creating a new temp commit in `jj` based on the same parent. Just ensure that the state is the same before/after.
