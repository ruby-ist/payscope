require 'rails_helper'

RSpec.describe Employee::SalaryAggregationService do
  subject(:summary) { described_class.new(scope).aggregate_summary }

  let(:scope) { Employee.all }
  let(:exchange_rate) { create(:exchange_rate, rate: 1) }

  describe 'over several employees' do
    before do
      create(:employee, exchange_rate: exchange_rate, local_salary: 50_000)
      create(:employee, exchange_rate: exchange_rate, local_salary: 100_000)
      create(:employee, exchange_rate: exchange_rate, local_salary: 150_000)
    end

    it 'reports the lowest salary' do
      expect(summary[:minimum]).to eq(50_000)
    end

    it 'reports the highest salary' do
      expect(summary[:maximum]).to eq(150_000)
    end

    it 'reports the mean salary' do
      expect(summary[:average]).to eq(100_000)
    end

    it 'reports how many employees it covers' do
      expect(summary[:count]).to eq(3)
    end

    it 'reports the total salary' do
      expect(summary[:total]).to eq(300_000)
    end

    context 'when the scope is narrowed' do
      let(:scope) { Employee.where(normalized_usd_salary: 100_000..) }

      it 'summarises only what the scope holds' do
        expect(summary[:count]).to eq(2)
      end

      it 'averages only what the scope holds' do
        expect(summary[:average]).to eq(125_000)
      end
    end

    context 'when the scope is sorted' do
      let(:scope) { Employee.order(normalized_usd_salary: :desc) }

      it 'computes the same values a sorted scope would' do
        expect(summary).to eq(described_class.new(Employee.all).aggregate_summary)
      end
    end

    context 'when the scope is sorted by a joined column' do
      let(:scope) { Employee.joins(:exchange_rate).order("exchange_rates.currency" => :asc) }

      it 'still summarises without the ordering tripping the aggregate' do
        expect(summary[:count]).to eq(3)
      end
    end
  end

  describe 'over employees with no normalized salary yet' do
    before do
      create(:employee, exchange_rate: exchange_rate, local_salary: 100_000)
      create(:employee, exchange_rate: exchange_rate, local_salary: 100_000).update_column(:normalized_usd_salary, nil)
    end

    it 'counts every employee in the scope' do
      expect(summary[:count]).to eq(2)
    end

    it 'averages only the salaries it has' do
      expect(summary[:average]).to eq(100_000)
    end
  end

  describe 'over an empty scope' do
    it 'reports no employees' do
      expect(summary[:count]).to eq(0)
    end

    it 'reports no total' do
      expect(summary[:total]).to be_nil
    end

    it 'reports no average' do
      expect(summary[:average]).to be_nil
    end
  end
end
