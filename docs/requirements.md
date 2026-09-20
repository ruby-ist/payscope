# Requirements Document: Employee Salary Management Software

## 1. Goal & Product Scope

The objective is to build a web-based employee salary management software tailored for a single HR Manager. The application replaces tedious manual workflows for managing a database of 10,000 employees. The core focus is on organizational and statistical reporting to help the HR Manager instantly answer questions about how the organization pays its people.

## 2. Pre-requisites

- **Authentication Scope:** The application assumes the single HR Manager is already authenticated.

## 3. Web Experience & Core Features

- **Main Listing Page (Management View):** An index page displaying all employee records. The HR Manager can search and filter across various columns to manage the salaries data via web-based software. The view dynamically displays 5 standard aggregate metrics (`min`, `max`, `avg`, `count`, `sum`) based on the active search and filter results.

- **Dashboard Page (Analytics View):** A dedicated reporting interface featuring three primary charts: Salary by `job_title`, Salary by `department`, and Salary by `country`. Each chart can be toggled between 5 operational modes (`min`, `max`, `avg`, `count`, `sum`) to evaluate how organizational segments compare.
- **Record Management (CRUD):** The HR Manager can perform basic CRUD operations on both employee records and exchange rate records.
- **Asynchronous Processing:** When the HR Manager edits an exchange rate, a background job is scheduled to compute and update the `normalized_usd_salary` for all affected employee records without blocking the main UI thread.

## 4. Data Schema & Architecture

### `employee` Table

- `id` (int)
- `employee_code` (string): Acts as the primary organizational identifier since employees may not know their database record ID; this prevents duplicate name issues.
- `full_name` (string)
- `job_title` (string)
- `department` (string)
- `country` (string)
- `local_salary` (decimal): The actual contractual compensation figure paid to the employee in their local currency.

- `currency` (string): The 3-letter ISO currency code.
- `normalized_usd_salary` (decimal): The core reporting metric, computed and stored at the time of creation or update using a static exchange rate dictionary. Storing this normalized value at the database level ensures that aggregate queries for the dashboard charts are highly performant.
- `created_at` (timestamp)
- `updated_at` (timestamp)

### `exchange_rate` Table

- `id` (int)
- `currency` (string)
- `rate` (decimal): The conversion multiplier to the base reporting currency.
- `created_at` (timestamp)
- `updated_at` (timestamp)
- _Note on Updates:_ Updating the exchange rates per month or quarter based on the real-world economy will be the manual responsibility of the HR Manager for the MVP. Depending on change frequency, future iterations may automate this by pulling rates from an external source and update the affected records on regular intervals.

## 5. Data Seeding Strategy

- **Batch Processing:** The application will be populated using a batch-processed CSV seed script generating over 10,000 employees. The seed process ensures a minimum of 10,000 valid records are imported.

- **Invalid Record Handling:** Invalid entries (e.g., unsupported currency, blank name, duplicate employee code, blank local salary) will be automatically filtered during the batch process.
- **Error Logging:** These invalid records will be output to a separate file (either a default path or one provided by the HR Manager). To ensure whoever is seeding can easily find and filter these errors, the invalid records in this secondary file will deliberately not have timestamps.

## 6. Reporting Questions Answered

Using the 5 built-in aggregate modes (`min`, `max`, `avg`, `count`, `sum`) across the application's charts and grid, the HR Manager can answer the following organizational questions:

1. What is the total (`sum`) `normalized_usd_salary` payroll liability distributed across each `department`?
2. Which `job_title` commands the highest average (`avg`) `normalized_usd_salary` globally?
3. What is the total headcount (`count`) of employees operating within a specific `country`?
4. What is the highest (`max`) and lowest (`min`) `local_salary` for a specific `job_title` within a specific `currency`?
5. How does the average (`avg`) `normalized_usd_salary` compare across different countries to evaluate geographic cost efficiency?
6. Which `department` contains the single highest (`max`) earner in the organization?
7. What is the total sum (`sum`) of `local_salary` payouts required for a specific 3-letter `currency` code to prepare regional bank transfers?
8. How many (`count`) employees share the exact same `job_title` within a specific `department`?

## 7. Deliberately Left Out (Trade-offs)

As required by the assessment, the following features are intentionally excluded, along with the reasoning for their omission:

- **CSV Import/Export of Filtered Reports:** Since the HR Manager currently manages the salary data in Excel sheets, it would be helpful to quickly populate the data in our application. We can easily handle the import by making our database seed script reusable. The export option also adds meaningful value when the organization asks for a formal report rather than a straightforward answer. However, exporting a dynamically growing dataset of 10,000+ employees would require a background job, batch operations, and error handling. To submit the assignment in the least possible time, the export feature is excluded from this iteration, but it will be prioritized in next iteration.

- **Salary Breakdowns & Histories:** The core requirement is to help the HR manager answer macro-level questions about how the org pays people rather than performing individual payslip auditing. Therefore, storing historical payslips or granular breakdowns (taxes, allowances, base pay) is omitted from this release. This can be taken up later by transitioning `local_salary` from an editable field to a calculable field based on a breakdown if employees or HR require granular payslip generation.

- **Start Date / End Date:** As we are not storing historical records, there is currently no proper way to do tenure-based reporting. So keeping the schema flat and lean is prioritized to ensure high database performance. Tracking precise Start Dates and End Dates is omitted for now, but these fields can be seamlessly added later if features requiring temporal or tenure-based metrics become necessary.

## 8. Technical Stack & Architecture

- **Backend & Framework:** Ruby on Rails.

- **Frontend & Interactivity:** Hotwire (Turbo & Stimulus).
- **Data Visualization:** Apache Echarts.
- **Architectural Reasoning:** While a decoupled Single Page Application (SPA) is an industry standard, managing two individual repositories increases complexity and effort. To deliver high quality software rapidly, a full-stack Rails monolith architecture was chosen. If the HR Manager ever requires a true SPA-like experience, Hotwire Turbo Streams and partial rendering are fully equipped to handle those front-end scaling needs. This architecture also leaves the door open to provide a mobile-app equivalent experience using PWA/Hotwire Strada in the future.
