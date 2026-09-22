class Employee
  class FilterService
    include TextFilterable
    include RangeFilterable
    include ParamCoercible

    TEXT_FILTERS = %i[full_name employee_code department country job_title].freeze
    RANGE_FILTERS = %i[normalized_usd_salary created_at updated_at].freeze
    DATE_RANGE_COLUMNS = %i[created_at updated_at].freeze

    def initialize(params, scope: Employee.all)
      @params = params.to_h.deep_symbolize_keys
      @relation = scope
    end

    def filter_employees
      filter_by_exchange_rate
      apply_text_filters
      apply_range_filters

      @relation
    end

    private

    def apply_text_filters
      @params.slice(*TEXT_FILTERS).each do |column, term|
        @relation = filter_by_text(@relation, column, term)
      end
    end

    def filter_by_exchange_rate
      return if @params[:exchange_rate_id].blank?

      @relation = @relation.where(exchange_rate_id: @params[:exchange_rate_id])
    end

    def apply_range_filters
      @params.slice(*RANGE_FILTERS).each do |column, range|
        minimum, maximum = range_bounds(column, range.to_h[:from], range.to_h[:to])
        @relation = filter_by_range(@relation, column, minimum, maximum)
      end
    end

    def range_bounds(column, from, to)
      if DATE_RANGE_COLUMNS.include?(column)
        [ day_start(from), day_end(to) ]
      else
        [ numeric_bound(from), numeric_bound(to) ]
      end
    end
  end
end
