require 'rails_helper'

RSpec.describe EmployeesController do
  describe 'GET /employees' do
    let!(:employee) { create(:employee) }

    before { get employees_path }

    it 'returns http success' do
      expect(response).to have_http_status(:ok)
    end

    it 'lists the employee' do
      expect(response.body).to include(employee.employee_code)
    end
  end

  describe 'POST /employees' do
    let(:exchange_rate) { create(:exchange_rate) }

    context 'with valid params' do
      let(:params) { { employee: attributes_for(:employee).merge(exchange_rate_id: exchange_rate.id) } }

      before { post employees_path, params: params }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end

      it 'persists the employee' do
        expect(Employee.count).to eq(1)
      end
    end

    context 'with invalid params' do
      let(:params) { { employee: attributes_for(:employee, employee_code: nil).merge(exchange_rate_id: exchange_rate.id) } }

      before { post employees_path, params: params }

      it 'returns http unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'renders the new employee form' do
        expect(response.body).to include('New Employee')
      end

      it 'does not persist the employee' do
        expect(Employee.count).to eq(0)
      end
    end
  end

  describe 'PATCH /employees/:id' do
    let!(:employee) { create(:employee) }

    context 'with valid params' do
      before { patch employee_path(employee), params: { employee: { full_name: 'New Name' } } }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end

      it 'updates the employee' do
        expect(employee.reload.full_name).to eq('New Name')
      end
    end

    context 'with invalid params' do
      before { patch employee_path(employee), params: { employee: { full_name: nil } } }

      it 'returns http unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'renders the edit employee form' do
        expect(response.body).to include('Edit Employee')
      end

      it 'does not update the employee' do
        expect(employee.reload.full_name).not_to be_nil
      end
    end

    context 'with an unknown id' do
      before { patch employee_path(id: 0), params: { employee: { full_name: 'New Name' } } }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end
    end
  end

  describe 'GET /employees/new' do
    before { get new_employee_path }

    it 'returns http success' do
      expect(response).to have_http_status(:ok)
    end

    it 'renders the new employee form' do
      expect(response.body).to include('New Employee')
    end
  end

  describe 'GET /employees/:id/edit' do
    context 'with an existing employee' do
      let(:employee) { create(:employee) }

      before { get edit_employee_path(employee) }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'renders the edit employee form' do
        expect(response.body).to include('Edit Employee')
      end

      it 'prefills the form with the employee code' do
        expect(response.body).to include(%(value="#{employee.employee_code}"))
      end
    end

    context 'with an unknown id' do
      before { get edit_employee_path(id: 0) }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end

      it 'sets a not found alert' do
        expect(flash[:alert]).to eq('Employee not found.')
      end
    end
  end

  describe 'DELETE /employees/:id' do
    let!(:employee) { create(:employee) }

    context 'with html format' do
      before { delete employee_path(employee) }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end

      it 'removes the employee' do
        expect(Employee.exists?(employee.id)).to be(false)
      end
    end

    context 'with turbo_stream format' do
      before { delete employee_path(employee), as: :turbo_stream }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'includes a turbo-stream remove action targeting the employee row' do
        expect(response.body).to include(%(action="remove" target="#{ActionView::RecordIdentifier.dom_id(employee)}"))
      end

      it 'updates the flash with the deletion notice' do
        expect(response.body).to include('Employee deleted.')
      end

      it 'removes the employee' do
        expect(Employee.exists?(employee.id)).to be(false)
      end
    end

    context 'with an unknown id' do
      before { delete employee_path(id: 0) }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end
    end
  end
end
