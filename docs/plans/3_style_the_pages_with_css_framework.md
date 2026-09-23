# Style the Pages with a CSS Framework (Step 3, Revised)

## Objective

Implement the revised visual design system: color tokens, IBM Plex Sans typography (no monospace, no second serif), icons, app shell with an active-state navbar, buttons, flash messages, form styling, and the Employee index as a single row-card component that reflows internally rather than switching between a table and a card template. This step is visual and structural only — no new routes, controllers, or business logic. Every interaction from Step 2 (create/edit/delete, Turbo navigation, `turbo_confirm` dialogs) must keep working exactly as before, just styled.

## Framework & fonts

- `tailwindcss-rails`, no Node/npm dependency.
- **Font: IBM Plex Sans only** — weight 400 for body, 500 for emphasized values/numbers, 600 for headings and nav. Do not load Zilla Slab or IBM Plex Mono; they're dropped from the system entirely.
- Define colors as CSS custom properties on `:root` (see token block below), wired into `tailwind.config.js` under `theme.extend.colors`.

```css
:root {
  --ledger-primary: #ff6f59;
  --ledger-primary-hover: #e85742;
  --ledger-bg: #f2f9f8;
  --ledger-surface: #ffffff;
  --ledger-border: #d3e6e4;
  --ledger-text: #10292c;
  --ledger-text-muted: #5c7c7a;
  --ledger-destructive: #d1264f;

  --ledger-nav-bg: #0e3b2e;
  --ledger-nav-border: #175040;
  --ledger-nav-text: #eaf6f2;
  --ledger-nav-text-muted: #9fc4b8;
  --ledger-nav-active: #ff6f59;
}

@theme inline {
  --color-primary: var(--ledger-primary);
  --color-primary-hover: var(--ledger-primary-hover);
  --color-bg: var(--ledger-bg);
  --color-surface: var(--ledger-surface);
  --color-border: var(--ledger-border);
  --color-text: var(--ledger-text);
  --color-text-muted: var(--ledger-text-muted);
  --color-destructive: var(--ledger-destructive);

  --color-nav-bg: var(--ledger-nav-bg);
  --color-nav-border: var(--ledger-nav-border);
  --color-nav-text: var(--ledger-nav-text);
  --color-nav-text-muted: var(--ledger-nav-text-muted);
  --color-nav-active: var(--ledger-nav-active);
}
```

## Scope boundaries

**In scope:**

- Color tokens above, IBM Plex Sans type system (headings 600 / body 400 / numeric emphasis 500 with `font-variant-numeric: tabular-nums`)
- App shell: navbar on `--color-nav-bg`, with a working **active-link state** (`aria-current="page"` plus either a coral underline or a coral pill — pick one and apply it consistently) and flash message styling (`notice` vs `alert`)
- Icon partials (Lucide, vendored inline SVG) for: `plus-circle`, `pencil`, `check`, `trash-2`, `x`, `sliders-horizontal`, `search`
- **Every actionable button gets both an icon and a visible text label — no icon-only buttons anywhere in the app.** Apply this uniformly to Employee create/edit/delete and both Exchange Rate row states (`Edit`/`Delete` display state, `Save`/`Cancel` edit state)
- Employee index as **one row-card component**: `display: flex; flex-wrap: wrap;` internal layout that spreads fields on one line at wide widths and wraps onto stacked lines at narrow widths — never a `<table>`, never two separate partials for "desktop" and "mobile"
- Truncation + `title`/`aria-label` pattern on name/title/department within the row-card
- Employee form: joined salary/currency control, label+inline-error row, content-sized inputs
- Exchange Rate index: display/edit row states sharing one fixed `grid-template-columns`, with all four buttons icon+label as above
- Reserving (not building) the filter sidebar/drawer and the five-stat aggregate bar as empty, styled containers — same as the original plan, unaffected by this revision

**Explicitly out of scope (do not implement):**

