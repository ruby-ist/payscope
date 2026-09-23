# Salary Visualizer Page (Step 7)

## Objective

Build a single visualizer page: one big card, split into a chart panel and a controls panel. Three parameters — group by, aggregation, and a created-at date range — jointly determine one chart's contents. Changing any parameter re-renders only the chart panel via a Turbo Frame; the controls panel never reloads.

## Before naming anything — check existing convention first

`Dashboard::` is the working namespace for this step's two new service objects, mirroring how `Employee::FilterService` is organized. Before creating either object, look at the actual folder structure and namespacing of the existing services on disk — confirm `Dashboard::` under the same parent directory `Employee::` lives in is consistent with that pattern, rather than assuming it without checking.

## Layout

```
┌───────────────────────────────────────────────────────────┐
│                                                             │
│   ┌───────────────────────────┐   ┌─────────────────────┐ │
│   │                           │   │ Group by             │ │
│   │                           │   │ [Dept][Title][Country]│ │
│   │        chart panel        │   │                      │ │
│   │      (bar or pie)         │   │ Aggregation          │ │
│   │                           │   │ [Min][Max][Avg][Sum][Count] │
│   │                           │   │                      │ │
│   │                           │   │ Created between       │ │
│   │                           │   │ [from]   [to]         │ │
│   └───────────────────────────┘   └─────────────────────┘ │
│                                                             │
└───────────────────────────────────────────────────────────┘
```

One card, roughly 60/40 chart-to-controls on wide viewports. Below the 768px breakpoint, stack controls above the chart — same reflow discipline already used for the employee row-cards.

## Parameter behavior

- **Group by** — segmented control (Department / Job title / Country), single-select, applies immediately.
- **Aggregation** — segmented control (Min / Max / Avg / Sum / Count), single-select, applies immediately.
- **Created-at range** — two date inputs, inclusive bounds, same convention as Step 5.

All three live in one `<form>` targeting the chart's Turbo Frame. Reuse Step 5's auto-submit Stimulus controller, attached once at the form level for `change` events bubbling from any descendant.

Segmented controls are a styled `fieldset`/`legend` radio group with visually-hidden native inputs and pill-styled labels — real radio semantics, not ARIA-tab mimicry, degrading cleanly with no JS.

## Chart type follows aggregation

| Aggregation | Chart type |
| ----------- | ---------- |
| Sum         | Pie        |
| Count       | Pie        |
| Min         | Bar        |
| Max         | Bar        |
| Avg         | Bar        |

One explicit, visible constant — not inferred from scattered conditionals.

## Data layer — design requirements

**`Dashboard::SalaryBreakdownQuery`** — takes group-by field, aggregation, and optional date range once, in its initializer. One public method, named for what it returns, not `call`. Whitelists the group-by param against the three allowed columns and the aggregation param against the five allowed operations — an unvalidated column/function name reaching raw SQL is an injection surface. Falls back to a sensible default (department, sum) on missing or invalid input. Applies the date range as a single inclusive-bounds filter on `created_at`.

This object does **not** reuse or extend `Employee::FilterService` — that object's nine general-purpose filters solve a different shape of problem than this page's single-purpose grouped aggregation, and stretching it to cover both would blur what each is for. Returns results grouped and aggregated over `normalized_usd_salary` in one query, ordered by group label for a stable chart.

**`Dashboard::SalaryChartPresenter`** — takes the breakdown results and the requested aggregation once, in its initializer. One public method, named for what it returns (a chart configuration). Looks up chart type from the mapping above, shapes data into ECharts' expected structure for that type (categories+values for bar; name/value pairs for pie). This is the only place chart-type knowledge lives — the breakdown object has no opinion on bar vs pie.

## Turbo Frame mechanism

No separate expensive-sidebar-data concern here — the single breakdown query is the only work this page does, for both full load and parameter change. No `turbo_frame_request_id` branching needed. Wrap the chart panel in a Turbo Frame; the controls form targets it on submit; Turbo's default fetch-and-swap is sufficient with zero conditional logic in the controller.

## Chart rendering — Apache ECharts via a CDN-pinned importmap entry

Load ECharts through Rails' importmap, pinned to a CDN-hosted ES module rather than a `<script>` tag:

```
bin/importmap pin echarts
```

This adds a `pin "echarts", to: "https://..."` line in `config/importmap.rb` pointing at a CDN-hosted ESM build. The browser resolves and fetches it as a real JS module the first time it's imported, cached like any other pinned dependency — no manual `<script src>` tag anywhere in the layout or in any view.

Import it directly in the chart's Stimulus controller module:

```javascript
import * as echarts from "echarts";
```

