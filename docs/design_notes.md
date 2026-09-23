# Design Doc: Employee Salary Management — Visual & Interaction Spec

_Describes the design as currently implemented. Tokens and component classes live in `app/assets/tailwind/application.css`; shared helpers in `app/helpers/application_helper.rb`._

## 1. Design Principle

The system works as a plain two-tone contrast: a cool **petrol/teal** base that reads calm and data-forward, against a warm **coral** accent that carries every action. A separate **dark forest-green** band anchors the navbar as its own distinct frame around the content, rather than just a darker copy of the page.

The discipline is: two real hues in relationship to each other, one type family, one button pattern everywhere.

---

## 2. Color System

No dark mode — one fixed theme. Raw values sit on `:root` as `--ledger-*`; `@theme inline` maps them onto Tailwind utilities (`bg-primary`, `text-destructive`, `border-nav-border`) so the compiled CSS references the variable rather than a baked-in hex.

| Token                    | Value     | Role                                                            |
| ------------------------ | --------- | --------------------------------------------------------------- |
| `--color-primary`        | `#FF6F59` | Coral. All actions: primary buttons, links, active/focus states |
| `--color-primary-hover`  | `#E85742` | Hover state of primary                                          |
| `--color-bg`             | `#F2F9F8` | Page background — petrol-tinted white, not plain white          |
| `--color-surface`        | `#FFFFFF` | Cards, panels, odd list rows                                    |
| `--color-surface-alt`    | `#F5F7F7` | Alternating (even) list rows                                    |
| `--color-border`         | `#D3E6E4` | Rules, dividers, input borders                                  |
| `--color-text`           | `#10292C` | Primary text                                                    |
| `--color-text-muted`     | `#5C7C7A` | Secondary text, field labels                                    |
| `--color-destructive`    | `#E85742` | Delete actions — currently aliases `--ledger-primary-hover`     |
| `--color-success`        | `#15803D` | Flash notice border/icon/text only                              |
| `--color-error`          | `#DC2626` | Flash alert border/icon/text only                               |
| `--color-nav-bg`         | `#0E3B2E` | Navbar band, and page `<h1>` colour                             |
| `--color-nav-border`     | `#175040` | Navbar bottom rule                                              |
| `--color-nav-text`       | `#9FC4B8` | Navbar inactive links                                           |
| `--color-nav-text-muted` | `#9FC4B8` | Navbar secondary text (same value as `nav-text` today)          |
| `--color-nav-active`     | `#EAF6F2` | Active nav item and the brand area                              |

### Why `surface-alt` exists separately from `bg`

Striped rows first reused `--color-bg`. Because that is the *page* colour, every alternate row read as a gap punched through the panel to the background behind it. `--color-surface-alt` is deliberately a shade darker than `--color-bg` and desaturated toward grey rather than pushed further into the teal, so a striped row still belongs to the card it sits in.

### Primary vs destructive

These are no longer separated by hue — `--color-destructive` points at the same value as `--color-primary-hover`. **Fill and shape carry the entire distinction:**

- **Primary** (Save, Add, New): solid `--color-primary` fill, white text.
- **Destructive** (Delete): outlined — `--color-destructive` text and border on `--color-surface` — filling solid only on hover, as an "arming" cue just before the `turbo_confirm` dialog.

Delete is therefore never signalled by colour alone: outline styling, a trash icon and a confirm dialog are three redundant cues.

### Flash is the one deliberate exception to the one-hue rule

§1's "two real hues" discipline and `destructive`-aliases-`primary-hover` both stop at the flash toast (§10). A toast is a status report shown *after* the action already happened, not another actionable control competing for the coral accent — red/green there reads as "succeeded/failed" the instant it appears, without reading the text. `--color-success` / `--color-error` are scoped to that one component; nothing else should reach for them.

### Scope of the `nav-*` tokens

The navbar is their home, with one sanctioned exception: page `<h1>`s use `text-nav-bg`, tying content headings to the navbar band.

---

## 3. Typography

**One sans-serif family throughout — IBM Plex Sans. No serif, no monospace.** Loaded from Google Fonts at weights 400/500/600.

