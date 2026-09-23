class ExchangeRate < ApplicationRecord
  validates :currency, presence: true, uniqueness: { case_sensitive: false },
                        format: { with: /\A[A-Z]{3}\z/ }
  validates :rate, presence: true, numericality: { greater_than: 0 }

  before_create :default_last_synced_at
  after_commit :enqueue_recalculation, on: :update, if: :saved_change_to_rate?

  private

  def default_last_synced_at
    self.last_synced_at ||= Time.current
  end

  def enqueue_recalculation
    Employee::NormalizedSalariesRecalculationJob.perform_later(id)
  end
end
