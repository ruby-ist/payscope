require 'rails_helper'

RSpec.describe Employee::CsvImportService do
  subject(:import) { service.import }

  let(:error_log_path) { Rails.root.join('tmp/import_errors_spec.csv') }

  let(:service) do
    fixtures_path = Rails.root.join('spec/fixtures/files/seed_data')

    described_class.new(exchange_rates_path: fixtures_path.join('exchange_rates.csv'),
                         employees_path: fixtures_path.join('employees.csv'),
                         error_log_path: error_log_path, batch_size: 2)
  end

  let(:error_rows) { CSV.read(error_log_path, headers: true) }

  after { File.delete(error_log_path) if File.exist?(error_log_path) }

  describe 'importing exchange rates' do
    it 'imports every valid exchange rate row' do
      import
      expect(ExchangeRate.pluck(:currency)).to contain_exactly('USD', 'EUR', 'GBP')
    end

    it 'rejects a row that fails model validation' do
      import
      expect(ExchangeRate.exists?(currency: 'US')).to be(false)
    end

    it 'reports the correct imported/rejected counts' do
      expect(import.exchange_rates_imported_count).to eq(3)
    end

    it 'reports the rejected count' do
      expect(import.exchange_rates_rejected_count).to eq(1)
    end

    it "logs the rejected row's validation error" do
      import
      rejected_row = error_rows.find { |row| row['type'] == 'exchange_rate' }
      expect(rejected_row['error']).to include('Currency')
    end
  end

  describe 'importing employees' do
    it 'imports every valid employee row' do
      import
      expect(Employee.pluck(:employee_code)).to contain_exactly('EMP001', 'EMP002', 'EMP003')
    end

    it 'reports the correct imported count' do
      expect(import.employees_imported_count).to eq(3)
    end

    it 'reports the correct rejected count' do
      expect(import.employees_rejected_count).to eq(5)
    end

    it 'imports an employee referencing a currency defined later in the exchange rate file' do
      import
      expect(Employee.find_by(employee_code: 'EMP003').exchange_rate.currency).to eq('GBP')
    end

    it "computes normalized_usd_salary the same way Employee::SalaryNormalizer would" do
      import
      ada = Employee.find_by(employee_code: 'EMP001')
      expected = Employee::SalaryNormalizer.new(ada.local_salary, ada.exchange_rate).normalized_usd_salary
      expect(ada.normalized_usd_salary).to eq(expected)
    end

    context 'with a blank employee code' do
      it 'is rejected and not persisted' do
        import
        expect(Employee.exists?(full_name: 'Blank Code Employee')).to be(false)
      end
    end

    context 'with a blank name' do
      it 'is rejected and not persisted' do
        import
        expect(Employee.exists?(employee_code: 'EMP005')).to be(false)
      end
    end

    context 'with a duplicate employee code' do
      it 'is rejected, keeping only the first row with that code' do
        import
        expect(Employee.where(employee_code: 'EMP001').count).to eq(1)
      end

      it 'keeps the first-seen row rather than the duplicate' do
        import
        expect(Employee.find_by(employee_code: 'EMP001').full_name).to eq('Ada Lovelace')
      end
    end

    context 'with an unsupported currency' do
      it 'is rejected and not persisted' do
        import
        expect(Employee.exists?(employee_code: 'EMP006')).to be(false)
      end
    end

    context 'with a blank local salary' do
      it 'is rejected and not persisted' do
        import
        expect(Employee.exists?(employee_code: 'EMP007')).to be(false)
      end
    end

    it 'logs a rejected employee row with a meaningful error message' do
      import
      rejected_row = error_rows.find { |row| row['employee_code'] == 'EMP006' }
      expect(rejected_row['error']).to be_present
    end
  end

  describe 'the error log' do
    it 'has no timestamp column' do
      import
      expect(error_rows.headers).not_to include('created_at', 'updated_at', 'timestamp')
    end
  end
end
