require 'rails_helper'

RSpec.describe ExchangeRatesHelper do
  describe '#formatted_rate' do
    subject(:formatted_rate) { helper.formatted_rate(build(:exchange_rate, rate: rate)) }

    context 'when the rate is a whole number' do
      let(:rate) { 1 }

      it 'keeps a single decimal place' do
        expect(formatted_rate).to eq('1.0')
      end
    end

    context 'when the rate has trailing zeros' do
      let(:rate) { 1.08 }

      it 'trims the trailing zeros' do
        expect(formatted_rate).to eq('1.08')
      end
    end

    context 'when the rate uses every decimal place' do
      let(:rate) { 0.0067 }

      it 'keeps every significant digit' do
        expect(formatted_rate).to eq('0.0067')
      end
    end
  end

  describe '#last_synced_label' do
    subject(:last_synced_label) { helper.last_synced_label(exchange_rate) }

    context 'when the exchange rate has never been synced' do
      let(:exchange_rate) { build(:exchange_rate, last_synced_at: nil) }

      it 'shows a placeholder' do
        expect(last_synced_label).to include('Not synced yet')
      end
    end

    context 'when the exchange rate has been synced' do
      let(:exchange_rate) { build(:exchange_rate, last_synced_at: 2.hours.ago) }

      it 'shows the relative time' do
        expect(last_synced_label).to include('Synced about 2 hours ago')
      end
    end
  end
end