| Role                                                | Weight |
| --------------------------------------------------- | ------ |
| Headings, nav                                       | 600    |
| Body text, labels, buttons                          | 400    |
| Emphasis within body (field values, salary figures) | 500    |

Numeric figures align via the `.numeric` class (`font-medium` + `tabular-nums`) — tabular figures on the same family, never a second typeface.

Scale: 12 / 14 / 16 (base) / 20 / 24 / 32px, set as `--text-xs` … `--text-2xl`.

---

## 4. Icons & Buttons

Lucide icons, vendored as inline SVG partials in `app/views/shared/icons/` — no npm dependency. `icon(name)` renders one; `icon_label(name, label)` renders icon + visible label and deliberately has **no** label-less variant.

| Action | Icon                 | Label                                |
| ------ | -------------------- | ------------------------------------ |
| Create | `plus_circle`        | "New employee" / "Add exchange rate" |
| Edit   | `pencil`             | "Edit"                               |
| Save   | `check`              | "Save"                               |
| Delete | `trash_2`            | "Delete"                             |
| Cancel | `x`                  | "Cancel"                             |
| Filter | `sliders_horizontal` | "Filter"                             |

Three variants differing only in fill and border: `.btn-primary`, `.btn-destructive`, `.btn-neutral`. All share `px-3 py-2 text-sm` and `gap-1.5` between icon and label, so an Edit and a Delete button are the same size.

**Every actionable button carries a visible label, with one documented exception:** the flash toast's close control (§10) is the `x` icon with an `sr-only` "Close". A toast with the word "Close" spelled out reads wrong, and that control is conventional enough to stand alone.

---

## 5. Employee Listing — Stacked Full-Width Rows

No `<table>` anywhere, at any width. The list is a vertical stack of full-width rows in one panel, from a single partial (`app/views/employees/_employee.html.erb`).

**Rows sit flush, with no gap:**

- `border-x border-t` on every row plus `last:border-b` gives exactly one 1px divider per boundary, instead of two stacked borders.
- Only `first:rounded-t-md` / `last:rounded-b-md`, so the stack reads as one panel rather than a pile of cards.
- `even:bg-surface-alt` stripes the rows. Striping is `:nth-child`-based rather than a render-time index, so it re-alternates the instant a row is removed by `turbo_stream` — and it works with `render @employees`, which passes no counter.

**Fields are labelled pairs in a `<dl>`** — four columns at ≥640px, folding to two below:

```
Employee code | Name       | Job title | Salary
Department    | Country    | Created   | Updated        [✎ Edit]
                                                        [🗑 Delete]
```

- Labels are 12px uppercase muted. Labels and values share the same horizontal padding as the salary chip, so every field's text sits on one edge.
- **Salary and currency are one grouped unit** (`85,000.00 USD`, non-breaking space between), highlighted in a bordered chip. The chip is `bg-bg` on white rows and flips to `bg-surface` on striped rows via `group-even:`, so it always stands off its row instead of dissolving into it.
- Salary is formatted with `number_with_precision(precision: 2)`; `number_with_delimiter` alone leaks the decimal's raw scale (`85,000.0`).
- Timestamps show date **and** time (`20 Sep 2026, 17:29`).
- Actions stack vertically at equal width (`sm:flex-col sm:items-stretch`) beside the field grid, lining up with its two rows. Below 640px they sit side by side in a footer with a top border. Equal width needs `button_to`'s wrapper form to be `flex` (not `inline-block`) plus `justify-center` on the buttons, or Delete stays narrower than Edit.

### Reserved regions

The **filter sidebar sits on the left** — `md:grid-cols-[22rem_minmax(0,1fr)]`, with the `<aside>` before the list in the DOM so reading and tab order match the visual order. Below 768px it becomes a drawer sliding in **from the left**, opened by a `Filter` button and driven by `drawer_controller.js`. Both render the same `employees/_filters` partial: the column is 22rem (drawer `w-88`) so its fields pair up two to a row, including each range's two bounds. Only one of the two copies is reachable at any width, so each scopes its field ids by its form id.

