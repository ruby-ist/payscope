require 'rails_helper'

RSpec.describe Dashboard::Employee::SalaryReportService do
  subject(:aggregate_salaries) { described_class.new(**query_params).aggregate_salaries }

  let(:query_params) { { group_by: 'department', aggregation: 'sum' } }
  let(:exchange_rate) { create(:exchange_rate, rate: 1) }

  describe 'grouping and aggregating' do
    before do
      create(:employee, department: 'Engineering', job_title: 'Engineer', country: 'USA',
                         exchange_rate: exchange_rate, local_salary: 50_000)
      create(:employee, department: 'Engineering', job_title: 'Manager', country: 'India',
                         exchange_rate: exchange_rate, local_salary: 100_000)
      create(:employee, department: 'Finance', job_title: 'Engineer', country: 'USA',
                         exchange_rate: exchange_rate, local_salary: 150_000)
    end

    context 'when grouped by department' do
      let(:query_params) { { group_by: 'department', aggregation: 'sum' } }

      it 'sums the normalized salary per department' do
        expect(aggregate_salaries).to eq('Engineering' => 150_000, 'Finance' => 150_000)
      end
    end

    context 'when grouped by job title' do
      let(:query_params) { { group_by: 'job_title', aggregation: 'count' } }

      it 'counts employees per job title' do
        expect(aggregate_salaries).to eq('Engineer' => 2, 'Manager' => 1)
      end
    end

    context 'when grouped by country' do
      let(:query_params) { { group_by: 'country', aggregation: 'max' } }

      it 'reports the highest normalized salary per country' do
        expect(aggregate_salaries).to eq('India' => 100_000, 'USA' => 150_000)
      end
    end

    context 'with the minimum aggregation' do
      let(:query_params) { { group_by: 'department', aggregation: 'min' } }

      it 'reports the lowest normalized salary per group' do
        expect(aggregate_salaries).to eq('Engineering' => 50_000, 'Finance' => 150_000)
      end
    end

    context 'with the average aggregation' do
      let(:query_params) { { group_by: 'department', aggregation: 'avg' } }

      it 'reports the mean normalized salary per group' do
        expect(aggregate_salaries).to eq('Engineering' => 75_000, 'Finance' => 150_000)
      end
    end

    it 'orders groups by their label' do
      expect(aggregate_salaries.keys).to eq(aggregate_salaries.keys.sort)
    end
  end

  describe 'date range filtering' do
    let(:query_params) { { group_by: 'department', aggregation: 'count', from: from, to: to } }
    let(:from) { nil }
    let(:to) { nil }

    before do
      create(:employee, department: 'Engineering', exchange_rate: exchange_rate, created_at: 10.days.ago)
      create(:employee, department: 'Engineering', exchange_rate: exchange_rate, created_at: 5.days.ago)
      create(:employee, department: 'Engineering', exchange_rate: exchange_rate, created_at: Time.current)
    end

    context 'with only a from date' do
      let(:from) { 6.days.ago.to_date.to_s }

      it 'includes records created on or after the boundary' do
        expect(aggregate_salaries['Engineering']).to eq(2)
      end
    end

    context 'with only a to date' do
      let(:to) { 6.days.ago.to_date.to_s }

      it 'includes records created on or before the boundary' do
        expect(aggregate_salaries['Engineering']).to eq(1)
      end
    end

    context 'with both bounds' do
      let(:from) { 6.days.ago.to_date.to_s }
      let(:to) { 4.days.ago.to_date.to_s }

      it 'includes only records inside the range' do
        expect(aggregate_salaries['Engineering']).to eq(1)
      end
    end

    context 'with neither bound' do
      it 'includes every record' do
        expect(aggregate_salaries['Engineering']).to eq(3)
      end
    end

    context 'with an unparseable bound' do
      let(:from) { 'not-a-date' }

      it 'ignores the bound rather than filtering everything out' do
        expect(aggregate_salaries['Engineering']).to eq(3)
      end
    end

    context 'when the bound is exactly on the boundary' do
      let(:from) { 10.days.ago.to_date.to_s }
      let(:to) { 10.days.ago.to_date.to_s }

      it 'includes a record created exactly on the boundary date' do
        expect(aggregate_salaries['Engineering']).to eq(1)
      end
    end
  end

  describe 'invalid parameters' do
    before { create(:employee, department: 'Engineering', exchange_rate: exchange_rate, local_salary: 50_000) }

    context 'with an invalid group-by column' do
      let(:query_params) { { group_by: 'salary; DROP TABLE employees;', aggregation: 'sum' } }

      it 'falls back to the default group-by column' do
        expect(aggregate_salaries).to have_key('Engineering')
      end
    end

    context 'with an invalid aggregation' do
      let(:query_params) { { group_by: 'department', aggregation: 'average_of_all_time' } }

      it 'falls back to the default aggregation' do
        expect(aggregate_salaries['Engineering']).to eq(50_000)
      end
    end

    context 'with no parameters given' do
      let(:query_params) { { group_by: nil, aggregation: nil } }

      it 'does not raise' do
        expect { aggregate_salaries }.not_to raise_error
      end
    end
  end
end
