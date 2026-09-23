# Create Tables and Models (Step 1)

## Objective

Create the `Employee` and `ExchangeRate` tables, their models, indexes, and validations — with specs written before implementation. This step produces schema and validation logic only. Do not build controllers, views, normalization logic, or seed data here; those are separate steps.

## Scope boundaries

**In scope:**

- Migrations for `exchange_rates` and `employees`, in that order (employees references exchange_rates)
- Indexes needed for filtering/grouping performance, matched to the eight reporting questions in the requirements doc
- Model validations (presence, uniqueness, format, numericality)
- Model specs for every validation, plus factories

**Explicitly out of scope (do not implement):**

- `normalized_usd_salary` calculation logic (Step 6) — column exists, stays nil for now
- Controllers, views, routes
- Seed scripts (Step 8) — though note the ordering constraint this step creates: seeding must always insert `ExchangeRate` rows before any `Employee` row

If you find yourself writing a service object, background job, or a controller action while doing this task, stop — that belongs to a later step.

---

## Schema specification

### `exchange_rates` table

| Column     | Type          | Constraints            |
| ---------- | ------------- | ---------------------- |
| `currency` | string(3)     | not null, unique index |
| `rate`     | decimal(12,6) | not null               |

Use `decimal(12,6)` for `rate`, not float, to avoid rounding drift in downstream aggregation.

### `employees` table

| Column                  | Type          | Constraints                                              |
| ----------------------- | ------------- | -------------------------------------------------------- |
| `employee_code`         | string        | not null, unique index                                   |
| `full_name`             | string        | not null                                                 |
| `job_title`             | string        | not null, index                                          |
| `department`            | string        | not null, index                                          |
| `country`               | string        | not null, index                                          |
| `local_salary`          | decimal(12,2) | not null                                                 |
| `exchange_rate_id`      | bigint        | not null, foreign key → `exchange_rates`, indexed        |
| `normalized_usd_salary` | decimal(12,2) | nullable (populated later by Step 6 — leave nil for now) |

### Indexes

- `employees.department`
- `employees.country`
- `employees.job_title`
- `employees.exchange_rate_id` (auto-created by `foreign_key: true`)
- `employees.[department, job_title]` (composite)
- `employees.[job_title, exchange_rate_id]` (composite)
- `exchange_rates.currency` (unique)

Deliberately not indexing `normalized_usd_salary` yet — it's nil until Step 6, and adding it prematurely just costs write time on every seed insert for no benefit today. Revisit once that column is populated if a specific dashboard query is slow.

---

## Validation rules

### `ExchangeRate`

- `currency`: presence, uniqueness (case-insensitive), format `/\A[A-Z]{3}\z/`
- `rate`: presence, numericality (`greater_than: 0`)

### `Employee`

- `employee_code`: presence, uniqueness (case-insensitive)
- `full_name`: presence
- `job_title`: presence
- `department`: presence
- `country`: presence
- `local_salary`: presence, numericality (`greater_than: 0`)
- `exchange_rate_id`: enforced via `belongs_to :exchange_rate` (required by default in Rails — no separate presence validation needed)
- No `currency` validation lives on `Employee` directly anymore; delegate reading it to the association:
  ```ruby
  belongs_to :exchange_rate
  delegate :currency, to: :exchange_rate
  ```

---

## Task order (TDD — write the failing spec before the code that passes it)

1. Generate the `ExchangeRate` migration and model file (no logic yet).
2. Write `spec/factories/exchange_rates.rb` with a valid default factory.
3. Write `spec/models/exchange_rate_spec.rb` covering: valid factory passes; blank currency fails; blank rate fails; non-positive rate fails; malformed currency code fails; duplicate currency fails.
4. Run specs, confirm they fail (model has no validations yet).
5. Add validations to `ExchangeRate` until all specs pass.
6. Generate the `Employee` migration — `t.references :exchange_rate, null: false, foreign_key: true` plus the columns and indexes above.
7. Write `spec/factories/employees.rb` with a valid default factory that creates an associated `exchange_rate` (via `association :exchange_rate`).
8. Write `spec/models/employee_spec.rb` covering: valid factory passes; each required field blank fails independently; duplicate `employee_code` fails; non-positive `local_salary` fails; building an employee with no `exchange_rate` fails; a valid record does **not** require `normalized_usd_salary` to be present (confirms we haven't accidentally coupled this step to Step 6); `employee.currency` correctly delegates to `employee.exchange_rate.currency`.
9. Run specs, confirm they fail.
10. Add validations/associations to `Employee` until all specs pass.
11. Run `bin/rails db:migrate` and confirm `schema.rb` reflects both tables with the specified indexes and the foreign key.
12. Run the full spec suite once more to confirm nothing else broke.

---

## Acceptance criteria

- [ ] `schema.rb` shows both tables with correct column types, all listed indexes, and the `exchange_rate_id` foreign key
- [ ] Every validation above has a corresponding spec, and every spec was written before its implementation (visible in commit order)
- [ ] Full spec suite is green
- [ ] No controller, view, route, normalizer, or seed code was touched
- [ ] `normalized_usd_salary` exists as a column but is untouched by any validation, callback, or index
- [ ] `Employee` has no direct `currency` column or validation — it reads currency only through `exchange_rate`
