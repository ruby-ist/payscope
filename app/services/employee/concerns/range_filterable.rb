class Employee
  module RangeFilterable
    def filter_by_range(relation, column, minimum, maximum)
      return relation unless minimum || maximum

      relation.where(column => minimum..maximum)
    end
  end
end
