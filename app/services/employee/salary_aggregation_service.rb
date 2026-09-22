class Employee
  class SalaryAggregationService
    SALARY = "employees.normalized_usd_salary".freeze

    AGGREGATES = {
      minimum: "MIN(#{SALARY})",
      maximum: "MAX(#{SALARY})",
      average: "AVG(#{SALARY})",
      count: "COUNT(*)",
      total: "SUM(#{SALARY})"
    }.freeze

    def initialize(employees)
      @employees = employees.reorder(nil)
    end

    def aggregate_summary
      AGGREGATES.keys.zip(@employees.pick(*AGGREGATES.values.map { |sql| Arel.sql(sql) })).to_h
    end
  end
end
