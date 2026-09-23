# Decisions Log

Records the *why* behind choices that either aren't self-evident from the code, or that intentionally depart from [`docs/requirements.md`](requirements.md). [`docs/design_notes.md`](design_notes.md) covers *how* the UI is built; this file covers *why* the underlying architecture and process choices were made the way they were.

## 1. `employee.currency` became `employee.exchange_rate_id`

[`docs/requirements.md` §4](requirements.md) specifies the `employee` table with its own `currency` (string) column, separate from `exchange_rate`. The actual schema never had one — `employees.exchange_rate_id` is a foreign key to `exchange_rates` from the very first migration, and `Employee#currency` is a `delegate :currency, to: :exchange_rate`.

A plain `employee.currency` string would duplicate data already living on `exchange_rates.currency`, with no mechanism keeping the two in sync — rename a currency code on the `exchange_rates` table (or fix a typo) and every employee row referencing it silently goes stale. Modelling it as a foreign key makes `exchange_rates` the single source of truth: an employee's currency is always whatever its linked exchange rate currently says it is, and the relationship also gets the two features that follow directly from it, at no extra cost — the `belongs_to` association means the currency can't dangle in an unsupported state, and it's what the recalculation job in [§2 of `requirements.md`](requirements.md) walks (`employees.where(exchange_rate_id: ...)`) to find which employees to recompute when a rate changes.

## 2. One dynamic chart instead of three fixed ones

The dashboard is built around a single chart driven by three controls (group by / aggregation / date range) rather than three separate fixed charts — this is already the shape recorded in [`docs/requirements.md` §3](requirements.md), but the requirements doc doesn't capture *why*, so it's recorded here:

- **Faster loads.** Three charts means three queries (at minimum) on every page load, computed and rendered regardless of which one the HR Manager actually wants to look at right now. One chart means one query, and it's exactly the one currently in view.
- **One thing at a time.** Fifteen group-by/aggregation combinations are reachable from the same three controls, so nothing is lost versus three fixed charts — but the page shows one answer to one question, rather than asking the HR Manager to visually parse three charts to find the one relevant to what they're currently asking.

## 3. CockroachDB in production, PostgreSQL in development/test

Production runs on CockroachDB (`activerecord-cockroachdb-adapter`); development and test run plain PostgreSQL (`config/database.yml`). This is a cost/availability decision, not a technical requirement of the app itself — nothing in the code depends on CockroachDB specifically, and the adapter is wire-compatible with the `pg` gem's SQL surface.

The reasoning: finding a free-tier Postgres host that doesn't require a credit card is genuinely hard. A few (Aiven, Neon) offer reasonable free tiers, but they sleep the instance when idle, and the wake-up latency on the first request after sleep is considerable — a bad first impression for a demo/assignment deployment. CockroachDB Cloud's free tier gives 10 GB of storage, doesn't require a card, and its wake-up latency is comparatively low. It was chosen for cost and availability, not because the application needs anything CockroachDB-specific over Postgres.

**This is a deliberate, temporary asymmetry, not the target end state.** Development and production running different databases is worth tolerating for a free-tier assignment deployment, but not for an application that's actually grown — dialect differences between Postgres and CockroachDB are a real (if currently unhit) source of bugs that only get more expensive to find the longer dev/prod diverge. Once there's budget for it, production should move to a dedicated PostgreSQL instance instead.

## 4. Solid Queue in-process with Puma instead of Sidekiq + Redis

The initial choice was Sidekiq, but Sidekiq needs Redis, and that's another piece of paid/free-tier infrastructure to provision and keep alive on top of the database. Solid Queue was chosen instead specifically because it can run against the database that's already there — no new service to add.

On top of that, `config/puma.rb` runs the Solid Queue supervisor *inside* the same Puma process as the web server (`plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`), rather than as a separate worker process or service, so the whole app — web requests and job processing both — runs on one server.

**This is a known trade-off, not a recommended pattern** Sharing Puma's process between web and worker means a burst of job processing competes with web requests for the same threads, and sharing one database between application data and the job queue means job-table writes compete with the app's own OLTP load — neither is how a production system at real scale should be run. It's an acceptable shortcut for a single low-traffic free-tier deployment where the alternative is provisioning and paying for a separate worker dyno and a separate Redis instance for a job volume that doesn't currently need either. Once the application has real traffic or job volume, this should split back out: Solid Queue (or another backend) on its own dedicated database, running in its own process/dyno rather than inside Puma.
