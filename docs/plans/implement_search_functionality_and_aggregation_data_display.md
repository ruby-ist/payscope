# Search, Filtering, Sorting, and Aggregation Display (Step 5)

## Objective

Build real filtering, sorting, and aggregate computation for the Employee index, replacing Step 4's `load_sidebar_data` no-op. Filters live in the right-hand sidebar/drawer built in Step 3; a sort control sits near the "New employee" button. Applying a filter must update both the row-card list **and** the five-stat aggregate bar; paginating must update neither the aggregate bar nor the filter/sort selections — and must carry the current filters and sort order forward onto every subsequent page.

## Filter fields

- **Name** — partial, case-insensitive text match against `full_name`
- **Employee code** — partial, case-insensitive text match against `employee_code`
- **Department** — partial, case-insensitive text match against `department`
- **Country** — partial, case-insensitive text match against `country`
- **Job title** — partial, case-insensitive text match against `job_title`
- **Currency** — a dropdown, exact match, sourced from `ExchangeRate`'s distinct currencies (the one bounded-set field; everything else above is free text)
- **Normalized salary range** — two numeric inputs, a lower bound and an upper bound, against `normalized_usd_salary`
- **Created at range** — two date inputs, a lower and upper bound, against `created_at`
- **Updated at range** — two date inputs, a lower and upper bound, against `updated_at`

Each text field is independent — filtering by Name and Department together narrows to records matching both, not either. Every range filter treats the lower bound as inclusive and the upper bound as inclusive; a blank bound on either side leaves that side unbounded rather than excluding records.

## Filter submission — explicit, not automatic

The filter sidebar/drawer has a **Filter** button and a **Reset** button. There is no debounce, no submit-on-keystroke, no submit-on-select-change for any of the nine filter fields above. The person fills in whatever fields they want, then presses Filter to apply them all at once. Reset clears every field back to blank and returns the list to its unfiltered, default-sorted, page-1 state.

## Sort control

A **Sort by** dropdown sits near the "New employee" button, separate from the filter sidebar. It offers every employee column _except_ `local_salary` — `employee_code`, `full_name`, `job_title`, `department`, `country`, `currency` (via the `exchange_rate` association), `normalized_usd_salary`, `created_at`, and `updated_at` — each with an ascending/descending direction. `local_salary` is deliberately excluded from sorting since it's a raw figure in whatever local currency the employee is paid in; sorting by it across mixed currencies wouldn't produce a meaningful order, which is exactly the kind of thing `normalized_usd_salary` exists to fix.

Unlike the filter fields, the sort dropdown submits immediately on change. Picking a sort option is a single discrete action, not continuous typing — it doesn't carry the same "don't fire a request on every keystroke" concern the filter fields did, so treating it differently from the no-auto-submit rule above is a deliberate, stated choice, not an inconsistency.

To keep this to one request rather than duplicating every filter value as hidden fields, the sort dropdown is **part of the same form** as the filters, even though it's rendered elsewhere on the page — HTML allows an input to declare which form it belongs to by referencing that form's id, regardless of where in the DOM the input actually sits. A small Stimulus controller attached only to the sort dropdown submits that shared form on change. This means picking a sort order also re-applies whatever filters are currently set, and vice versa, with no separate mechanism needed to keep them in sync.

Never build the `ORDER BY` clause from the raw incoming sort parameter directly — whitelist it against the known sortable columns first. An unvalidated column name in a sort parameter is a real injection surface, not just a correctness concern.

## Scope boundaries

**In scope:**

- `EmployeeListingQuery`: takes a scope and filter/sort params, exposes a method that returns the matching, ordered employees as a relation
- `EmployeeSalarySummary`: takes a scope, exposes a method returning a min/max/avg/count/sum hash read from `normalized_usd_salary`
- All nine filter fields and the sort control described above
- Wiring both query objects into `EmployeesController#index`, replacing the Step 4 stub
- The `employee_results` outer Turbo Frame wrapping the aggregate bar and the existing `employee_list` inner frame
- Pagy configured so its page links carry forward every current filter and sort parameter, not just `page`
- Request specs covering each filter individually, filters in combination, range boundary behavior, sorting on every allowed column in both directions, sort-parameter whitelisting, filter/sort persistence across pagination, and the Step 4 frame-isolation guarantee

**Explicitly out of scope:**

- On-the-fly USD computation — read the stored column only
- Recalculating `normalized_usd_salary` on create/update — Step 6
- Dashboard charts (Step 7), though the salary summary object should stay generic enough for Step 7 to reuse against a grouped scope
- Saved filter presets
- Any auto-submit behavior on the nine filter fields — Filter and Reset are the only ways those apply

---

## `EmployeeListingQuery` — design requirements

Name the class for what it returns, and name its public method the same way — not a generic `call` or `results` that tells a reader nothing without opening the file.

Treat each filter as its own private method with a single, narrow responsibility: given a relation, return a narrower relation. `ActiveRecord::Relation` is chainable by nature, so thread the filter methods through a fold rather than repeatedly reassigning a local variable by hand.

Each of the five text filters skips itself when its param is blank, sanitizes the input before building a `LIKE` pattern (matching the sanitization approach used elsewhere in the app), and matches case-insensitively. The currency filter joins to `exchange_rate` and matches exactly, also skipping itself when blank. Each range filter independently checks its own min and max — applying the lower bound only if given, the upper bound only if given, applying neither if both are blank.

