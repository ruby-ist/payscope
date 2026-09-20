require 'rails_helper'

RSpec.describe ExchangeRatesController do
  describe 'GET /exchange_rates' do
    let!(:exchange_rate) { create(:exchange_rate) }

    before { get exchange_rates_path }

    it 'returns http success' do
      expect(response).to have_http_status(:ok)
    end

    it 'lists the exchange rate' do
      expect(response.body).to include(exchange_rate.currency)
    end
  end

  describe 'POST /exchange_rates' do
    context 'with valid params and html format' do
      let(:params) { { exchange_rate: attributes_for(:exchange_rate) } }

      before { post exchange_rates_path, params: params }

      it 'redirects to the exchange rates index' do
        expect(response).to redirect_to(exchange_rates_path)
      end

      it 'persists the exchange rate' do
        expect(ExchangeRate.count).to eq(1)
      end
    end

    context 'with valid params and turbo_stream format' do
      let(:params) { { exchange_rate: attributes_for(:exchange_rate) } }

      before { post exchange_rates_path, params: params, as: :turbo_stream }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'includes a turbo-stream append action for the new rate' do
        expect(response.body).to include('action="append"')
      end

      it 'persists the exchange rate' do
        expect(ExchangeRate.count).to eq(1)
      end
    end

    context 'with invalid params and html format' do
      let(:params) { { exchange_rate: attributes_for(:exchange_rate, currency: nil) } }

      before { post exchange_rates_path, params: params }

      it 'returns http unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not persist the exchange rate' do
        expect(ExchangeRate.count).to eq(0)
      end

      it 'renders the validation error in the new rate form' do
        expect(response.body).to include("Currency can&#39;t be blank")
      end
    end

    context 'with invalid params and turbo_stream format' do
      let(:params) { { exchange_rate: attributes_for(:exchange_rate, currency: nil) } }

      before { post exchange_rates_path, params: params, as: :turbo_stream }

      it 'returns http unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'includes error text in the body' do
        expect(response.body).to include("can&#39;t be blank")
      end
    end
  end

  describe 'PATCH /exchange_rates/:id' do
    let!(:exchange_rate) { create(:exchange_rate) }

    context 'with valid params and html format' do
      before { patch exchange_rate_path(exchange_rate), params: { exchange_rate: { rate: 2.5 } } }

      it 'redirects to the exchange rates index' do
        expect(response).to redirect_to(exchange_rates_path)
      end

      it 'updates the exchange rate' do
        expect(exchange_rate.reload.rate).to eq(2.5)
      end
    end

    context 'with valid params and turbo_stream format' do
      before { patch exchange_rate_path(exchange_rate), params: { exchange_rate: { rate: 2.5 } }, as: :turbo_stream }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'includes a turbo-stream replace action for the rate row' do
        expect(response.body).to include(%(action="replace" target="#{ActionView::RecordIdentifier.dom_id(exchange_rate)}"))
      end

      it 'updates the exchange rate' do
        expect(exchange_rate.reload.rate).to eq(2.5)
      end
    end

    context 'with invalid params and html format' do
      before { patch exchange_rate_path(exchange_rate), params: { exchange_rate: { rate: 0 } } }

      it 'returns http unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not update the exchange rate' do
        expect(exchange_rate.reload.rate).not_to eq(0)
      end

      it 'renders the validation error' do
        expect(response.body).to include('Rate must be greater than 0')
      end

      it 're-renders the row in its edit state' do
        expect(response.body).to include(%(value="#{exchange_rate.currency}"))
      end
    end

    context 'with invalid params and turbo_stream format' do
      before { patch exchange_rate_path(exchange_rate), params: { exchange_rate: { rate: 0 } }, as: :turbo_stream }

      it 'returns http unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'includes a turbo-stream replace action for the rate row' do
        expect(response.body).to include(%(action="replace" target="#{ActionView::RecordIdentifier.dom_id(exchange_rate)}"))
      end
    end

    context 'with an unknown id' do
      before { patch exchange_rate_path(id: 0), params: { exchange_rate: { rate: 2.5 } } }

      it 'redirects to the exchange rates index' do
        expect(response).to redirect_to(exchange_rates_path)
      end
    end
  end

  describe 'GET /exchange_rates/:id/edit' do
    context 'with an existing exchange rate' do
      let!(:exchange_rate) { create(:exchange_rate) }
      let!(:other_exchange_rate) { create(:exchange_rate) }

      before { get edit_exchange_rate_path(exchange_rate) }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'renders the edited row inside its own turbo frame' do
        expect(response.body).to include(%(<turbo-frame id="#{ActionView::RecordIdentifier.dom_id(exchange_rate)}">))
      end

      it 'renders the edited row as a prefilled form' do
        expect(response.body).to include(%(value="#{exchange_rate.currency}"))
      end

      it 'leaves the other rows in their display state' do
        expect(response.body).not_to include(%(value="#{other_exchange_rate.currency}"))
      end
    end

    context 'with an unknown id' do
      before { get edit_exchange_rate_path(id: 0) }

      it 'redirects to the exchange rates index' do
        expect(response).to redirect_to(exchange_rates_path)
      end

      it 'sets a not found alert' do
        expect(flash[:alert]).to eq('Exchange rate not found.')
      end
    end
  end

  describe 'DELETE /exchange_rates/:id' do
    let!(:exchange_rate) { create(:exchange_rate) }

    context 'with html format' do
      before { delete exchange_rate_path(exchange_rate) }

      it 'redirects to the exchange rates index' do
        expect(response).to redirect_to(exchange_rates_path)
      end

      it 'removes the exchange rate' do
        expect(ExchangeRate.exists?(exchange_rate.id)).to be(false)
      end
    end

    context 'with turbo_stream format' do
      before { delete exchange_rate_path(exchange_rate), as: :turbo_stream }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'includes a turbo-stream remove action targeting the rate row' do
        expect(response.body).to include(%(action="remove" target="#{ActionView::RecordIdentifier.dom_id(exchange_rate)}"))
      end

      it 'updates the flash with the deletion notice' do
        expect(response.body).to include('Exchange rate deleted.')
      end

      it 'removes the exchange rate' do
        expect(ExchangeRate.exists?(exchange_rate.id)).to be(false)
      end
    end

    context 'with an unknown id' do
      before { delete exchange_rate_path(id: 0) }

      it 'redirects to the exchange rates index' do
        expect(response).to redirect_to(exchange_rates_path)
      end
    end
  end
end
