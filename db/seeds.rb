exchange_rates_csv = Rails.root.join("db/seed_data/exchange_rates.csv")
employees_csv = Rails.root.join("db/seed_data/employees.csv")
error_log_path = ENV["ERROR_LOG_PATH"].presence || Employee::CsvImportService::DEFAULT_ERROR_LOG_PATH

unless File.exist?(exchange_rates_csv) && File.exist?(employees_csv)
  abort <<~MESSAGE
    Seed CSVs not found at #{exchange_rates_csv} and #{employees_csv}.
    Run `script/generate_seed_data --exchange-rates N --employees N --invalid-employees N` first to generate them.
  MESSAGE
end

result = Employee::CsvImportService.new(
  exchange_rates_path: exchange_rates_csv,
  employees_path: employees_csv,
  error_log_path: error_log_path
).import

puts "Exchange rates: #{result.exchange_rates_imported_count} imported, #{result.exchange_rates_rejected_count} rejected"
puts "Employees: #{result.employees_imported_count} imported, #{result.employees_rejected_count} rejected"
