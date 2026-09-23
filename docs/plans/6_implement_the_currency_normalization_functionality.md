# Currency Normalization Functionality (Step 6)

## Objective

Give `normalized_usd_salary` a real, live implementation: compute it whenever an employee's local salary or currency changes, and recompute it for every affected employee — without blocking the request — whenever an exchange rate's value changes, using **Solid Queue** as the background job backend. Track and surface when each exchange rate's value was last set.

## Why Solid Queue

Rails 8's default job backend, backed by the same relational database already in use — no Redis, no second datastore to run or deploy, consistent with the SQLite-and-Hotwire-monolith philosophy already established for this project. It ships with its own migration set for its job tables and a `bin/jobs` process to run workers, separate from the main web process.

## Behavior specification

**On employee create or update:** if `local_salary` or `exchange_rate_id` has changed, `normalized_usd_salary` is recomputed and saved in the same write, before the record hits the database. Updating an unrelated field alone should not trigger a recomputation. This path goes through a normal ActiveRecord save, so `updated_at` is touched automatically — nothing extra needed here.

**On exchange rate update:** if the rate's numeric value actually changed, two things happen after commit:
1. `last_synced_at` on that exchange rate is set to the current time, marking when this rate's value was last set — whether by this manual edit today or by an automated sync in some future iteration, per the requirements doc's note that rate updates may eventually be pulled from an external source.
2. A Solid Queue job is enqueued to recompute `normalized_usd_salary` for every employee currently on that currency.

Both happen only when the rate value itself changed — editing the record without changing `rate`, or creating a brand-new exchange rate, does neither. A brand-new rate has no employees on it yet, so there's nothing to recalculate, but its `last_synced_at` should still be set to the moment of creation — a rate has been "synced" the instant its value is first set, not only on a later edit.

**The bulk recomputation runs in batches, not one write per employee**, a handful of SQL statements total. Each batch's `UPDATE` sets both `normalized_usd_salary` and `updated_at` explicitly in the same statement — since this bypasses ActiveRecord's per-record save path entirely, neither column gets touched unless the SQL says so directly.

**Last synced time is visible in the Exchange Rate UI** — each row in the index shows when that currency's rate was last set.

## Scope boundaries

**In scope:**
- A migration adding `last_synced_at` (datetime, nullable) to `exchange_rates`
- Solid Queue installed and configured as the Active Job adapter
- A standalone calculation object that computes the normalized USD value from a local salary and an exchange rate
- An `Employee` callback that uses it on create/update
- An `ExchangeRate` callback that sets `last_synced_at` and enqueues the recalculation job when the rate value changes (or is set for the first time)
- The recalculation job itself, batched, explicitly setting both `normalized_usd_salary` and `updated_at`
- Displaying `last_synced_at` on the Exchange Rate index row, in both its display and inline-edit states
- Specs for all of the above

**Explicitly out of scope:**
- Any change to the seed script — Step 8 owns that, though it will need to call the same calculation object this step introduces, and will need to set `last_synced_at` itself when seeding exchange rates
- Any change to the `ExchangeRate` controller actions themselves — the model callbacks and the view are what change, not the create/update logic already built in Step 2
- Dashboard charts (Step 7)
- Any UI indicator showing "recalculation in progress" for employees — not requested

If you find yourself writing seed logic or touching the controller's create/update actions, stop — neither belongs here.

---

## Migration

Add `last_synced_at:datetime` to `exchange_rates`, nullable (existing rows before this migration won't have a meaningful value until their next update — that's an acceptable, honest gap, not something to backfill with a fabricated timestamp). No index needed; this column is for display, not for filtering or sorting in this step.

## Solid Queue setup

Add the `solid_queue` gem if not already present from the Rails 8 default Gemfile, run its install generator to get `config/queue.yml` and its migration, run that migration, and set the Active Job queue adapter to `:solid_queue` for at least the production and development environments. Confirm `bin/jobs` starts a worker process that can pick up and execute a trivial test job before building the real recalculation job on top of it — worth a quick manual sanity check, not just trusting the install worked.

## Calculation object — design requirements

Name it for what it computes — a salary normalizer that turns a local salary and an exchange rate into a USD figure. It takes its inputs once, in its initializer, and exposes one method named after what it returns. It rounds to two decimal places explicitly itself, rather than trusting the database column's declared scale, since not every database engine enforces decimal precision strictly on write.

This object is reused in two execution contexts — once per-record inside the `Employee` callback, and once reimplemented as raw SQL for bulk performance inside the recalculation job. The job's spec should assert its raw-SQL output matches what this calculation object would produce for the same inputs, so the two implementations of the same formula can't silently drift apart.

## `Employee` callback — design requirements

Triggers before save, on both create and update, only recomputing when `local_salary` or `exchange_rate_id` is actually among the changed attributes. Recomputing on an unrelated field edit at 10,000+ rows is wasted work with no observable benefit. Since this goes through a normal `save`, `updated_at` updates automatically — no manual handling needed.

## `ExchangeRate` callback — design requirements

Two responsibilities, both gated on the rate value having changed (including a brand-new record, where every attribute counts as changed from nil):

