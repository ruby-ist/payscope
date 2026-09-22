class Employee < ApplicationRecord
  belongs_to :exchange_rate
  delegate :currency, to: :exchange_rate

  validates :employee_code, presence: true, uniqueness: { case_sensitive: false }
  validates :full_name, presence: true
  validates :job_title, presence: true
  validates :department, presence: true
  validates :country, presence: true
  validates :local_salary, presence: true, numericality: { greater_than: 0 }

  before_save :normalize_salary, if: :normalize_salary?

  private

  def normalize_salary?
    local_salary_changed? || exchange_rate_id_changed?
  end

  def normalize_salary
    self.normalized_usd_salary = SalaryNormalizer.new(local_salary, exchange_rate).normalized_usd_salary
  end
end
