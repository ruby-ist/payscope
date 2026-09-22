module ExchangeRatesHelper
  def formatted_rate(exchange_rate)
    rate = number_with_precision(exchange_rate.rate, precision: 6, strip_insignificant_zeros: true)
    rate == "1" ? "1.0" : rate
  end

  def last_synced_label(exchange_rate)
    return tag.span("Not synced yet", class: "rate-value text-text-muted") if exchange_rate.last_synced_at.nil?

    exact_time = exchange_rate.last_synced_at.to_fs(:long)

    tag.span("Synced #{time_ago_in_words(exchange_rate.last_synced_at)} ago",
             class: "rate-value text-text-muted", title: exact_time, aria: { label: "Last synced #{exact_time}" })
  end
end
