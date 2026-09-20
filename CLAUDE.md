# CLAUDE.md

## RSpec Conventions

- Build spec subjects with `let` (or `before` + `let` when a record just needs to exist in the DB, not be referenced — `let!` trips the `RSpec/LetSetup` cop). Avoid assigning `build`/`create` results to local variables inline inside an `it` block.
- Group related examples with `describe`/`context` blocks (e.g. `describe 'currency validations'` > `context 'when blank'`) instead of a flat list of similarly-worded `it` blocks.
- One `expect` assertion per example.
- Pass the actual class to `RSpec.describe`, not a string — `RSpec.describe Employee`, `RSpec.describe EmployeesController` (not `RSpec.describe 'Employees'`).
- Never pass an explicit `type:` (`type: :model`, `type: :request`). `spec/rails_helper.rb` enables `infer_spec_type_from_file_location!`, so the type comes from the directory.
