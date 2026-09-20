class ExchangeRate < ApplicationRecord
  validates :currency, presence: true, uniqueness: { case_sensitive: false },
                        format: { with: /\A[A-Z]{3}\z/ }
  validates :rate, presence: true, numericality: { greater_than: 0 }
end
