# Implement Pagination (Step 4)

## Objective

Add pagination to the Employee index using the **`pagy`** gem. Two things make this more than "drop in a gem and call it done":

1. **Visual integration** — the page navigation must use the app's existing color tokens and button conventions (icon + label, per Step 3), not pagy's unstyled defaults.
2. **Frame isolation** — clicking a page number must only replace the row-card list. The filter sidebar/drawer and the five-stat aggregate bar must not re-render, and — more importantly — **their underlying data must not be re-queried at all** on a pagination request. This is a real performance concern at 10,000+ rows, not just a visual one: recomputing five aggregate values and filter dropdown option lists on every page click would be wasted work the user never asked for.

This step establishes the frame-isolation plumbing now, even though the aggregate/filter _data_ itself doesn't exist yet (that's Step 5). Step 5 will fill in one stub method this step defines — it won't need to think about the Turbo mechanics at all.

## Why pagy

`pagy` is minimal-dependency, has no view-helper bloat, and is actively maintained — a good fit for a Hotwire-only stack where we don't want a pagination library pulling in its own JS or assuming Bootstrap markup we'd have to fight.

## Scope boundaries

**In scope:**

- `pagy` gem installation and a `config/initializers/pagy.rb` with sane defaults
- Paginating the Employee index query
- A custom-styled pagy nav partial matching the design system (colors, icon+label buttons)
- Wrapping the row-card list + nav in its own Turbo Frame
- Controller logic that skips aggregate/filter data loading on frame-only pagination requests
- Request specs covering both the pagination behavior and the frame-isolation behavior

**Explicitly out of scope (do not implement):**

- The actual aggregate computation or filter option queries (Step 5) — this step only defines the stub method Step 5 will fill in, and proves it's called correctly
- Search/filter form logic (Step 5)
- Dashboard (Step 7)
- Any change to Exchange Rates (it's a small "mini resource" per Step 2 — no pagination needed there)

If you find yourself writing actual aggregate SQL here, stop — that's Step 5's job. This step only needs the calling convention to be correct.

---

## Technical approach: frame isolation

**Wrap only the list and its nav in a Turbo Frame — the aggregate bar and filter sidebar stay outside it:**

```erb
<%# app/views/employees/index.html.erb %>
<div class="employee-page-layout">
  <div class="employee-main">
    <%= render "aggregate_bar", aggregates: @aggregates %>

    <%= turbo_frame_tag "employee_list" do %>
      <%= render @employees %>
      <%= render "pagy/nav", pagy: @pagy %>
    <% end %>
  </div>

  <aside>
    <%= render "filters", options: @filter_options %>
  </aside>
</div>
```

Because pagy's nav links are plain `<a href>` tags inside a `turbo_frame_tag`, Turbo intercepts them automatically — no Stimulus, no custom JS.

**Controller skips expensive work when only the frame is requested:**

```ruby
class EmployeesController < ApplicationController
  def index
    @pagy, @employees = pagy(Employee.all, items: Pagy::DEFAULT[:items])
    load_sidebar_data unless turbo_frame_request_id == "employee_list"
  end

  private

  # Step 5 replaces this body with real @aggregates / @filter_options queries.
  # Step 4's job is only to prove this method is skipped on frame-only requests.
  def load_sidebar_data
  end
end
```

`turbo_frame_request_id` is provided by the `turbo-rails` gem and returns the id of the frame that initiated the request, or `nil` for a normal full-page navigation. This is the whole mechanism — no extra headers to hand-roll.

**Why the paginated query itself still always runs:** the row-card list is needed in both cases (full page load and frame-only navigation) — it's cheap (`LIMIT`/`OFFSET`), unlike the aggregate query it sits next to. Only the sidebar data is conditional.

---

## Task order (TDD — write the failing spec before the code that passes it)

1. Add `pagy` to the Gemfile, `bundle install`, include `Pagy::Backend` in `ApplicationController` and `Pagy::Frontend` in `ApplicationHelper`.
2. Create `config/initializers/pagy.rb`: set `Pagy::DEFAULT[:items] = 25`, require `pagy/extras/trim` (drops `?page=1` from URLs — small but real cleanliness win for shareable/bookmarked links).
3. Write `spec/requests/employees_pagination_spec.rb`:
   - `index` with no `page` param returns the first 25 employees (given a seeded 60+ employee fixture set)
   - `index?page=2` returns the next 25, correctly offset
   - `index?page=2`, request sent **with** the `Turbo-Frame: employee_list` header → response status 200, response body includes the second page's employees, and — critically — the `load_sidebar_data` call is **not** made (spy/stub on the controller instance and assert `not_to have_received`)
   - `index` with **no** Turbo-Frame header (a normal full-page load) → `load_sidebar_data` **is** called
4. Run specs, confirm they fail (no pagination wired up yet).
5. Implement the controller changes above until specs pass.
6. Update `Employee` index view: paginate the row-card render, wrap list + nav in `turbo_frame_tag "employee_list"`, leave aggregate bar and filter sidebar outside it (as already-placeholder markup from Step 3).
7. Vendor pagy's nav partial into the app (`app/views/pagy/_nav.html.erb`) rather than fighting its default `.pagy-nav` CSS classes — restyle its markup directly with the app's tokens:
   - Active page: `--color-primary` filled background, white text
   - Inactive pages: `--color-text` on `--color-surface`, `--color-border` outline, hover state using `--color-primary-hover` at low opacity or as a text-color shift
   - Prev/Next: icon (`chevron-left` / `chevron-right`) + visible label ("Previous" / "Next"), matching Step 3's icon+label rule — pagy nav links are still actionable controls, so they follow the same convention as every other button in the app
   - Disabled prev/next (first/last page): visibly muted, `--color-text-muted`, `aria-disabled="true"`, not a dead-looking default gray that clashes with the theme
8. Manually verify in-browser: clicking a page number swaps only the row-card list and nav; the aggregate bar and filter sidebar visibly do not flicker/reload; check the Network tab to confirm the request carries the `Turbo-Frame` header and returns 200.
9. Run the full spec suite to confirm nothing from Steps 1–3 broke.

---

## Acceptance criteria

- [ ] `pagy` installed and configured, default page size 25
- [ ] Employee index paginates correctly; page count and offset are correct against a seeded fixture set
- [ ] Row-card list and pagy nav are wrapped in `turbo_frame_tag "employee_list"`; aggregate bar and filter sidebar are outside that frame
- [ ] A pagination request sent with the `Turbo-Frame: employee_list` header does **not** trigger `load_sidebar_data` (verified by spec, not just visually)
- [ ] A normal full-page load **does** trigger `load_sidebar_data`
- [ ] Pagy's nav is restyled with the app's color tokens — active page uses `--color-primary`, not pagy's default unstyled markup
- [ ] Prev/Next controls follow the icon+label convention from Step 3, including a visibly distinct disabled state at the first/last page
- [ ] Clicking a page number does not cause a full page reload or any visible change to the filter sidebar/aggregate bar
- [ ] Full spec suite from Steps 1–3 still passes unmodified
- [ ] No aggregate computation or filter query logic was actually implemented here — `load_sidebar_data` remains a no-op stub for Step 5 to fill in
