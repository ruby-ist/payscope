module EmployeesHelper
  FILTER_KEYS = %i[full_name employee_code department country job_title exchange_rate_id].freeze
  RANGE_FILTER_KEYS = %i[normalized_usd_salary created_at updated_at].freeze

  def filters_applied?
    FILTER_KEYS.any? { |key| params[key].present? } ||
      RANGE_FILTER_KEYS.any? { |column| params[column]&.values&.any?(&:present?) }
  end

  def employee_sort = @employee_sort ||= Employee::SortService.new(params)

  def sort_by_options
    labels = {
      "employee_code" => "Employee code",
      "full_name" => "Name",
      "job_title" => "Job title",
      "department" => "Department",
      "country" => "Country",
      "currency" => "Currency",
      "normalized_usd_salary" => "Salary (USD)",
      "created_at" => "Created",
      "updated_at" => "Updated"
    }

    Employee::SortService::COLUMNS.map { |column| [ labels.fetch(column), column ] }
  end

  def sort_column = employee_sort.column

  def sort_direction = employee_sort.direction

  def page_showing(pagy)
    return if pagy.from.zero?

    "(showing #{number_with_delimiter(pagy.from)}–#{number_with_delimiter(pagy.to)})"
  end

  def salary_div_title(employee)
    return "Not yet normalized" if employee.normalized_usd_salary.nil?

    "#{number_with_precision(employee.normalized_usd_salary, precision: 2, delimiter: ',')} USD"
  end
end
