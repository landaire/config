# Rust

These rules add to the global instructions.

## Organization

- Keep `lib.rs` to module declarations and re-exports. Put errors in `error.rs`.
- Put shared logic in a library crate. CLI and UI crates are thin front ends that depend on it.
- One module per concern. Select platform-specific modules with paired `#[cfg]` declarations and re-export them behind one API.
- A large type may have `impl` blocks in the modules that own each concern. Its definition and constructor stay in one place.

## Item order

- Imports, traits and types (each followed directly by its impls), private helper types, free functions, tests. `main` is last.
- One trait per `impl` block. Put impl bounds in a `where` clause.
- Declare a constant used by one function inside that function.

## Imports

- One item per `use` line. No brace groups or globs, except `use super::*;` in tests.
- Three groups separated by blank lines: `std`, external crates, `crate`. Re-exports follow.

## Spacing

- Write function bodies as paragraphs, one step each, separated by a blank line.
- Blank line after a guard clause, around a loop, and before the final return value.
- A comment sits directly above the paragraph it explains.
- Group related struct fields with a blank line between groups.

## Control flow

- `let ... else` for preconditions. Early `return`/`continue` over nesting.
- Bind once with `let x = match ...` or `let x = if ...`. Do not assign in each branch.
- Walk trees with a worklist loop, not recursion.
- Block bodies for match arms that do more than produce a value. Empty arms get a comment saying why.
- Drop locks with a scoped block.
- Clone reference-counted values as `Arc::clone(&x)`.
- Write resumable work as an explicit state machine that the caller drives.

## Naming and formatting

- Getters have no `get_` prefix: `x()`, `x_mut()`, `is_x()`.
- Constructors are `new`, `from_<source>`, or `parse`.
- Full descriptive names. `idx`, `len`, and `e` are acceptable.
- `Self { a, b }` construction. `Default` delegates to `new()`.
- Inline format arguments: `"{count:#X}"`.

## Missing data

- Use `Option` or an enum for absent values. Bubble `Option` and `Result` up to the boundary that can handle them.
- Scrutinize every `.unwrap_or`, `.unwrap_or_default`, `.unwrap_or_else`, and `Default` applied to parsed or possibly-missing data.

## Errors

- Use strong `thiserror` enums with structured fields.
- Never match on an error's `Display` or `Debug` string to recover data. Add a field instead.
- Use `rootcause` to attach context as errors cross boundaries in new projects or existing projects with the dep.

## Tests and builds

- Use Insta for snapshot tests.
- Under `buck2`, shelling out to `cargo` is a last resort.
