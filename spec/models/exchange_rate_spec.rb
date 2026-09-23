require 'rails_helper'

RSpec.describe ExchangeRate do
  let(:exchange_rate) { build(:exchange_rate) }

  describe 'currency validations' do
    context 'when blank' do
      let(:exchange_rate) { build(:exchange_rate, currency: nil) }

      it 'is invalid' do
        expect(exchange_rate).not_to be_valid
      end
    end

    context 'when the format is malformed' do
      let(:exchange_rate) { build(:exchange_rate, currency: 'usd1') }

      it 'is invalid' do
        expect(exchange_rate).not_to be_valid
      end
    end

    context 'when it duplicates an existing currency' do
      before { create(:exchange_rate, currency: 'USD') }

      let(:exchange_rate) { build(:exchange_rate, currency: 'USD') }

      it 'is invalid' do
        expect(exchange_rate).not_to be_valid
      end
    end
  end

  describe 'rate validations' do
    context 'when blank' do
      let(:exchange_rate) { build(:exchange_rate, rate: nil) }

      it 'is invalid' do
        expect(exchange_rate).not_to be_valid
      end
    end

    context 'when not positive' do
      let(:exchange_rate) { build(:exchange_rate, rate: 0) }

      it 'is invalid' do
        expect(exchange_rate).not_to be_valid
      end
    end
  end

  describe 'last_synced_at' do
    context 'when creating a new exchange rate' do
      let(:exchange_rate) { create(:exchange_rate) }

      it 'defaults to the current time' do
        expect(exchange_rate.last_synced_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when updating the rate value' do
      let!(:exchange_rate) { create(:exchange_rate, rate: 1.5) }

      it 'does not change last_synced_at itself, leaving that to the recalculation job' do
        expect { exchange_rate.update(rate: 2.0) }.not_to change(exchange_rate, :last_synced_at)
      end
    end
  end

  describe 'recalculation job enqueueing' do
    context 'when creating a new exchange rate' do
      it 'does not enqueue the recalculation job' do
        expect { create(:exchange_rate) }.not_to have_enqueued_job(Employee::NormalizedSalariesRecalculationJob)
      end
    end

    context 'when updating the rate value' do
      let!(:exchange_rate) { create(:exchange_rate, rate: 1.5) }

      it 'enqueues the recalculation job with the exchange rate id' do
        expect { exchange_rate.update(rate: 2.0) }
          .to have_enqueued_job(Employee::NormalizedSalariesRecalculationJob).with(exchange_rate.id)
      end
    end

    context 'when updating the record without changing the rate value' do
      let!(:exchange_rate) { create(:exchange_rate, rate: 1.5, currency: 'USD') }

      it 'does not enqueue the recalculation job' do
        expect { exchange_rate.update(currency: 'EUR') }.not_to have_enqueued_job(Employee::NormalizedSalariesRecalculationJob)
      end
    end
  end
end
