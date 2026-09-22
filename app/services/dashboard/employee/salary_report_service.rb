module Dashboard
  module Employee
    class SalaryReportService
      include RangeFilterable
      include ParamCoercible
      include Whitelistable

      GROUP_BY_COLUMNS = %w[department job_title country].freeze
      DEFAULT_GROUP_BY = "department"
      DEFAULT_AGGREGATION = "sum"

      attr_reader :group_by, :aggregation

      def initialize(group_by:, aggregation:, from: nil, to: nil)
        @group_by = whitelisted(group_by, GROUP_BY_COLUMNS, DEFAULT_GROUP_BY)
        @aggregation = whitelisted(aggregation, ::Employee::SALARY_AGGREGATE_SQL.keys, DEFAULT_AGGREGATION)
        @from = day_start(from)
        @to = day_end(to)
      end

      def aggregate_salaries
        relation = filter_by_range(::Employee.all, :created_at, @from, @to)

        relation.group(group_by).order(group_by)
                .pluck(group_by, Arel.sql(::Employee::SALARY_AGGREGATE_SQL.fetch(aggregation))).to_h
      end
    end
  end
end
