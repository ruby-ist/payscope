class Employee
  class SalaryAggregationService
    # local_salary is only meaningful to aggregate when every row in scope
    # shares one currency (a specific exchange rate filter) — otherwise the
    # figures being summed/averaged wouldn't be comparable. normalized_usd_salary
    # is the default precisely because it's always comparable across currencies.
    ALLOWED_COLUMNS = %i[normalized_usd_salary local_salary].freeze

    def initialize(employees, column: :normalized_usd_salary)
      raise ArgumentError, "unsupported column: #{column}" unless ALLOWED_COLUMNS.include?(column)

      @employees = employees.reorder(nil)
      @column = column
    end

    def aggregate_summary
      sql = aggregate_sql.values.map { |fragment| Arel.sql(fragment) }
      aggregate_sql.keys.map(&:to_sym).zip(@employees.pick(*sql)).to_h
    end

    private

    def aggregate_sql
      {
        "min" => "MIN(employees.#{@column})",
        "max" => "MAX(employees.#{@column})",
        "avg" => "AVG(employees.#{@column})",
        "sum" => "SUM(employees.#{@column})",
        "count" => "COUNT(*)"
      }
    end
  end
end