- Any `<table>` element for the employee listing, at any viewport width
- Any monospace or slab-serif font — one sans-serif family only, per above
- Any icon-only button anywhere
- Pagination logic (Step 4), search/filter/aggregate logic (Step 5), dashboard (Step 7)
- Any new route, controller, or model logic
- Changing `turbo_confirm` text or destructive-action behavior — style the button, don't touch its `data` attributes

If you find yourself building a second template to handle mobile vs desktop for the employee list, stop — it should be one component that reflows via CSS, not two templates behind a breakpoint.

---

## Task order

1. Add `tailwindcss-rails`, run `bin/rails tailwindcss:install`, confirm `bin/dev` compiles.
2. Add the Google Fonts `<link>` for IBM Plex Sans (400/500/600) only.
3. Define the color tokens above as CSS custom properties and wire them into `tailwind.config.js`.
4. Set the type scale and weight assignments (600 headings/nav, 400 body, 500 numeric emphasis with `tabular-nums`).
5. Vendor the Lucide icon partials and build a shared helper that always renders icon + visible label together — no variant that omits the label.
6. Build the navbar: brand wordmark, `Employees` / `Exchange Rates` links on `--color-nav-bg`, active-link treatment with `aria-current="page"`, and the flash partial.
7. Build primary (`--color-primary`, solid) and destructive (`--color-destructive`, outlined that fills on hover) button styles as reusable classes, and apply them — with icon + label — to every create/edit/delete/save action across both resources.
8. Build the Employee row-card component: one partial, flex-wrap internal layout, truncation pattern applied to name/title/department, salary+currency grouped and right-aligned. Reserve the filter sidebar/drawer region and aggregate bar container as empty placeholders.
9. Style the Employee `new`/`edit` form: joined salary/currency control, label+inline-error row with `aria-describedby`/`aria-invalid`, content-sized inputs.
10. Style the Exchange Rate index: shared fixed-column grid between display and edit states, and confirm all four buttons (`Edit`, `Delete`, `Save`, `Cancel`) use identical icon+label styling and sizing.
11. Verify every Turbo-driven interaction from Step 2 still works styled: inline exchange rate add/edit/delete, employee delete-in-place, full-page employee create/edit, success and 422-error states.
12. Check the row-card at 375px, 768px, and 1440px widths — confirm it's genuinely the same DOM reflowing (inspect and confirm no separate markup), and that the navbar active state is visibly correct on both pages.
13. Run the full spec suite to confirm nothing broke — markup restructuring can silently drop something a request spec depends on (button text, `dom_id`, `data-turbo-confirm`, `aria-current`).

## Testing note

No new automated specs come out of this step. Verified by (a) the existing suite passing unmodified, and (b) manual visual review at the three widths above, on both pages, including confirming the navbar correctly marks whichever page is active.

---

## Acceptance criteria

- [ ] All colors are the finalized Petrol & Coral + dark-green-navbar tokens, applied via CSS custom properties, not hardcoded hex
- [ ] IBM Plex Sans is the only typeface in the app; no monospace or serif font is loaded or referenced anywhere
- [ ] Numeric figures use `tabular-nums` for alignment, not a separate font
- [ ] Every button in the app has both an icon and a visible label — verified specifically on the Exchange Rate row's four buttons (`Edit`, `Delete`, `Save`, `Cancel`), which must be visually identical in pattern
- [ ] The navbar clearly marks the current page via `aria-current="page"` plus a consistent visual treatment
- [ ] The Employee index uses one row-card component with no `<table>` markup at any width, confirmed by inspecting the rendered DOM at 375px, 768px, and 1440px and seeing the same elements reflow rather than different partials rendering
- [ ] Salary and currency remain one grouped, right-aligned unit at every width
- [ ] Full spec suite from Steps 1–2 still passes unmodified
- [ ] No new routes, controllers, pagination, search logic, aggregate computation, or dashboard code introduced