Sorting is a distinct concern from filtering — it's an `ORDER BY`, not a `WHERE` — so keep it as its own explicit step applied after every filter, not folded into the filter list as if it were one more narrowing condition. It should validate the requested sort column against the known whitelist (falling back to a sensible default, such as `employee_code` ascending, if the requested column is missing or not on the whitelist) and validate the requested direction the same way. Sorting by currency requires the same join to `exchange_rate` the currency filter uses; if both are active in the same request, that join should only happen once, not twice.

## `EmployeeSalarySummary` — design requirements

One instance variable, assigned once in the initializer, no generic `call` method. Name the class for the specific thing it summarizes, and name its public method for what it returns. It computes min, max, avg, count, and sum of `normalized_usd_salary` in a single query, returned as one hash. Sorting has no effect on these values — they should be computed once from the filtered scope regardless of sort order, so this object should never need to know what sort was requested.

## Controller wiring

The controller builds the filtered, sorted, unpaginated relation from `EmployeeListingQuery` once, passes it to Pagy for the current page, and passes that same relation to the salary summary object and to the currency dropdown's data — but only when the request is not a page-only Turbo Frame request, per the Step 4 guarantee. Pagy itself is configured so that every generated page link includes the full current set of filter and sort query parameters alongside `page`, so following a page link never silently reverts to an unfiltered, default-sorted first page.

## View structure — frame nesting

Unchanged mechanism from Step 4: an outer `employee_results` frame contains the aggregate bar and the inner `employee_list` frame (row-cards plus pagy nav). The shared filter-and-sort form lives mostly in the sidebar/drawer, targets `employee_results` on submission, and resets to page 1. The sort dropdown, physically placed near the "New employee" button, submits as part of that same form via its form-association attribute. Pagy's nav links stay inside the inner frame and default-target their closest ancestor, so paging alone never touches the outer frame — while still carrying the filter and sort parameters forward, per the Pagy configuration above.

Group the sidebar/drawer form into clearly separated sections rather than one long flat list: a text-filters group (name, employee code, department, country, job title), then currency, then the two range groups (salary, and the two date ranges), with Filter and Reset at the bottom.

---

## Task order (TDD)

1. Write a spec for `EmployeeListingQuery` in isolation: seed employees with varied names, codes, departments, countries, job titles, currencies, salaries, and timestamps. Assert each of the nine filters narrows correctly alone and in combination (AND, not OR); assert case-insensitivity where relevant; assert blank params return everything; assert range filters handle only-min, only-max, both, and neither, inclusive on both boundary values; assert sorting works correctly, in both directions, for every allowed column including currency (via the join); assert an invalid or unknown sort column falls back to the default rather than raising or building an unsafe query.
2. Run, confirm failure. Build `EmployeeListingQuery` until green.
3. Write a spec for `EmployeeSalarySummary`: seed employees with known `normalized_usd_salary` values, assert the summary's five values against hand-computed expectations, assert it executes as a single query, assert sort order has no effect on the computed values.
4. Run, confirm failure. Build `EmployeeSalarySummary` until green.
5. Write request specs covering: a filtered request returns only matching employees; a filtered request's aggregates reflect the filtered set; a sorted request returns employees in the correct order for a sample of columns and both directions; a full-page filter/sort request loads the sidebar data; a request carrying the outer frame's header also loads the sidebar data; a pagination request carrying the inner frame's header, even with filter and sort params present, does not load the sidebar data; pagination preserves both the active filters and the active sort order on the next page's request; a request with a tampered/invalid sort parameter does not error and falls back to the default order.
6. Run, confirm failure. Wire the controller and views until green.
7. Build the filter sidebar/drawer form with Filter and Reset buttons, the sort dropdown near "New employee" associated to the shared form, and the small Stimulus controller that submits the form when the sort dropdown changes.
8. Manually verify in-browser: filters only apply after pressing Filter, never before; Reset clears everything; changing sort re-applies immediately and preserves any active filters; paginating with active filters and a non-default sort keeps both intact on every subsequent page; attempting to hand-craft an invalid `sort_by` in the URL doesn't error or expose raw SQL behavior.
9. Run the full spec suite to confirm nothing from Steps 1–4 broke.

---

## Acceptance criteria

- [ ] `EmployeeListingQuery` and `EmployeeSalarySummary` are isolated, independently tested objects with intention-revealing names and methods — no generic naming, no `call`/`results`
- [ ] The query object threads its filters through a fold over an ordered method list, not manual repeated reassignment, and treats sorting as a distinct step from filtering
- [ ] Both objects assign their instance state exactly once, in the initializer, and never reassign it
- [ ] All nine filters work individually and in combination; the Filter button is the only way they're applied, and Reset clears all of them
- [ ] Range filters are inclusive on both bounds and correctly handle a missing minimum, missing maximum, or both
- [ ] The sort dropdown offers every employee column except `local_salary`, applies immediately on change, and is whitelisted server-side against SQL injection via an arbitrary sort column
- [ ] Sorting has no effect on the five aggregate values
- [ ] Paginating preserves both active filters and active sort order on every subsequent page, verified by spec
- [ ] Aggregates read `normalized_usd_salary` directly, in one query, over the fully filtered scope
- [ ] Only the currency dropdown is sourced from distinct data; the five text filters have no options lookup
- [ ] Full spec suite from Steps 1–4 still passes unmodified
- [ ] No migration, no write to `normalized_usd_salary`, no dashboard code introduced
