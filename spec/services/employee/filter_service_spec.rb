require 'rails_helper'

RSpec.describe Employee::FilterService do
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

  let(:records) { [ ada, grace, linus ] }

  before { records }

  describe 'without any filters' do
    subject(:listed_employees) { described_class.new(params).filter_employees }

    let(:params) { {} }

    context 'when the params are empty' do
      it 'returns every employee' do
        expect(listed_employees).to contain_exactly(ada, grace, linus)
      end
    end

    context 'when every filter param is blank' do
      let(:params) do
        { full_name: '', employee_code: '', department: '', country: '', job_title: '', exchange_rate_id: '',
          normalized_usd_salary: { from: '', to: '' }, created_at: { from: '', to: '' },
          updated_at: { from: '', to: '' } }
      end

      it 'returns every employee' do
        expect(listed_employees).to contain_exactly(ada, grace, linus)
      end
    end

    context 'with a scope narrower than every employee' do
      subject(:listed_employees) { described_class.new(params, scope: Employee.where(country: 'India')).filter_employees }

      it 'only returns employees from that scope' do
        expect(listed_employees).to eq([ linus ])
      end
    end
  end

  describe 'name filter' do
    subject(:filtered_value) { described_class.new({ full_name: term }).filter_employees }

    it_behaves_like 'a text filter', :full_name, matching_term: 'Lovelace'
  end

  describe 'employee code filter' do
    subject(:filtered_value) { described_class.new({ employee_code: term }).filter_employees }

    it_behaves_like 'a text filter', :employee_code, matching_term: 'EMP-002'
  end

  describe 'department filter' do
    subject(:filtered_value) { described_class.new({ department: term }).filter_employees }

    it_behaves_like 'a text filter', :department, matching_term: 'fin'
  end

  describe 'country filter' do
    subject(:filtered_value) { described_class.new({ country: term }).filter_employees }

    it_behaves_like 'a text filter', :country, matching_term: 'united'
  end

  describe 'job title filter' do
    subject(:filtered_value) { described_class.new({ job_title: term }).filter_employees }

    it_behaves_like 'a text filter', :job_title, matching_term: 'analyst'
  end

  describe 'exchange rate filter' do
    subject(:listed_employees) { described_class.new(params).filter_employees }

    context 'when it matches the exchange rate id' do
      let(:params) { { exchange_rate_id: linus.exchange_rate_id } }

      it 'returns the employee paid under that exchange rate' do
        expect(listed_employees).to eq([ linus ])
      end
    end

    context 'when it matches no exchange rate id' do
      let(:params) { { exchange_rate_id: -1 } }

      it 'returns no employees' do
        expect(listed_employees).to be_empty
      end
    end
  end

  describe 'salary range filter' do
    subject(:filtered_value) { described_class.new({ normalized_usd_salary: bounds }).filter_employees }

    it_behaves_like 'a range filter', :normalized_usd_salary, invalid_bound: 'a lot'
  end

  describe 'created at range filter' do
    subject(:filtered_value) { described_class.new({ created_at: bounds }).filter_employees }

    it_behaves_like 'a range filter', :created_at, invalid_bound: 'yesterday'
  end

  describe 'updated at range filter' do
    subject(:filtered_value) { described_class.new({ updated_at: bounds }).filter_employees }

    it_behaves_like 'a range filter', :updated_at, invalid_bound: 'yesterday'
  end

  describe 'combining filters' do
    subject(:listed_employees) { described_class.new(params).filter_employees }

    context 'when two filters match the same employee' do
      let(:params) { { full_name: 'grace', department: 'Finance' } }

      it 'returns that employee' do
        expect(listed_employees).to eq([ grace ])
      end
    end

    context 'when two filters match different employees' do
      let(:params) { { full_name: 'grace', department: 'Operations' } }

      it 'narrows by both rather than either' do
        expect(listed_employees).to be_empty
      end
    end

    context 'when a text filter and a range filter are combined' do
      let(:params) { { country: 'united', normalized_usd_salary: { from: '120000' } } }

      it 'returns only the employee matching both' do
        expect(listed_employees).to eq([ grace ])
      end
    end
  end
end
