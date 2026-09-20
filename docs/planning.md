# Planning Document:

This file will contain the plans and to-do list to build this application from ground up.

To-Do:

- [x] 1. Create Tables and Models
- [x] 2. Set up Views and Controllers for Basic CRUD
- [ ] 3. Style the Pages with CSS Framework
- [ ] 4. Implement Pagination
- [ ] 5. Implement Search Functionality and Aggregation Data Display
- [ ] 6. Implement the Currency Normalization Functionality
- [ ] 7. Create the Dashboard Page
- [ ] 8. Write a Script to Seed the Database
- [ ] 9. Code Optimization and Feature Improvements

## 1. Create Tables and Models

We'll create migrations for employee and exchange_rate, including indexes on the columns we'll filter and group by later — department, country, job_title, and currency — so search and aggregation stay fast once the table holds 10,000+ rows. We'll add model-level validations (presence, uniqueness on employee_code, currency format) and write the validation tests first, before implementing the validations that make them pass.

Refer: `docs/plans/create_tables_and_models.md`

## 2. Set up Views and Controllers for Basic CRUD

We'll build `EmployeesController` and `ExchangeRatesController` with standard CRUD actions, using Turbo Frames/Streams for edit and delete so the page doesn't do a full reload. Controllers stay thin — validation lives in the model, and filtering/aggregation logic is deferred to dedicated query objects in step 5. We'll write request tests for the happy path and validation failures before building out the views themselves.

Refer: `docs/plans/set_up_view_and_controllers_for_basic_crud.md`

## 3. Style the Pages with CSS Framework

We'll pick a lightweight CSS framework that works with server-rendered Hotwire views without needing a JS build step, and apply consistent layout, table, and form styling across the employee and exchange rate pages. Getting this in early means the dashboard in step 7 can reuse the same look instead of styling being bolted on at the end.

Refer: `docs/plans/style_the_pages_with_css_framework`

## 4. Implement Pagination

TBU

## 5. Implement Search Functionality and Aggregation Data Display

TBU

## 6. Implement the Currency Normalization Functionality

TBU

## 7. Create the Dashboard Page

TBU

## 8. Write a Script to Seed the Database

TBU

## 9. Code Optimization and Feature Improvements

TBU