- Set `last_synced_at` to the current time, before save, so it's part of the same write as the rate change itself.
- After commit, and only on an update where the rate value changed (never on create — nothing to recalculate yet), enqueue the recalculation job. Enqueueing after commit rather than before or during matters here: a worker that picks up the job faster than the transaction finishes could otherwise read the old, pre-update rate value.

## Recalculation job — design requirements

Takes the exchange rate's id, looks up its current rate, and updates every employee referencing that exchange rate in batches — a handful of SQL statements, not one per employee. Each batch's `UPDATE` computes and rounds `normalized_usd_salary` using the same formula as the calculation object, and **also explicitly sets `updated_at` to the current time in that same statement** — this is the one place in the system where `updated_at` has to be set by hand rather than relying on ActiveRecord's automatic behavior, precisely because this path bypasses individual model saves. Worth a comment at the point of the raw SQL noting why it's explicit here, since the reason isn't obvious from the surrounding code alone.

## Exchange Rate UI — last synced display

Add `last_synced_at` as a fourth field alongside currency, rate, and actions on each Exchange Rate row. Per the design doc's no-layout-shift requirement from Step 3, this field needs a reserved column in the shared `grid-template-columns` used by both the display and edit states — even though it's not directly editable, the edit state should still show it as static text in that same column position, not omit it, so toggling between states doesn't reflow the row. Display it as a relative time ("2 hours ago") with the exact timestamp available via `title`/`aria-label` on hover, consistent with the truncation-tooltip pattern already established for other fields — precision on demand, readability by default. A rate that has never been synced (pre-migration data with a null value) should show a clear placeholder rather than a blank cell or a broken date format.

---

## Task order (TDD)

1. Write the migration adding `last_synced_at` to `exchange_rates`; run it; confirm `schema.rb` reflects it.
2. Install and configure Solid Queue; confirm its own migration has run and a trivial test job executes via `bin/jobs`.
3. Write a spec for the calculation object: known local-salary/rate pairs against hand-computed results, including a rounding edge case.
4. Run, confirm failure. Build the calculation object until green.
5. Write a spec for the `Employee` callback: creating an employee populates `normalized_usd_salary` correctly; changing `local_salary` recomputes it; changing `exchange_rate_id` recomputes it using the new rate; changing an unrelated field does not invoke the calculation object at all (assert this directly, not just that the value happens to stay the same).
6. Run, confirm failure. Build the callback until green.
7. Write a spec for the `ExchangeRate` callback: creating a new exchange rate sets `last_synced_at` but does not enqueue the job; updating the rate value sets a new `last_synced_at` and enqueues the job with the correct id; updating the record without changing the rate value does neither.
8. Run, confirm failure. Build the callback until green.
9. Write a spec for the recalculation job: seed employees across at least two exchange rates; run the job for one after changing its rate; assert every employee on that rate now has the correct `normalized_usd_salary`, matching the calculation object's output for the same inputs; assert employees on the other rate are untouched; assert it correctly batches more employees than a single batch size (use a small batch size in the test); assert `updated_at` **is** updated on every affected employee, in the same batch statement, confirming this is explicit rather than accidental.
10. Run, confirm failure. Build the job until green.
11. Update the Exchange Rate row view (display and edit states) to show `last_synced_at` as relative time with an exact-time tooltip, in the same reserved grid column in both states, with a placeholder for a never-synced rate.
12. Manually verify in-browser: create a new exchange rate, confirm `last_synced_at` shows immediately and no job was enqueued; edit an existing rate's value, confirm the response returns immediately, confirm `last_synced_at` updates right away, and confirm the affected employees' salaries and their `updated_at` values reflect the change once the Solid Queue worker processes the job.
13. Run the full spec suite to confirm nothing from Steps 1–5 broke.

---

## Acceptance criteria

- [ ] `exchange_rates.last_synced_at` exists via a proper migration and is reflected in `schema.rb`
- [ ] Solid Queue is configured as the Active Job adapter and a job can be confirmed to run via `bin/jobs`
- [ ] The calculation object is independently tested, takes its inputs once in its initializer, and is named for what it computes
- [ ] `Employee` recomputes `normalized_usd_salary` on create and whenever `local_salary` or `exchange_rate_id` changes, provably skipping recomputation otherwise, with `updated_at` updating automatically via the normal save path
- [ ] `ExchangeRate` sets `last_synced_at` on both create and any rate-value change, and enqueues the recalculation job only on an update where the rate value changed, never on create
- [ ] The recalculation job updates affected employees in batched SQL statements, explicitly setting both `normalized_usd_salary` and `updated_at` in each batch statement, matching the calculation object's output for the same inputs
- [ ] The Exchange Rate index displays `last_synced_at` as relative time with an exact-time tooltip, in the same fixed column position in both display and edit states, with a clear placeholder when never synced
- [ ] Editing an exchange rate's value returns a response to the HR manager without waiting on the recalculation to finish
- [ ] Full spec suite from Steps 1–5 still passes unmodified
- [ ] No seed script or controller action logic was touched — only the migration, model layer, job, and the Exchange Rate view
