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

The five-stat aggregate bar above the list holds the min/max/avg/count/sum of the filtered set — a flex row on desktop, a horizontally scroll-snapping strip on mobile. Amounts render through `usd_amount`, which shows an em dash until Step 6 normalizes a salary.

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
Display:  1  EUR   =  0.900000    USD    [✎ Edit]  [🗑 Delete]
Edit:     1 [EUR ] =  [0.9      ] USD    [✓ Save]  [x Cancel]
```

`USD` is fixed as the base, matching `normalized_usd_salary` as the reporting metric. There are **no column headers** — each row describes itself. Displayed rates are formatted to 6 decimal places to match the column's `decimal(12,6)` scale; the input keeps the raw value so it stays easy to type over.

**No layout shift on toggle.** `.rate-equation` is a 5-column grid with the currency and rate columns pinned to `calc(4ch + 1rem + 2px)` and `calc(12ch + 1rem + 2px)` — the §8 content widths plus the input's own padding and border. Display and edit share it. `.rate-value` additionally gives displayed values the same padding and a *transparent* border, so text sits exactly where the input's text sits; without it the equation jiggles on toggle even with the columns fixed.

**The add form is not always present.** The `new_exchange_rate` frame holds *either* an "Add exchange rate" button or the form. `GET /exchange_rates/new` re-renders the index with that frame switched into its form state — the same approach row editing uses — so it degrades to a normal full-page navigation without JS. Creating a rate appends the row and swaps the button back.

**One Cancel link serves both frames.** It points at `exchange_rates_path`; Turbo extracts only the matching frame, so a row frame returns to its display row and the new frame returns to its button.

Rows stripe with `even:bg-surface-alt` like the employee list. The striping class sits on the frame, and the frame is rendered from three places (index, create stream, update stream), so that markup is extracted into `_rate_frame` / `_new_frame` partials — otherwise a streamed row arrives unstriped.

> **Implementation trap, hit twice:** the edited row must render the errored object, not the equal-by-id member of `@exchange_rates`. That collection is a fresh query, so its rows carry no validation errors — passing one to the form silently drops both the error message and the user's rejected input while still appearing to toggle correctly. There is a spec guarding this.

---

## 10. Flash Messages

Flash is a floating toast, deliberately outside the document flow so showing one never shifts the page: a `fixed` container, top-centred via `inset-x-0 mx-auto` (centred without a `transform`, which would otherwise become a containing block for descendants). It renders outside `<main>` for the same reason.

- `notice` is bordered in primary with a `check` icon; `alert` in destructive with an `x`.
- Each toast has a dismiss control; `flash_controller.js` removes just that toast.
- `pointer-events-none` on the container with `pointer-events-auto` on each toast, so the empty container never swallows clicks on the page beneath it.
- `role="status" aria-live="polite"`. Caveat: the stream replaces the live-region node itself, so announcement on turbo_stream updates isn't guaranteed — reliable announcing would need a permanent region with only its children swapped.
- The container keeps `id="flash"`, which every stream response targets via `turbo_stream.replace "flash"`. Controllers set `flash.now` in their `format.turbo_stream` branches, so the message renders on that response without leaking into the next one.

---

## 11. Breakpoints

Two are in play, and they are not interchangeable:

- **640px (`sm`)** — internals of an employee row: field grid 2→4 columns, actions footer→side column.
- **768px (`md`, declared as `--breakpoint-md`)** — filter sidebar ↔ drawer, and the aggregate bar's flex row ↔ scroll-snap strip.

---

## 12. Quick Reference for Implementation

- **Step 4 (pagination):** style controls as `.btn-neutral`; note the list panel's `first:`/`last:` rounding assumes rows are the panel's only children.
- **Step 5 (search/aggregation):** done — fields sit in the left sidebar and drawer containers (§5), real values in the aggregate bar. The sort dropdown sits by "New employee" and joins the sidebar's form through its `form` attribute.
- **Step 6 (normalization):** no visual work, but the employee row's Salary chip and Updated timestamp are where a recomputed value becomes visible.
- **Step 7 (dashboard):** ECharts theming should draw from the §2 tokens rather than introducing new hex values.