Each group's separating rule sits on a wrapper `<div>`, not on the `<fieldset>` itself — a `<legend>` renders *on* its fieldset's top border and punches a gap in it.

The five-stat aggregate bar above the list holds the min/max/avg/count/sum of the filtered set — a flex row on desktop (`md:flex`), a static `grid grid-cols-2` on mobile. The odd 5th card (Count) gets `col-span-2 mx-auto w-1/2` so it centers alone on its own row instead of sitting flush left; the earlier design used a horizontal scroll-snap strip here, dropped in favour of a wrapping grid so nothing is hidden off-screen. Amounts render through `usd_amount`, which shows an em dash until Step 6 normalizes a salary.

---

## 6. Truncation & Full-Value Tooltips

`truncated_text(value)` is used for name, job title, department and country:

```erb
<span class="truncate" title="<%= value %>" aria-label="<%= value %>"><%= value %></span>
```

`title` gives mouse users the native tooltip; `aria-label` gives screen readers the full value. Containers carry `min-w-0` so the flex/grid child can shrink enough for `truncate` to engage at all.

---

## 7. Navbar — Active State

The navbar sits on `--color-nav-bg` with a `--color-nav-border` bottom rule. The brand is the logo image (`app/assets/images/logo.svg`) linking to root, sized `h-8 w-auto`.

Active state is **colour and weight only — no pill, no underline**:

- Active link: `--color-nav-active` (near-white) at weight 600.
- Inactive links: `--color-nav-text` (muted green) at weight 400, brightening to `--color-nav-active` on hover.
- The active link also gets `aria-current="page"` — one piece of markup produces both the visual and the accessible signal.

`nav_link_to(label, path, controller)` derives "active" from `controller_name`, so `/employees/new` and `/employees/42/edit` both keep Employees marked.

**Mobile: links drop below the logo.** `nav` is `flex-col` below `md`, `flex-row` at `md:` and up. The three links sit in a wrapper `<div>` that's `md:contents` — at `md:` the wrapper stops generating its own box, so its children rejoin the logo as direct flex children of `nav`, exactly the original single-row layout. `gap-y-6` (mobile) matches `py-6`, so the three vertical gaps in the stacked nav — above the logo, between logo and links, below the links — read as one even rhythm instead of a small gap sandwiched between two larger paddings; `md:gap-y-2` restores the original (now-incidental, single-row) value.

---

## 8. Forms

**Focus is the border colour alone.** `.field` sets `focus:border-primary focus:outline-none`, with no ring or outline.

**Label and inline error share one row, adjacent** — `flex flex-wrap items-baseline gap-x-2`, not pushed to opposite edges; `justify-between` left a large void across a wide field. The error span carries an `id`, and the input gets `aria-invalid` plus `aria-describedby` pointing at it.

**Only the first error per field is shown.** A blank currency produces both "can't be blank" and "is invalid"; stacking both is noise while the field is wrong.

**No Rails error wrapper.** `config.action_view.field_error_proc` is overridden to return the tag untouched. Rails' default wraps every errored label and input in `<div class="field_with_errors">`, and that block-level div changed the label row's height and baseline. Error state is already carried by the `field-error` border, the inline message and the ARIA attributes.

**Salary + currency are one joined control** — number input and currency select share a border with no gap (`rounded-r-none border-r-0` / `rounded-l-none`).

**Content-sized inputs, no `w-full` default:** currency `4ch`, exchange rate `12ch`, salary `14ch`, employee code `10ch`, full name `28ch`.

---

## 9. Exchange Rates — A Live Converter

Each rate reads as a sentence rather than a row of columns, in both states:

```
Display:  [1 ] EUR   =  0.900000    USD    [✎ Edit]  [🗑 Delete]
Edit:       1 [EUR ] =  [0.9      ] USD    [✓ Save]  [x Cancel]
```

`USD` is fixed as the base, matching `normalized_usd_salary` as the reporting metric. There are **no column headers** — each row describes itself. Displayed rates are formatted to 6 decimal places to match the column's `decimal(12,6)` scale; the input keeps the raw value so it stays easy to type over.

