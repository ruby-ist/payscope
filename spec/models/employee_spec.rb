require 'rails_helper'

RSpec.describe Employee do
  let(:employee) { build(:employee) }

  describe 'presence validations' do
    context 'when employee_code is blank' do
      let(:employee) { build(:employee, employee_code: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end

    context 'when full_name is blank' do
      let(:employee) { build(:employee, full_name: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end

    context 'when job_title is blank' do
      let(:employee) { build(:employee, job_title: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end

    context 'when department is blank' do
      let(:employee) { build(:employee, department: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end

    context 'when country is blank' do
      let(:employee) { build(:employee, country: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end

    context 'when local_salary is blank' do
      let(:employee) { build(:employee, local_salary: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end
  end

  describe 'employee_code uniqueness' do
    context 'when it duplicates an existing employee_code' do
      before { create(:employee, employee_code: 'EMP100') }

      let(:employee) { build(:employee, employee_code: 'EMP100') }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end
  end

  describe 'local_salary numericality' do
    context 'when not positive' do
      let(:employee) { build(:employee, local_salary: 0) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end
  end

  describe 'exchange_rate association' do
    context 'when missing' do
      let(:employee) { build(:employee, exchange_rate: nil) }

      it 'is invalid' do
        expect(employee).not_to be_valid
      end
    end
  end

  context 'when normalized_usd_salary is blank' do
    let(:employee) { build(:employee, normalized_usd_salary: nil) }

    it 'is valid' do
      expect(employee).to be_valid
    end
  end

  describe '#currency' do
    let(:exchange_rate) { create(:exchange_rate, currency: 'EUR') }
    let(:employee) { build(:employee, exchange_rate: exchange_rate) }

    it 'delegates to the exchange_rate currency' do
      expect(employee.currency).to eq('EUR')
    end
  end

  describe 'normalized_usd_salary calculation' do
    let(:exchange_rate) { create(:exchange_rate, rate: 1.5) }

    context 'when creating an employee' do
      let(:employee) { create(:employee, local_salary: 1_000, exchange_rate: exchange_rate) }

      it 'computes normalized_usd_salary from the local salary and exchange rate' do
        expect(employee.normalized_usd_salary).to eq(1_500.00)
      end
    end

    context 'when local_salary changes' do
      let(:employee) { create(:employee, local_salary: 1_000, exchange_rate: exchange_rate) }

      it 'recomputes normalized_usd_salary' do
        employee.update(local_salary: 2_000)

        expect(employee.normalized_usd_salary).to eq(3_000.00)
      end
    end

    context 'when exchange_rate_id changes' do
      let(:new_exchange_rate) { create(:exchange_rate, rate: 2) }
      let(:employee) { create(:employee, local_salary: 1_000, exchange_rate: exchange_rate) }

      it 'recomputes normalized_usd_salary using the new rate' do
        employee.update(exchange_rate: new_exchange_rate)

        expect(employee.normalized_usd_salary).to eq(2_000.00)
      end
    end

    context 'when an unrelated field changes' do
      let(:employee) { create(:employee, local_salary: 1_000, exchange_rate: exchange_rate) }

      before do
        employee
        allow(Employee::SalaryNormalizer).to receive(:new).and_call_original
      end

      it 'does not recompute normalized_usd_salary' do
        employee.update(full_name: 'New Name')

        expect(Employee::SalaryNormalizer).not_to have_received(:new)
      end
    end
  end
end
