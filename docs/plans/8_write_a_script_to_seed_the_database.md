# Seed Data Generation and Import (Step 8)

## Objective

Three separate pieces, each with one job:

1. **A generator script** — interactive, asks for exchange rate count, employee count, and how many of those employees should be deliberately invalid, then writes two CSV files.
2. **An import service** — reads the two CSVs, batch-inserts valid rows, and routes invalid rows to a separate error file.
3. **`db/seeds.rb`** — thin: reads the CSVs the generator produced and hands them to the import service. No generation logic, no import logic, lives in `seeds.rb` itself.

Use the **Faker** gem for all generated values — names, job titles, departments, countries, currency codes where applicable.

## Why two CSVs, and why exchange rates must generate first

`Employee.exchange_rate_id` is a not-null foreign key (Step 1). An employee CSV row can only be valid if it references a currency code that actually exists in the exchange rate CSV. So the generator must:

1. Generate the exchange rate rows first, entirely.
2. Generate employee rows by sampling currency codes _from that already-generated set_ — not from an independent list of plausible-looking currency codes, which could drift from what's actually in the exchange rate file and make every employee accidentally invalid.

This ordering constraint is the generator's most important design detail — get it wrong and the "invalid employee count" input becomes meaningless, since everything would be invalid.

## Scope boundaries

**In scope:**

- An interactive Rake task or standalone script (`bin/generate_seed_data` or `lib/tasks/seed_data.rake` — pick one, be consistent with however other one-off scripts in the repo are organized) prompting for the three counts
- Two CSV files written to a predictable location (e.g. `db/seed_data/exchange_rates.csv`, `db/seed_data/employees.csv`)
- An import service, namespaced consistently with the convention established in Steps 5 and 7 (check existing service folders before naming/placing this one, same as those steps required)
- Batch insertion, error logging to a separate file, using Faker for all generated values
- `db/seeds.rb` reduced to reading the two CSVs and calling the import service — nothing else
- Specs for the import service's validation, batching, and error-routing behavior, using small fixture CSVs, not the generated 10,000-row files

**Explicitly out of scope:**

- Any change to `Employee`, `ExchangeRate`, or their validations — the import service works within the rules Step 1 already established, it doesn't relax or extend them
- Running the normalization calculation on import in Ruby per-row — see the note on `normalized_usd_salary` below
- A UI for triggering the seed process — this is a developer-run script/rake task, not an HR-manager-facing feature
- Testing the generator script itself with specs — it's an interactive dev tool, not application logic; verify it manually. Only the import service gets specs

If you find yourself adding validation rules to the models or building a web-facing upload form, stop — neither belongs here.

---

## Generator script

Prompts, in order:

1. "How many exchange rates?" — a small number realistically (a dozen or so real currency codes), but accept whatever's entered
2. "How many employees?" — the 10,000+ figure from the requirements doc
3. "How many of those employees should be invalid?" — must be validated as less than or equal to the employee count entered in step 2; re-prompt on invalid input rather than silently clamping it

Generation order:

1. Generate N exchange rate rows: a real 3-letter currency code (sampled without replacement from a fixed list of real ISO codes — not Faker's currency helper alone, since duplicate currency codes would violate the Step 1 uniqueness validation) and a Faker-generated or reasonable-range decimal rate. Write to the exchange rates CSV.
2. Generate M employee rows, where M is the requested total minus the requested invalid count, as clearly valid: Faker name, a sequential or Faker-generated unique employee code, Faker job title/department, Faker country, a reasonable positive salary, and a currency code **sampled from the exchange rate rows generated in step 1**.
3. Generate the remaining `invalid_count` employee rows, each deliberately broken in exactly one way, cycling through the known invalid cases so the import service's rejection logic actually gets exercised across all of them rather than just one repeated failure type: a blank name, a blank employee code, a duplicate employee code (reusing one already emitted in step 2), an unsupported/nonexistent currency code, and a blank or non-numeric local salary. If `invalid_count` doesn't divide evenly across these five cases, that's fine — cycle through them in order and stop when the count is reached.
4. Shuffle the employee rows before writing, so invalid rows aren't all clustered at the end of the file — that's a more honest test of the import service's batch/error-handling than a suspiciously convenient ordering would be.

## Import service — design requirements

Namespaced and located consistent with whatever convention Steps 5 and 7 established — check the actual folder structure before placing this, same instruction as those steps.

Takes the two CSV file paths (and optionally an output path for the error file, defaulting to something sensible if not given) once, in its initializer. One clearly named public method that performs the import and returns a result — something a caller can use to report how many succeeded and how many failed, not just a bare `true`/`void`.

**Import order matters:** exchange rates first, entirely, before any employee row is processed — same ordering constraint as the generator, for the same reason.

**Exchange rates:** read and validate each row against the model's own validations (don't reimplement validation logic in the import service — instantiate an `ExchangeRate`, check `valid?`, and only then batch-insert the valid ones). Invalid exchange rate rows go to the error file same as invalid employee rows.

**Employees:** same approach — validate via the model, don't hand-roll parallel validation rules that could drift from Step 1's actual constraints. Resolve each row's currency code to the corresponding already-imported `ExchangeRate` id before validating — a row whose currency code doesn't match any imported exchange rate is itself an invalid row and goes to the error file, it doesn't raise or crash the batch.

