class Employee
  class NormalizedSalariesRecalculationJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 1000

    def perform(exchange_rate_id)
      exchange_rate = ExchangeRate.find(exchange_rate_id)

      Employee.where(exchange_rate_id: exchange_rate_id).in_batches(of: BATCH_SIZE) do |batch|
        batch.update_all(
          [ "normalized_usd_salary = ROUND(local_salary * ?, 2), updated_at = ?", exchange_rate.rate, Time.current ]
        )
      end

      exchange_rate.update(last_synced_at: Time.current)
    end
  end
end
