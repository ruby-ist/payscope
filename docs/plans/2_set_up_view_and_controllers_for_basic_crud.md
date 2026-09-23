# Set Up Views and Controllers for CRUD (Step 2)

## Objective

Build `EmployeesController` and `ExchangeRatesController` with standard CRUD actions. The two resources are treated differently by design:

- **Employees** — a large, page-worthy resource. `new`/`edit` are dedicated pages. `create`/`update` respond to `html` only, relying on Turbo Drive for async navigation. `destroy` responds to both `html` and `turbo_stream`, since it's triggered inline from the index row.
- **Exchange Rates** — a small, low-cardinality "mini resource" (a handful of currency rows), managed entirely inline on its own index page via a Turbo Frame form. `create`, `update`, and `destroy` all respond to both `html` and `turbo_stream`.

This step produces routes, controllers, and views only — no search, filtering, aggregation, pagination, styling, or normalization logic.

## Scope boundaries

**In scope:**

- Routes for both resources
- Controller actions with correct format handling per the tables below
- Minimal, unstyled ERB views
- Turbo stream templates as specified per resource
- `data: { turbo_confirm: "..." }` on every delete action, in both apps
- Request specs covering the correct formats for every mutating action, per resource

**Explicitly out of scope (do not implement):**

- CSS/styling (Step 3)
- Pagination (Step 4)
- Search, filtering, aggregation display (Step 5)
- Currency normalization triggering on employee create/update (Step 6) — `normalized_usd_salary` stays untouched here
- Dashboard (Step 7)
- Any Stimulus controller beyond what Turbo needs by default
- `turbo_stream` responses for Employees `create`/`update` — deliberately omitted; see reasoning below

If a task requires deciding how filtering or aggregates will look, stop — that's Step 5.

---

## Routes

```ruby
resources :employees
resources :exchange_rates
root to: "employees#index"
```

No nested routes needed at this stage.

---

## Employees controller behavior

| Action              | Format         | Behavior                             |
| ------------------- | -------------- | ------------------------------------ |
| `index`             | `html`         | List records                         |
| `new`               | `html`         | Render blank form page               |
| `create` (success)  | `html`         | Redirect to index with flash         |
| `create` (failure)  | `html`         | Render `:new`, status 422            |
| `edit`              | `html`         | Render form page for existing record |
| `update` (success)  | `html`         | Redirect to index with flash         |
| `update` (failure)  | `html`         | Render `:edit`, status 422           |
| `destroy` (success) | `html`         | Redirect to index with flash         |
| `destroy` (success) | `turbo_stream` | `turbo_stream.remove` the row        |

**Why no `turbo_stream` on Employees create/update:** since `new`/`edit` are full pages, the success path always navigates back to the index anyway — Turbo Drive already makes that navigation and the 422 re-render fast and reload-free, without a second response format to maintain.

```ruby
def create
  @employee = Employee.new(employee_params)
  if @employee.save
    redirect_to employees_path, notice: "Employee created."
  else
    render :new, status: :unprocessable_entity
  end
end

def destroy
  @employee.destroy
  respond_to do |format|
    format.html { redirect_to employees_path, notice: "Employee deleted." }
    format.turbo_stream
  end
end
```

---

## Exchange Rates controller behavior