**Batching:** insert valid rows in slices (a configurable batch size, defaulting to something like 1,000) via `insert_all`, not one `save` per row — this is the same performance reasoning as the original plan's seeding step, now made concrete. Because `insert_all` bypasses ActiveRecord callbacks, **`normalized_usd_salary` will not be populated by Step 6's callback during this bulk insert** — the import service must compute it itself, per row, before the batch insert, reusing Step 6's calculation object directly rather than reimplementing the formula a third time. This is exactly the situation flagged back in Step 6's plan.

**Error file:** every rejected row, exchange rate or employee, written to the error output file with its validation error message attached, and **deliberately without a timestamp column** — this matches the original requirements doc's language about making rejected rows easy to spot and filter, and should carry over into this concrete implementation rather than being silently dropped.

**Result reporting:** the import method's return value should make counts available — how many exchange rates imported vs. rejected, how many employees imported vs. rejected — since the developer running this needs that summary printed at the end, not just a completed process with no feedback.

## `db/seeds.rb`

```ruby
# Illustrative shape, not literal final code — the point is how little belongs here
exchange_rates_csv = Rails.root.join("db/seed_data/exchange_rates.csv")
employees_csv = Rails.root.join("db/seed_data/employees.csv")

result = SomeNamespace::CsvImportService.new(
  exchange_rates_path: exchange_rates_csv,
  employees_path: employees_csv
).import

puts "Exchange rates: #{result.exchange_rates_imported} imported, #{result.exchange_rates_rejected} rejected"
puts "Employees: #{result.employees_imported} imported, #{result.employees_rejected} rejected"
```

If the CSVs don't exist yet, `seeds.rb` should say clearly that the generator needs to be run first, rather than failing with a raw file-not-found error.

---

## Task order (TDD)

1. Check existing service namespacing (same instruction as Steps 5 and 7) and decide where the import service lives.
2. Build the generator script manually first (no specs) — interactive prompts, the ordering/sampling logic above, Faker-based generation, the five invalid-case rotation, shuffled output. Run it by hand with small numbers (e.g. 3 exchange rates, 20 employees, 5 invalid) and manually inspect both CSVs for correctness before trusting it at scale.
3. Write a spec for the import service using small, hand-crafted fixture CSVs (not the generator's output) — a handful of valid exchange rate rows, a handful of valid employee rows referencing them, and at least one row for each of the five known-invalid cases:
   - all valid rows import successfully and are queryable afterward
   - each invalid case (blank name, blank code, duplicate code, unknown currency, blank/non-numeric salary) is rejected and appears in the error file with a meaningful message, and does not appear in the database
   - imported employees have a correctly computed `normalized_usd_salary`, matching what Step 6's calculation object would produce for the same inputs — this is the regression check for the `insert_all`-skips-callbacks gap
   - exchange rates import before any employee row is processed (e.g. assert an employee row referencing a currency defined later in the same import batch still succeeds, since all exchange rates are fully imported before any employee validation begins)
   - the returned result object's counts match the fixture's known valid/invalid split exactly
   - batching works correctly across more rows than a single batch size (use a small configured batch size in the test, not the production default)
4. Run, confirm failure. Build the import service until green.
5. Wire `db/seeds.rb` to the shape above, including the missing-CSV guidance message.
6. Run the generator at the real target scale (10,000+ employees), then run `db/seeds.rb` against its output, and confirm the printed summary's numbers make sense against what was requested (e.g. requesting 200 invalid employees should reject close to 200, not some wildly different number — small drift from the five-case rotation not dividing evenly is fine, a large discrepancy is not).
7. Spot-check the database afterward: query a handful of imported employees and confirm their `normalized_usd_salary` is populated and correct, not left null.
8. Run the full spec suite to confirm nothing from Steps 1–7 broke.

---

## Acceptance criteria

- [ ] Generator script prompts for exchange rate count, employee count, and invalid employee count, validates the invalid count against the total, and re-prompts rather than silently clamping
- [ ] Exchange rate rows are generated first; employee currency codes are sampled from that already-generated set, not independently
- [ ] Invalid employee rows cycle through all five known invalid cases, not just one repeated failure
- [ ] Generated rows are shuffled before writing, not clustered
- [ ] Import service is namespaced consistently with the convention already established in Steps 5 and 7
- [ ] Import service validates every row through the actual model (`valid?`), never a hand-rolled parallel rule set
- [ ] Exchange rates are fully imported before any employee row is processed
- [ ] Rows are inserted in configurable batches via `insert_all`, not one save per row
- [ ] `normalized_usd_salary` is computed per row using Step 6's calculation object before batch insert, since `insert_all` bypasses the model callback that would otherwise do this
- [ ] Rejected rows land in a separate error file with their validation error message, with no timestamp column
- [ ] The import method returns a result exposing imported/rejected counts for both exchange rates and employees
- [ ] `db/seeds.rb` contains only CSV-path setup, the service call, and result printing — no generation or import logic inline, and a clear message if the CSVs are missing
- [ ] Import service specs use small hand-crafted fixtures, not the generator's real output, and cover every invalid case plus batching plus the `normalized_usd_salary` regression check
- [ ] Full spec suite from Steps 1–7 still passes unmodified
