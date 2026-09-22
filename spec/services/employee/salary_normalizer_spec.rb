require 'rails_helper'

RSpec.describe Employee::SalaryNormalizer do
  subject(:normalized_usd_salary) { described_class.new(local_salary, exchange_rate).normalized_usd_salary }

  let(:exchange_rate) { build(:exchange_rate, rate: rate) }

  context 'with a rate above one' do
    let(:local_salary) { 1_000 }
    let(:rate) { 1.1 }

    it 'converts the local salary using the exchange rate' do
      expect(normalized_usd_salary).to eq(1_100.00)
    end
  end

  context 'with a rate below one' do
    let(:local_salary) { 50_000 }
    let(:rate) { 0.012 }

    it 'converts the local salary using the exchange rate' do
      expect(normalized_usd_salary).to eq(600.00)
    end
  end

  context 'when the raw result needs rounding' do
    let(:local_salary) { 333.33 }
    let(:rate) { 1.005 }

    it 'rounds to two decimal places' do
      expect(normalized_usd_salary).to eq(335.00)
    end
  end
end
