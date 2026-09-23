# Planning Document:

This file will contain the plans and to-do list to build this application from ground up.

To-Do:

- [x] 1. Create Tables and Models
- [x] 2. Set up Views and Controllers for Basic CRUD
- [x] 3. Style the Pages with CSS Framework
- [x] 4. Implement Pagination
- [x] 5. Implement Search Functionality and Aggregation Data Display
- [x] 6. Implement the Currency Normalization Functionality
- [x] 7. Create the Dashboard Page
- [x] 8. Write a Script to Seed the Database
- [ ] 9. Code Optimization and Feature Improvements

## 1. Create Tables and Models

We'll create migrations for employee and exchange_rate, including indexes on the columns we'll filter and group by later — department, country, job_title, and currency — so search and aggregation stay fast once the table holds 10,000+ rows. We'll add model-level validations (presence, uniqueness on employee_code, currency format) and write the validation tests first, before implementing the validations that make them pass.

Refer: [docs/plans/1_create_tables_and_models.md](plans/1_create_tables_and_models.md)

## 2. Set up Views and Controllers for Basic CRUD

We'll build `EmployeesController` and `ExchangeRatesController` with standard CRUD actions, using Turbo Frames/Streams for edit and delete so the page doesn't do a full reload. Controllers stay thin — validation lives in the model, and filtering/aggregation logic is deferred to dedicated query objects in step 5. We'll write request tests for the happy path and validation failures before building out the views themselves.

Refer: [docs/plans/2_set_up_view_and_controllers_for_basic_crud.md](plans/2_set_up_view_and_controllers_for_basic_crud.md)

## 3. Style the Pages with CSS Framework

We'll pick a lightweight CSS framework that works with server-rendered Hotwire views without needing a JS build step, and apply consistent layout, table, and form styling across the employee and exchange rate pages. Getting this in early means the dashboard in step 7 can reuse the same look instead of styling being bolted on at the end.

Refer: [docs/plans/3_style_the_pages_with_css_framework.md](plans/3_style_the_pages_with_css_framework.md)

## 4. Implement Pagination

We'll add pagination to the employee index so we're never loading all 10,000+ records at once. We'll make sure pagination state persists correctly alongside search/filter params, and that page navigation happens via Turbo Frame rather than a full page reload.

Refer: [docs/plans/4_implement_pagination.md](plans/4_implement_pagination.md)

## 5. Implement Search Functionality and Aggregation Data Display

We'll build a query object that takes filter params (department, country, job_title, currency, name/code search) and returns a scoped relation, plus an aggregates object that computes min/max/avg/count/sum over that same scope. The search form will submit via Turbo, debounced with Stimulus, and the aggregate summary bar will update to reflect the filtered set rather than the whole table. We'll test the query and aggregate logic in isolation, independent of any view.

Refer: [docs/plans/5_implement_search_functionality_and_aggregation_data_display.md](plans/5_implement_search_functionality_and_aggregation_data_display.md)

## 6. Implement the Currency Normalization Functionality

We'll build a normalizer service that converts an employee's local_salary to normalized_usd_salary using the current exchange rate for that currency, called on employee create/update. When an exchange rate is edited, we'll enqueue a background job that recalculates normalized_usd_salary for every employee in that currency, so a rate change doesn't block the request. We'll unit test the normalizer on its own and test that editing a rate enqueues the job and produces correct results.

Refer: [docs/plans/6_implement_the_currency_normalization_functionality.md](plans/6_implement_the_currency_normalization_functionality.md)

## 7. Create the Dashboard Page

One card split into a chart and a controls panel. Three parameters — group by (department/job title/country), aggregation (min/max/avg/sum/count), and a created-at date range — jointly determine a single chart, replacing the original three-fixed-chart idea. Sum/count render as pie, min/max/avg as bar. Group by and aggregation use segmented controls. New Dashboard:: query and presenter objects handle the data, separate from Step 5's Employee::FilterService. ECharts loads via an importmap pin. Changing a parameter updates only the chart via Turbo Frame.

Refer: [docs/plans/7_create_the_dashboard_page.md](plans/7_create_the_dashboard_page.md)

## 8. Write a Script to Seed the Database

An interactive Faker-backed generator writes two CSVs (exchange rates, then employees referencing them), mixing in deliberately invalid rows. A namespaced import service validates rows via the model, batch-inserts with insert_all, computes normalized_usd_salary per row, and logs rejects to a timestamp-free error file. db/seeds.rb just calls it. Specs use small fixtures, not the real dataset.

Refer: [docs/plans/8_write_a_script_to_seed_the_database.md](plans/8_write_a_script_to_seed_the_database.md)

## 9. Code Optimization and Feature Improvements

Added an feature to perform money conversions on exchange rate listing page. Fixed the `ExchangeRate` deletion where it was failing with referencial integrity. Fixed the bug where `Employee` deletion was not updating the aggregation data. Added hover title for salary `div` element to show normalized USD value. Turned off default HTML autocomplete for input fields with unique validation. Updated the charts layout such that it can accomodate large number of categories (bars).
