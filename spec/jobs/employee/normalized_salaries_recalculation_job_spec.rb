require 'rails_helper'

RSpec.describe Employee::NormalizedSalariesRecalculationJob do
  subject(:perform_job) { described_class.perform_now(exchange_rate.id) }

  let(:exchange_rate) { create(:exchange_rate, rate: 2.5) }
  let(:other_exchange_rate) { create(:exchange_rate, rate: 2.0) }

  let!(:matching_employee) { create(:employee, exchange_rate: exchange_rate, local_salary: 333.33) }
  let!(:other_employee) { create(:employee, exchange_rate: other_exchange_rate, local_salary: 1_000) }

  before do
    matching_employee.update_columns(normalized_usd_salary: 0, updated_at: 1.day.ago)
    other_employee.update_columns(normalized_usd_salary: 0, updated_at: 1.day.ago)
  end

  context 'when all employees fit in a single batch' do
    before { perform_job }

    it 'recomputes normalized_usd_salary matching the calculation object' do
      expected = Employee::SalaryNormalizer.new(matching_employee.local_salary, exchange_rate).normalized_usd_salary
      expect(matching_employee.reload.normalized_usd_salary).to eq(expected)
    end

    it 'leaves employees on other exchange rates untouched' do
      expect(other_employee.reload.normalized_usd_salary).to eq(0)
    end

    it 'updates updated_at for the affected employee' do
      expect(matching_employee.reload.updated_at).to be > 1.day.ago
    end

    it 'sets last_synced_at on the exchange rate once recalculation finishes' do
      expect(exchange_rate.reload.last_synced_at).to be_present
    end
  end

  context 'when more employees are on the rate than fit in a single batch' do
    before { stub_const("#{described_class}::BATCH_SIZE", 2) }

    let!(:employees) do
      create_list(:employee, 5, exchange_rate: exchange_rate, local_salary: 1_000).each do |employee|
        employee.update_columns(normalized_usd_salary: 0, updated_at: 1.day.ago)
      end
    end

    it 'recomputes normalized_usd_salary for every employee across batches' do
      perform_job

      expected = Employee::SalaryNormalizer.new(1_000, exchange_rate).normalized_usd_salary
      expect(employees.map { |employee| employee.reload.normalized_usd_salary }).to all(eq(expected))
    end
  end
end