| Action              | Format         | Behavior                                                                         |
| ------------------- | -------------- | -------------------------------------------------------------------------------- |
| `index`             | `html`         | List records, with an inline form frame for adding a new one                     |
| `create` (success)  | `html`         | Redirect to index with flash                                                     |
| `create` (success)  | `turbo_stream` | `turbo_stream.append`/`prepend` the new row into the table, reset the form frame |
| `create` (failure)  | `html`         | Render `:index` with errors, status 422                                          |
| `create` (failure)  | `turbo_stream` | Replace the form frame with errors, status 422                                   |
| `update` (success)  | `html`         | Redirect to index with flash                                                     |
| `update` (success)  | `turbo_stream` | `turbo_stream.replace` the updated row                                           |
| `update` (failure)  | `html`         | Render `:index` (or re-render the row's edit state) with errors, status 422      |
| `update` (failure)  | `turbo_stream` | Replace the row's form frame with errors, status 422                             |
| `destroy` (success) | `html`         | Redirect to index with flash                                                     |
| `destroy` (success) | `turbo_stream` | `turbo_stream.remove` the row                                                    |

There is no dedicated `new.html.erb` or `edit.html.erb` — both states render inline within `turbo_frame_tag` on the index (a frame for "add new," and a frame per row that toggles between display and edit).

```ruby
def create
  @exchange_rate = ExchangeRate.new(exchange_rate_params)
  if @exchange_rate.save
    respond_to do |format|
      format.html { redirect_to exchange_rates_path, notice: "Exchange rate created." }
      format.turbo_stream
    end
  else
    respond_to do |format|
      format.html { render :index, status: :unprocessable_entity }
      format.turbo_stream { render :create, status: :unprocessable_entity }
    end
  end
end
```

(`create.turbo_stream.erb` handles the success case via the default template; the failure branch explicitly re-renders a stream partial showing the invalid `@exchange_rate` with errors in the form frame.) `update` and `destroy` follow the same paired pattern.

---

## Views needed

**Employees:**

- `index.html.erb` — table, each row wrapped in `turbo_frame_tag dom_id(employee)`
- `_employee.html.erb` — row partial, delete via `button_to "Delete", employee_path(employee), method: :delete, data: { turbo_confirm: "Are you sure you want to delete this employee?" }`
- `new.html.erb` / `edit.html.erb` — thin wrappers around shared `_form.html.erb`
- `destroy.turbo_stream.erb`

**Exchange Rates:**

- `index.html.erb` — table of rates, each row wrapped in `turbo_frame_tag dom_id(exchange_rate)`, plus a persistent `turbo_frame_tag "new_exchange_rate"` holding the add-new form
- `_exchange_rate.html.erb` — row partial (display state), with inline "Edit" link that navigates the row's own frame to `edit_exchange_rate_path` for row-level edit-in-place; delete via `button_to "Delete", exchange_rate_path(rate), method: :delete, data: { turbo_confirm: "Deleting this rate may affect employees using it. Are you sure?" }`
- `_form.html.erb` — shared by the new-frame and each row's edit state
- `create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`

No styling — plain semantic HTML only. Step 3 handles CSS.

---

## Task order (TDD — write the failing spec before the code that passes it)

1. Add routes for both resources.
2. Write `spec/requests/employees_spec.rb`:
   - `create`: valid params → redirect to index, persisted; invalid → 422, renders `:new`, not persisted
   - `update`: valid params → redirect, updated; invalid → 422, renders `:edit`, unchanged
   - `destroy`: `html` → redirect, removed; `turbo_stream` → 200, body contains `turbo-stream action="remove"` targeting correct dom_id, removed
   - `index`: `html` → 200, lists records
3. Run specs, confirm they fail. Build `EmployeesController` and views until green.
4. Write `spec/requests/exchange_rates_spec.rb`:
   - `create`: valid + `html` → redirect, persisted; valid + `turbo_stream` → 200, body contains an `append`/`prepend` action with the new rate's data, persisted; invalid + `html` → 422; invalid + `turbo_stream` → 422, body contains error text
   - `update`: same four cases, expecting a `replace` action on success
   - `destroy`: `html` → redirect, removed; `turbo_stream` → 200, body contains `remove` action targeting correct dom_id, removed
   - `index`: `html` → 200, lists records
5. Run specs, confirm they fail. Build `ExchangeRatesController` and views until green.
6. Run the full spec suite to confirm nothing from Step 1 broke.

---

## Acceptance criteria

- [ ] `resources :employees` and `resources :exchange_rates` routed, root points to employees index
- [ ] Employees `create`/`update` respond to `html` only; `destroy` responds to both `html` and `turbo_stream`
- [ ] Exchange Rates `create`, `update`, and `destroy` all respond to both `html` and `turbo_stream`, and can be fully managed inline on the index page without a full page reload
- [ ] Failed `create`/`update` on both resources return HTTP 422 in every format, with errors visible in the re-rendered form
- [ ] Every delete button/link has `data: { turbo_confirm: "..." }` and a confirmation dialog appears before deletion in-browser, for both resources
- [ ] No CSS, pagination, search, aggregation, normalization, or dashboard code was touched
- [ ] Request specs exist and pass for every action/format combination listed above, for both resources