**No layout shift on toggle.** `.rate-equation` is a 5-column grid with the leading amount, currency and rate columns pinned to `calc(12ch + 1rem + 2px)`, `calc(4ch + 1rem + 2px)` and `calc(12ch + 1rem + 2px)` at `md:` and up — the §8 content widths plus the input's own padding and border (the amount column matches the rate column's width, not the currency column's). Below `md:`, the amount and rate columns shrink to `8ch` (a raw `@media (width >= 768px)` override in `application.css`, since this is a plain CSS component class, not a utility on the element — there isn't room for the full desktop width, and the result column already has `overflow-x-auto` (below) so a value that doesn't fit scrolls instead of clipping the row). Display and edit share both breakpoints. `.rate-value` additionally gives displayed values the same padding and a *transparent* border, so text sits exactly where the input's text sits; without it the equation jiggles on toggle even with the columns fixed.

**The leading `1` is a live multiplier, only in the display state.** Typing into it recomputes the right-hand side as `amount × rate` — `rate_calculator_controller.js` reads the row's raw rate off a data attribute and writes the formatted product straight into the result span. This never touches the persisted rate or hits the server; it's a convenience calculator, not an edit. The edit state's leading `1` stays the static, non-editable span it always was — only the base unit ever changes there, via the currency and rate inputs. That span still needs `.rate-value` (not just `.numeric`) even though it's never a real input: the display state's `1` became a real `.field`-bordered-and-padded input, so without `.rate-value` mirroring that box, the two states' `1`s share a column width but the *glyph* sits at different offsets within it.

**The panel is `max-w-4xl`, wider than a typical card.** A full row — equation, "Synced … ago" label, and the Edit/Delete buttons — needs more horizontal space than the equation alone once the amount column matches the rate column's width; at `max-w-3xl` the synced label had nowhere left to sit and got crushed by `flex-wrap`.

**The result scrolls rather than overflows.** Since the amount is user-typed, `amount × rate` can produce a number far wider than the fixed rate column — `overflow-x-auto whitespace-nowrap` on the result span turns that into a horizontal scroll within the column instead of spilling into neighbouring columns or forcing the grid to grow.

**`autocomplete="off"` on the amount input.** Without it, browsers restore a previously typed amount on a plain page refresh — independent of Turbo entirely, so no server-side reset can fix it. The input always renders `value="1"` server-side; `autocomplete="off"` is what stops the browser from overriding that on reload.

**The add form is not always present.** The `new_exchange_rate` frame holds *either* an "Add exchange rate" button or the form. `GET /exchange_rates/new` re-renders the index with that frame switched into its form state — the same approach row editing uses — so it degrades to a normal full-page navigation without JS. Creating a rate appends the row and swaps the button back.

**One Cancel link serves both frames.** It points at `exchange_rates_path`; Turbo extracts only the matching frame, so a row frame returns to its display row and the new frame returns to its button.

Rows stripe with `even:bg-surface-alt` like the employee list. The striping class sits on the frame, and the frame is rendered from three places (index, create stream, update stream), so that markup is extracted into `_rate_frame` / `_new_frame` partials — otherwise a streamed row arrives unstriped.

> **Implementation trap, hit twice:** the edited row must render the errored object, not the equal-by-id member of `@exchange_rates`. That collection is a fresh query, so its rows carry no validation errors — passing one to the form silently drops both the error message and the user's rejected input while still appearing to toggle correctly. There is a spec guarding this.

**Mobile: actions drop below the equation, pinned right either way.** `.rate-equation` is `w-full md:w-auto` — full width forces it onto its own row, wrapping the synced label and the actions (Edit/Delete, or Save/Cancel in the form) onto a shared row below it. `_form.html.erb` has no synced label sharing that row, so its actions wrapper stays `ml-auto md:ml-0` to pin right — `justify-between` alone isn't enough, since the form has only one item on that row and would otherwise left-align it.

