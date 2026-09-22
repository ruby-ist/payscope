require 'rails_helper'

RSpec.describe Employee::SortService do
  subject(:sorted_employees) { described_class.new(params).sort_employees(Employee.all) }

  let(:params) { {} }

  let(:ada) do
    create(:employee,
           employee_code: 'EMP-001', full_name: 'Ada Lovelace', job_title: 'Staff Engineer',
           department: 'Engineering', country: 'United Kingdom',
           exchange_rate: create(:exchange_rate, currency: 'GBP', rate: 1),
           local_salary: 100_000,
           created_at: Time.zone.local(2026, 1, 10), updated_at: Time.zone.local(2026, 3, 5))
  end

  let(:grace) do
    create(:employee,
           employee_code: 'EMP-002', full_name: 'Grace Hopper', job_title: 'Finance Analyst',
           department: 'Finance', country: 'United States',
           exchange_rate: create(:exchange_rate, currency: 'USD', rate: 1),
           local_salary: 150_000,
           created_at: Time.zone.local(2026, 2, 10), updated_at: Time.zone.local(2026, 4, 5))
  end

  let(:linus) do
    create(:employee,
           employee_code: 'EMP-003', full_name: 'Linus Pauling', job_title: 'Operations Lead',
           department: 'Operations', country: 'India',
           exchange_rate: create(:exchange_rate, currency: 'INR', rate: 1),
           local_salary: 50_000,
           created_at: Time.zone.local(2026, 3, 10), updated_at: Time.zone.local(2026, 5, 5))
  end

  before { [ ada, grace, linus ] }

  context 'when no sort is requested' do
    it 'orders by employee code ascending' do
      expect(sorted_employees).to eq([ ada, grace, linus ])
    end
  end

  describe 'by a plain column' do
    context 'when ascending' do
      let(:params) { { sort_by: 'employee_code', sort_dir: 'asc' } }

      it 'orders the employees from lowest to highest' do
        expect(sorted_employees).to eq([ ada, grace, linus ])
      end
    end

    context 'when descending' do
      let(:params) { { sort_by: 'employee_code', sort_dir: 'desc' } }

      it 'orders the employees from highest to lowest' do
        expect(sorted_employees).to eq([ linus, grace, ada ])
      end
    end
  end

  describe 'by currency' do
    context 'when ascending' do
      let(:params) { { sort_by: 'currency', sort_dir: 'asc' } }

      it 'orders the employees from lowest to highest' do
        expect(sorted_employees).to eq([ ada, linus, grace ])
      end
    end

    context 'when descending' do
      let(:params) { { sort_by: 'currency', sort_dir: 'desc' } }

      it 'orders the employees from highest to lowest' do
        expect(sorted_employees).to eq([ grace, linus, ada ])
      end
    end
  end

  context 'when the sort column is not sortable' do
    let(:params) { { sort_by: 'local_salary', sort_dir: 'desc' } }

    it 'falls back to the default column, keeping the requested direction' do
      expect(sorted_employees).to eq([ linus, grace, ada ])
    end
  end

  context 'when the sort column is an injection attempt' do
    let(:params) { { sort_by: 'employees.id; DROP TABLE employees', sort_dir: 'asc' } }

    it 'falls back to the default order rather than building that SQL' do
      expect(sorted_employees).to eq([ ada, grace, linus ])
    end
  end

  context 'when the sort direction is unknown' do
    let(:params) { { sort_by: 'country', sort_dir: 'sideways' } }

    it 'keeps the requested column and falls back to ascending' do
      expect(sorted_employees).to eq([ linus, ada, grace ])
    end
  end

  context 'when applied on top of a filtered relation' do
    subject(:sorted_employees) do
      described_class.new(params).sort_employees(Employee::FilterService.new(params).filter_employees)
    end

    let(:params) { { country: 'united', sort_by: 'full_name', sort_dir: 'desc' } }

    it 'orders only the filtered employees' do
      expect(sorted_employees).to eq([ grace, ada ])
    end
  end

  context 'when sorting by currency on a relation already joined to exchange rates' do
    subject(:sorted_employees) { described_class.new(params).sort_employees(Employee.joins(:exchange_rate)) }

    let(:params) { { sort_by: 'currency', sort_dir: 'asc' } }

    it 'joins the exchange rates table exactly once' do
      expect(sorted_employees.to_sql.scan('INNER JOIN "exchange_rates"').size).to eq(1)
    end
  end
end