Because this is a real ES module import inside the controller file — resolved once, by the browser's module graph, when `controllers/index.js` first loads — it is **not** re-fetched or re-executed on every Turbo Frame swap. A frame swap only touches the DOM nodes inside the frame; it has no effect on already-resolved JS modules.

The controller should still fully dispose and reinitialize the ECharts _instance_ on every `connect()`. Bar and pie configurations differ structurally (axes exist on one, not the other), so dispose-and-reinit avoids stale leftover config from a previous chart type. `disconnect()` calls ECharts' dispose method so swapping away doesn't leak instances. One generic controller handles both chart types via `echarts.init` + `setOption` from the JSON configuration alone.

## Scope boundaries

**In scope:**

- Confirming the existing service-object namespacing convention before writing any new class
- Route and a `DashboardController#show` action
- The card layout, segmented controls, date range form
- `Dashboard::SalaryBreakdownQuery` and `Dashboard::SalaryChartPresenter`, correctly namespaced
- Pinning ECharts via `bin/importmap pin echarts` (CDN-resolved) and importing it in the chart Stimulus controller
- The chart Turbo Frame
- Specs for all of the above

**Explicitly out of scope:**

- Any second chart, saved view, or URL/bookmark state syncing
- Click-through/drill-down on chart segments
- CSV or image export
- Any change to the employee listing page or its Step 5 aggregate bar
- Any change to `Employee::FilterService`
- Any `<script src="...echarts...">` tag — importmap only

If you find yourself adding a CDN `<script>` tag directly to the layout, or dropping a new service flat into `app/services/` without checking the existing namespacing, stop.

---

## Task order (TDD)

1. Inspect existing service objects to confirm folder structure and namespacing before naming anything new; confirm `Dashboard::` fits, adjust if it doesn't.
2. Run `bin/importmap pin echarts`; confirm the pin appears in `config/importmap.rb` resolving to a CDN URL.
3. Add the route and a minimal `DashboardController#show` rendering the static layout shell — confirm the page loads.
4. Write a spec for `Dashboard::SalaryBreakdownQuery`: seed employees across all three group-by dimensions with known `normalized_usd_salary` values and varied `created_at` timestamps. Assert each of the five aggregations produces hand-computed correct results per group-by field; assert date range filtering with only-from, only-to, both, neither, inclusive on boundaries; assert invalid group-by/aggregation falls back to the default rather than raising.
5. Run, confirm failure. Build the breakdown object until green.
6. Write a spec for `Dashboard::SalaryChartPresenter`: given known breakdown results, assert sum/count produce a pie-shaped configuration and min/max/avg produce a bar-shaped configuration; assert values/labels match the input exactly.
7. Run, confirm failure. Build the presenter until green.
8. Write request specs for `DashboardController#show`: default params render a sensible default chart; each group-by/aggregation combination, alone and with a date range, returns correct chart type and values; a request carrying the chart frame's Turbo-Frame header returns only that frame's content; invalid/tampered params don't error.
9. Run, confirm failure. Wire the controller and views until green.
10. Build the chart container partial and its Stimulus controller — `import * as echarts from "echarts"` at the top, init on `connect()`, dispose on `disconnect()`.
11. Build the segmented controls and date range inputs inside the one form targeting the chart frame, using the reused Step 5 auto-submit controller.
12. Manually verify in-browser: each control updates only the chart immediately; switching between pie-producing and bar-producing aggregations renders cleanly with no leftover axis artifacts; date range narrows values correctly; confirm in the Network tab that echarts loads once, as a pinned module resolved from the CDN, not re-fetched on subsequent parameter changes; keyboard navigation through segmented controls works and is announced correctly.
13. Run the full spec suite to confirm nothing from Steps 1–6 broke.

---

## Acceptance criteria

- [ ] `Dashboard::SalaryBreakdownQuery` and `Dashboard::SalaryChartPresenter` live in the same namespaced, per-domain folder convention already established by `Employee::FilterService`
- [ ] Both are independently tested, single-purpose, and distinct from `Employee::FilterService` rather than an extension of it
- [ ] Group-by and aggregation params are whitelisted server-side, with a safe default on invalid input
- [ ] The five aggregations map to exactly two chart types via one explicit, visible constant
- [ ] ECharts is loaded exclusively via an importmap pin resolving to a CDN-hosted ES module, imported in the chart Stimulus controller — no CDN `<script>` tag anywhere in the app
- [ ] Changing any of the three parameters updates only the chart Turbo Frame — the controls panel never reloads
- [ ] Segmented controls are real radio groups with correct screen-reader semantics
- [ ] The chart Stimulus controller disposes its previous instance before reinitializing on every frame swap
- [ ] Full spec suite from Steps 1–6 still passes unmodified
- [ ] The requirements doc's Section 3 is updated to describe this single-visualizer design in place of the original three-fixed-charts description, with a line on why
