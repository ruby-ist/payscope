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
end
