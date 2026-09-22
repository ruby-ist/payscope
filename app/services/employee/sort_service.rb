class Employee
  class SortService
    COLUMNS = %w[employee_code full_name job_title department country currency
                 normalized_usd_salary created_at updated_at].freeze

    DIRECTIONS = %w[asc desc].freeze
    DEFAULT_COLUMN = "employee_code"
    DEFAULT_DIRECTION = "asc"
    PARAM_KEYS = %i[sort_by sort_dir].freeze

    attr_reader :column, :direction

    def initialize(params)
      @column = whitelisted(params[:sort_by], COLUMNS, DEFAULT_COLUMN)
      @direction = whitelisted(params[:sort_dir], DIRECTIONS, DEFAULT_DIRECTION)
    end

    def sort_employees(relation)
      attribute = column.to_sym
      relation = with_exchange_rate(relation) if by_currency?

      relation.order(by_currency? ? { exchange_rates: { attribute => direction } } : { attribute => direction })
    end

    private

    def by_currency? = column == "currency"

    def with_exchange_rate(relation)
      relation.joins_values.include?(:exchange_rate) ? relation : relation.joins(:exchange_rate)
    end

    def whitelisted(value, allowed, fallback)
      value = value.to_s
      allowed.include?(value) ? value : fallback
    end
  end
end
