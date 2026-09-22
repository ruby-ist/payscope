module ParamCoercible
  private

  def numeric_bound(value) = BigDecimal(value.to_s, exception: false)

  def day_start(value) = parsed_date(value)&.beginning_of_day

  def day_end(value) = parsed_date(value)&.end_of_day

  def parsed_date(value)
    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end
end
