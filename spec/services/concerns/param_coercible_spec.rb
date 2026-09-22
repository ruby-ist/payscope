require 'rails_helper'

RSpec.describe ParamCoercible do
  let(:includer) { Class.new { include ParamCoercible }.new }

  describe '#numeric_bound' do
    subject(:numeric_bound) { includer.send(:numeric_bound, value) }

    context 'when the value is a valid number' do
      let(:value) { '42.5' }

      it 'returns the parsed decimal' do
        expect(numeric_bound).to eq(BigDecimal('42.5'))
      end
    end

    context 'when the value is unparseable' do
      let(:value) { 'a lot' }

      it 'returns nil' do
        expect(numeric_bound).to be_nil
      end
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it 'returns nil' do
        expect(numeric_bound).to be_nil
      end
    end
  end

  describe '#day_start' do
    subject(:day_start) { includer.send(:day_start, value) }

    context 'when the value is a valid date' do
      let(:value) { '2026-03-05' }

      it 'returns the beginning of that day' do
        expect(day_start).to eq(Date.new(2026, 3, 5).beginning_of_day)
      end
    end

    context 'when the value is unparseable' do
      let(:value) { 'yesterday' }

      it 'returns nil' do
        expect(day_start).to be_nil
      end
    end

    context 'when the value is blank' do
      let(:value) { '' }

      it 'returns nil' do
        expect(day_start).to be_nil
      end
    end
  end

  describe '#day_end' do
    subject(:day_end) { includer.send(:day_end, value) }

    context 'when the value is a valid date' do
      let(:value) { '2026-03-05' }

      it 'returns the end of that day' do
        expect(day_end).to eq(Date.new(2026, 3, 5).end_of_day)
      end
    end

    context 'when the value is unparseable' do
      let(:value) { 'yesterday' }

      it 'returns nil' do
        expect(day_end).to be_nil
      end
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it 'returns nil' do
        expect(day_end).to be_nil
      end
    end
  end
end
