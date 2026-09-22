class Employee
  class SalaryAggregationService
    def initialize(employees)
      @employees = employees.reorder(nil)
    end

    def aggregate_summary
      sql = SALARY_AGGREGATE_SQL.values.map { |fragment| Arel.sql(fragment) }
      SALARY_AGGREGATE_SQL.keys.map(&:to_sym).zip(@employees.pick(*sql)).to_h
    end
  end
end
