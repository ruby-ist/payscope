module TextFilterable
  def filter_by_text(relation, column, term)
    term = term.to_s.strip
    return relation if term.empty?

    attribute = relation.klass.arel_table[column]
    relation.where(attribute.matches("%#{ActiveRecord::Base.sanitize_sql_like(term)}%"))
  end
end
