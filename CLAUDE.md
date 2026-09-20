# CLAUDE.md

## RSpec Conventions

- Build spec subjects with `let` (or `before` + `let` when a record just needs to exist in the DB, not be referenced — `let!` trips the `RSpec/LetSetup` cop). Avoid assigning `build`/`create` results to local variables inline inside an `it` block.
- Group related examples with `describe`/`context` blocks (e.g. `describe 'currency validations'` > `context 'when blank'`) instead of a flat list of similarly-worded `it` blocks.
- One `expect` assertion per example.
