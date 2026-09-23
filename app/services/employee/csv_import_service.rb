require "csv"

class Employee
  class CsvImportService
    ImportResult = Data.define(
      :exchange_rates_imported_count, :exchange_rates_rejected_count,
      :employees_imported_count, :employees_rejected_count
    )

    DEFAULT_BATCH_SIZE = 1_000
    DEFAULT_ERROR_LOG_PATH = Rails.root.join("db/seed_data/import_errors.csv")
    ERROR_CSV_HEADERS = %w[type employee_code full_name job_title department country
                           local_salary currency rate error].freeze

    def initialize(exchange_rates_path:, employees_path:, error_log_path: DEFAULT_ERROR_LOG_PATH,
                    batch_size: DEFAULT_BATCH_SIZE)
      @exchange_rates_path = exchange_rates_path
      @employees_path = employees_path
      @error_log_path = error_log_path
      @batch_size = batch_size
      @errors = []
    end

    def import
      exchange_rates_imported_count, exchange_rates_rejected_count = import_exchange_rates
      employees_imported_count, employees_rejected_count = import_employees

      write_error_log

      ImportResult.new(
        exchange_rates_imported_count: exchange_rates_imported_count,
        exchange_rates_rejected_count: exchange_rates_rejected_count,
        employees_imported_count: employees_imported_count,
        employees_rejected_count: employees_rejected_count
      )
    end

    private

    def import_exchange_rates
      timestamp = Time.current

      process_rows(ExchangeRate, @exchange_rates_path) do |row|
        build_exchange_rate_row(row, timestamp)
      end
    end

    def process_rows(model, path)
      imported = 0
      rejected = 0
      buffer = []

      CSV.foreach(path, headers: true) do |row|
        accumulate_row(model, buffer, yield(row)) ? imported += 1 : rejected += 1
      end

      flush_buffer(model, buffer)
      [ imported, rejected ]
    end

    def accumulate_row(model, buffer, valid_row)
      return false unless valid_row

      buffer << valid_row
      flush_buffer(model, buffer) if buffer.size == @batch_size
      true
    end

    def flush_buffer(model, buffer)
      insert_in_batches(model, buffer)
      buffer.clear
    end

    def build_exchange_rate_row(row, timestamp)
      exchange_rate = ExchangeRate.new(currency: row["currency"], rate: row["rate"], last_synced_at: row["last_synced_at"])

      unless exchange_rate.valid?
        record_error("exchange_rate", row.to_h, exchange_rate.errors.full_messages.to_sentence)
        return nil
      end

      { currency: exchange_rate.currency, rate: exchange_rate.rate, last_synced_at: exchange_rate.last_synced_at,
        created_at: timestamp, updated_at: timestamp }
    end

    def import_employees
      exchange_rates_by_currency = ExchangeRate.all.index_by(&:currency)
      seen_employee_codes = existing_employee_codes
      timestamp = Time.current

      process_rows(Employee, @employees_path) do |row|
        build_employee_row(row, exchange_rates_by_currency, seen_employee_codes, timestamp)
      end
    end

    def existing_employee_codes
      Employee.pluck(:employee_code).map(&:downcase).to_set
    end

    def build_employee_row(row, exchange_rates_by_currency, seen_employee_codes, timestamp)
      exchange_rate = exchange_rates_by_currency[row["currency"]]
      employee = build_employee(row, exchange_rate)
      code_key = row["employee_code"].to_s.downcase

      return nil unless valid_employee_row?(row, employee, seen_employee_codes, code_key)

      seen_employee_codes << code_key
      employee_row_attributes(employee, exchange_rate, timestamp)
    end

    def build_employee(row, exchange_rate)
      Employee.new(employee_code: row["employee_code"], full_name: row["full_name"],
                   job_title: row["job_title"], department: row["department"],
                   country: row["country"], local_salary: row["local_salary"],
                   exchange_rate: exchange_rate)
    end

    def valid_employee_row?(row, employee, seen_employee_codes, code_key)
      duplicate = seen_employee_codes.include?(code_key)
      return true if !duplicate && validate_employee_without_uniqueness(employee)

      message = duplicate ? "Employee code has already been taken" : employee.errors.full_messages.to_sentence
      record_error("employee", row.to_h, message)
      false
    end

    def validate_employee_without_uniqueness(employee)
      Employee.validators.each do |validator|
        validator.validate(employee) unless validator.is_a?(ActiveRecord::Validations::UniquenessValidator)
      end

      employee.errors.empty?
    end

    def employee_row_attributes(employee, exchange_rate, timestamp)
      normalized_usd_salary = SalaryNormalizer.new(employee.local_salary, exchange_rate).normalized_usd_salary

      { employee_code: employee.employee_code, full_name: employee.full_name, job_title: employee.job_title,
        department: employee.department, country: employee.country, local_salary: employee.local_salary,
        exchange_rate_id: exchange_rate.id, normalized_usd_salary: normalized_usd_salary,
        created_at: timestamp, updated_at: timestamp }
    end

    def insert_in_batches(model, rows)
      rows.each_slice(@batch_size) { |slice| model.insert_all(slice) }
    end

    def record_error(type, row, message)
      @errors << row.merge("type" => type, "error" => message)
    end

    def write_error_log
      FileUtils.mkdir_p(File.dirname(@error_log_path))

      CSV.open(@error_log_path, "w") do |csv|
        csv << ERROR_CSV_HEADERS
        @errors.each { |error| csv << ERROR_CSV_HEADERS.map { |header| error[header] } }
      end
    end
  end
end