`_exchange_rate.html.erb`'s row does have a synced label sharing that row, so it uses a different, breakpoint-independent pattern instead: the label wrapper is `flex min-w-0 flex-1 md:justify-center` and the actions wrapper is `flex flex-wrap shrink-0 items-center gap-2`, with no `ml-auto` at all — `flex-1` on the label always claims the remaining space (pinning actions to the end as the natural consequence, on both mobile and desktop) and `min-w-0` overrides the flex item's default `min-width: auto` floor, letting a long "Synced … ago" string actually wrap inside its own box instead of forcing the whole line — and the actions with it — down to a third line. `shrink-0` on the actions wrapper guarantees the buttons never get squeezed to make room. `justify-center` stays `md:`-only so the label reads flush-left ("next to the buttons") on mobile and centered between equation and actions on desktop, matching the original single-row layout.

**Deleting a rate still referenced by employees.** `employees.exchange_rate_id` is a DB-level `add_foreign_key` with no `on_delete`, so Postgres — not a Rails validation — rejects the delete, raising `ActiveRecord::InvalidForeignKey`. `ExchangeRatesController#destroy` rescues it and reports a plain-language alert instead of a 500 page; the row is never removed from the DOM in that case (the turbo_stream response only replaces the flash, not the frame), since the record genuinely wasn't deleted.

---

## 10. Flash Messages

Flash is a floating toast, deliberately outside the document flow so showing one never shifts the page: a `fixed` container, top-centred via `inset-x-0 mx-auto` (centred without a `transform`, which would otherwise become a containing block for descendants). It renders outside `<main>` for the same reason.

- `notice` is bordered in `--color-success` (green) with a `check` icon; `alert` in `--color-error` (red) with an `x` — border, icon and text all take the same colour. This is the one place the app breaks its own one-hue rule (§2).
- Each toast has a dismiss control; `flash_controller.js` removes just that toast.
- `pointer-events-none` on the container with `pointer-events-auto` on each toast, so the empty container never swallows clicks on the page beneath it.
- `role="status" aria-live="polite"`. Caveat: the stream replaces the live-region node itself, so announcement on turbo_stream updates isn't guaranteed — reliable announcing would need a permanent region with only its children swapped.
- The container keeps `id="flash"`, which every stream response targets via `turbo_stream.replace "flash"`. Controllers set `flash.now` in their `format.turbo_stream` branches, so the message renders on that response without leaking into the next one.

---

## 11. Breakpoints

Two are in play, and they are not interchangeable:

- **640px (`sm`)** — internals of an employee row: field grid 2→4 columns, actions footer→side column.
- **768px (`md`, declared as `--breakpoint-md`)** — filter sidebar ↔ drawer, the aggregate bar's flex row ↔ 2-column grid (§5), the navbar's single row ↔ stacked logo-then-links (§7), an exchange rate row's single row ↔ equation-then-actions (§9), the dashboard controls' centered row ↔ left-aligned (§12), and the pie chart's right-hand legend ↔ below-chart scrolling legend (§12) — `chart_controller.js` checks `window.innerWidth` against this same 768px value directly, since it has no access to the CSS breakpoint.

---

## 12. Dashboard — Chart Layout

One card, controls stacked above a full-width chart, at every viewport — no side-by-side split. Controls come first in `show.html.erb`'s source order, the `salary_chart` turbo frame second, plain vertical stacking (`mt-6` between them, no grid, no `md:order-*`). Both the frame and the canvas div are already block-level / `w-full`; the card being full-width is what actually makes the chart full-width, not anything sized on the frame itself.

> **Implementation trap:** the `salary_chart` turbo-frame tag's own `class` never varies by chart type — it's a constant `"block p-4"`. Turbo Frame navigation (the controls form retargets this frame on every change) replaces the frame's *content*, not the frame element's own attributes; a class that depended on `chart_config`'s type (e.g. a height present only for bar) could survive a stale value across a pie→bar switch while the newly-swapped content assumed the new one applied. All chart-type-dependent sizing — the fixed `h-80 md:h-96` for bar, the JS-grown height for pie — lives on the inner `data-controller="chart"` div instead, which *is* unambiguously replaced on every navigation. There's a spec guarding the frame's class staying constant.

