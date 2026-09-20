# Design Doc: Employee Salary Management — Visual & Interaction Spec (Revised)

## 1. Design Principle

The earlier concept leaned on red-as-ledger-ink, which fought the natural "red = over budget" reading in a salary tool and never quite landed visually. The system that replaced it drops the literal document metaphor and works as a plain two-tone contrast instead: a cool **petrol/teal** base that reads calm and data-forward, against a warm **coral** accent that carries every action. A separate **dark forest-green** band anchors the navbar as its own distinct frame around the content, rather than just a darker copy of the page.

---

## 2. Color System

| Token                    | Value     | Role                                                                                       |
| ------------------------ | --------- | ------------------------------------------------------------------------------------------ |
| `--color-primary`        | `#FF6F59` | Coral. All actions: primary buttons, links, active/focus states                            |
| `--color-primary-hover`  | `#E85742` | Hover/active state of primary                                                              |
| `--color-bg`             | `#F2F9F8` | Page background — petrol-tinted white, not plain white                                     |
| `--color-surface`        | `#FFFFFF` | Cards, panels                                                                              |
| `--color-border`         | `#D3E6E4` | Rules, dividers, input borders                                                             |
| `--color-text`           | `#10292C` | Primary text                                                                               |
| `--color-text-muted`     | `#5C7C7A` | Secondary text, labels                                                                     |
| `--color-nav-bg`         | `#0E3B2E` | Navbar band only                                                                           |
| `--color-nav-border`     | `#175040` | Navbar bottom rule / dividers                                                              |
| `--color-nav-text`       | `#EAF6F2` | Navbar text, inactive links                                                                |
| `--color-nav-text-muted` | `#9FC4B8` | Navbar secondary text                                                                      |
| `--color-nav-active`     | `#FF6F59` | Active nav item — reuses primary coral, so it's the one warm accent against the green band |

The navbar is the only surface allowed to use `--color-nav-*` tokens — it's a deliberately separate palette scope, not a variant of the page background.

---

## 3. Typography

**One sans-serif family throughout — no exceptions, no monospace.** IBM Plex Sans, at two weights:

| Role                                                | Weight |
| --------------------------------------------------- | ------ |
| Headings, brand wordmark, nav                       | 600    |
| Body text, labels, buttons                          | 400    |
| Emphasis within body (field values, salary figures) | 500    |

Numeric figures (salary, exchange rate, employee code) still need columns to line up visually within a card, but that's handled with `font-variant-numeric: tabular-nums;` on the Plex Sans regular/medium weight — not by switching typeface. This gets aligned digits without introducing a second font family.

Scale: 12 / 14 / 16 (base) / 20 / 24 / 32px.

---

## 4. Icons & Buttons

**Every actionable button carries both an icon and a visible text label, with no exceptions.** This is a hard rule, not a per-context judgment call — the earlier inconsistency (one exchange-rate button with icon+word, its neighbor as icon-only) came from treating that as optional. Going full card-based layout (Section 5) also removes the main reason to ever go icon-only — there's no cramped table cell forcing the issue anymore.

| Action                  | Icon                 | Label                       |
| ----------------------- | -------------------- | --------------------------- |
| Create                  | `plus-circle`        | "New employee" / "New rate" |
| Edit                    | `pencil`             | "Edit"                      |
| Save / Update           | `check`              | "Save"                      |
| Delete                  | `trash-2`            | "Delete"                    |
| Cancel                  | `x`                  | "Cancel"                    |
| Filter (mobile trigger) | `sliders-horizontal` | "Filter"                    |
| Search                  | `search`             | "Search"                    |

Icons vendored as inline Lucide SVG partials, no npm dependency. This applies identically to the Exchange Rate row's display state (`Edit` / `Delete`) and edit state (`Save` / `Cancel`) — all four buttons, same icon+label pattern, same sizing.

---

## 5. Employee Listing — Row Cards, No Table, Any Width

There is no `<table>` markup anywhere in this app, at any breakpoint. Every employee is a single **record card**: a bounded, rounded, bordered container (`--color-surface` background, `--color-border` border) whose _internal_ layout reflows with viewport width — one component, not two templates swapped at a breakpoint.

**Wide viewport** — card content lays out as one horizontal flex line, fields spread with `justify-content: space-between`:

```
┌──────────────────────────────────────────────────────────────┐
│ Jane Doe · E0001   Engineer   R&D   🇮🇳 India      ₹85,000  [✎ Edit] [🗑 Delete] │
└──────────────────────────────────────────────────────────────┘
```

**Narrow viewport** — the exact same card, `flex-wrap: wrap` lets the fields fall onto their own lines instead of a second template:

```
┌───────────────────────────┐
│ Jane Doe · E0001            │
│ Engineer · R&D               │
│ 🇮🇳 India                     │
│                    ₹85,000  │
│           [✎ Edit] [🗑 Delete]│
└───────────────────────────┘
```

Implementation-wise this is `display: flex; flex-wrap: wrap; gap: ...;` on the card's inner row, with each field as a flex child that has a natural min-width — no JS, no breakpoint-specific markup, no duplicated partial. Salary and currency stay one grouped unit (`₹85,000`) at both widths, right-aligned. Truncation + `title`/`aria-label` (Section 6) applies to name, title, and department at any width where the flex line gets tight.

The right-hand filter sidebar (desktop, persistent) / drawer (mobile, toggled) and the five-stat aggregate bar above the list are unaffected by this change — they still work exactly as previously specified, just sitting above/beside a list of row-cards instead of a table.

---

## 6. Truncation & Full-Value Tooltips

Unchanged from before — still needed since row-cards can compress at narrow widths:

```erb
<span class="truncate" title="<%= full_value %>" aria-label="<%= full_value %>">
  <%= full_value %>
</span>
```

---

## 7. Navbar — Active State

The navbar sits on `--color-nav-bg` (dark forest green), and needs an unambiguous "you are here" signal:

```
┌────────────────────────────────────────────┐
│  Salary Ledger    [Employees]   Exchange Rates │
│                    ▔▔▔▔▔▔▔▔▔                │  ← coral underline/pill, active only
└────────────────────────────────────────────┘
```

Rules:

- Active link: `--color-nav-active` (coral) as either a filled pill background or a 2px underline — pick one treatment and use it consistently, don't mix pill-for-one-page and underline-for-another.
- Active link also gets `aria-current="page"` — the visual treatment and the accessible signal are the same piece of markup, not two parallel implementations.
- Inactive links: `--color-nav-text` at weight 400; active link steps up to weight 600, same family, no font swap.

---

## 8. Forms

Unchanged in structure from the earlier doc — still relevant with the new palette and single typeface:

**Salary + currency, joined** — one visual control, shared border, no gap between the number input and the currency select.

**Label + inline error, same row** — label left, error message right, `aria-describedby` + `aria-invalid` wiring.

**Content-sized inputs** — currency `4ch`, exchange rate `12ch`, salary `14ch`, employee code `10ch`, full name `28ch`. No `w-full` defaults.

---

## 9. Exchange Rate Inline Edit

Unchanged constraints, restated with the button consistency rule folded in:

1. Edit-state form pre-fills current values — never blank.
2. Display state and edit state share one fixed `grid-template-columns` so toggling causes no layout shift.
3. **All four buttons across both states — `Edit`, `Delete`, `Save`, `Cancel` — use icon+label, same size, same spacing.** This is the specific fix for the reported inconsistency.

```
Display:  USD    │ 1.000000     │ [✎ Edit]   [🗑 Delete]
Edit:     [USD ] │ [1.000000  ] │ [✓ Save]   [x Cancel]
```
