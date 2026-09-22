require 'rails_helper'

RSpec.describe EmployeesHelper do
  describe '#filters_applied?' do
    subject(:filters_applied) { helper.filters_applied? }

    before { allow(helper).to receive(:params).and_return(params) }

    context 'when no params are present' do
      let(:params) { {} }

      it 'returns false' do
        expect(filters_applied).to be(false)
      end
    end

    context 'when only an unrelated param is present' do
      let(:params) { { page: '2' } }

      it 'returns false' do
        expect(filters_applied).to be(false)
      end
    end

    context 'when a text filter key has a value' do
      let(:params) { { full_name: 'Ada' } }

      it 'returns true' do
        expect(filters_applied).to be(true)
      end
    end

    context 'when a text filter key is present but blank' do
      let(:params) { { full_name: '' } }

      it 'returns false' do
        expect(filters_applied).to be(false)
      end
    end

    context 'when the exchange rate filter has a value' do
      let(:params) { { exchange_rate_id: '3' } }

      it 'returns true' do
        expect(filters_applied).to be(true)
      end
    end

    context 'when a range filter has a present bound' do
      let(:params) { { normalized_usd_salary: { from: '1000', to: '' } } }

      it 'returns true' do
        expect(filters_applied).to be(true)
      end
    end

    context 'when a range filter is present but every bound is blank' do
      let(:params) { { created_at: { from: '', to: '' } } }

      it 'returns false' do
        expect(filters_applied).to be(false)
      end
    end
  end

  describe '#page_showing' do
    subject(:page_showing) { helper.page_showing(pagy) }

    context 'when the page is fully filled' do
      let(:pagy) { Pagy::Offset.new(count: 30, page: 1, limit: 25) }

      it 'reports the range shown' do
        expect(page_showing).to eq('(showing 1–25)')
      end
    end

    context 'when the page is the last, partially filled page' do
      let(:pagy) { Pagy::Offset.new(count: 30, page: 2, limit: 25) }

      it 'reports the remaining range' do
        expect(page_showing).to eq('(showing 26–30)')
      end
    end

    context 'when there are no records at all' do
      let(:pagy) { Pagy::Offset.new(count: 0, page: 1, limit: 25) }

      it 'returns nil' do
        expect(page_showing).to be_nil
      end
    end

    context 'when the requested page is beyond the last page' do
      let(:pagy) { Pagy::Offset.new(count: 5, page: 999, limit: 25) }

      it 'returns nil' do
        expect(page_showing).to be_nil
      end
    end
  end
end