**Pie legend sits on the right, vertically — on desktop.** `legend: { orient: "vertical", right: 10, top: "middle" }` in `Dashboard::Employee::SalaryChartPresenterService#pie_config`. The series' `center` and the title's `left` both read from one `PIE_CENTER_X = "40%"` constant, so the title stays centered directly over the pie — not over the middle of the whole (now legend-widened) chart area — no matter how that shared value changes later. `title.left` alone only positions the title box's left edge at that x; `textAlign: "center"` is what actually centers the text around it.

**On mobile, the legend moves below the chart instead.** There's no room to its right at that width. `chart_controller.js#layoutPie` checks `window.innerWidth < 768` and, below that, overrides the server-built option: `legend: { orient: "horizontal", type: "scroll", bottom: 0, left: "center" }`, and resets `series.center` back to `["50%", "45%"]` (horizontally centered again, shifted up to leave room below). `type: "scroll"` gives the legend its own left/right paginator for overflow, so the chart uses a flat `360px` height instead of `growForLegend`'s per-item math — that math is specifically for a vertical list that needs to fit in one column without wrapping, which doesn't apply to a horizontal legend that pages instead.

**Controls sit in one horizontal row — centered on desktop, left-aligned on mobile.** `_controls.html.erb`'s form is `flex flex-wrap items-start justify-start gap-8 md:justify-center` (mobile-first: `justify-start` is the base, `md:justify-center` the override), not `space-y-8` — the three fieldsets (Group by, Aggregation, Created between) sit side by side rather than stacked, wrapping onto a new line on narrow viewports instead of overflowing. The From/To date pair inside "Created between" is one `<fieldset>`, so it's already a single flex item in that row — it doesn't need special-casing to avoid pulling apart from its own two inputs.

**Bar values are abbreviated to 1K/1M — everywhere except the tooltip.** `chart_controller.js#abbreviateBarNumbers` sets both `series.label.formatter` (the on-bar top value) and `yAxis.axisLabel.formatter` to the same `abbreviateNumber` function, client-side — ECharts formatters must be real JS functions, which can't survive the server → JSON → client round-trip, so this can't live in the Ruby presenter. `tooltip` is left with no formatter at all, so hovering still shows the exact figure; that's deliberate, not an oversight.

**The bar grid's margins shrink on mobile, desktop keeps the server-built values.** `Dashboard::Employee::SalaryChartPresenterService#bar_config` sets `grid: { top: 80, right: 90, bottom: 80, left: 90, containLabel: true }`, same as before this section's other mobile work — that Ruby service renders server-side with no notion of viewport, so any value it emits applies to every screen size unconditionally. Mobile has much less width to spare, so `chart_controller.js#layoutBar` overrides `option.grid` with a tighter `{ top: 40, right: 70, bottom: 70, left: 70 }` when `window.innerWidth < 768`, the same pattern `layoutPie` uses for the legend. `containLabel: true` is what actually prevents overflow — it shrinks the plot rect *within* whatever box `grid` declares to fit the axis ticks/names, so neither set of values can cause axis content to clip, only reclaim or reserve canvas space. `left` and `right` are still set *equal* in both, not independently — there's a spec (`'gives the plot area equal left and right margins so it sits centered'`) encoding that as a deliberate choice for visual centering of the plot, even though `right` alone has no axis content of its own to justify its size.

---

## 13. Quick Reference for Implementation

- **Step 4 (pagination):** style controls as `.btn-neutral`; note the list panel's `first:`/`last:` rounding assumes rows are the panel's only children.
- **Step 5 (search/aggregation):** done — fields sit in the left sidebar and drawer containers (§5), real values in the aggregate bar. The sort dropdown sits by "New employee" and joins the sidebar's form through its `form` attribute.
- **Step 6 (normalization):** no visual work, but the employee row's Salary chip and Updated timestamp are where a recomputed value becomes visible.
- **Step 7 (dashboard):** ECharts theming should draw from the §2 tokens rather than introducing new hex values; layout itself is §12.
