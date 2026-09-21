require 'rails_helper'

RSpec.describe EmployeesController do
  describe 'GET /employees' do
    let(:rendered_employee_ids) do
      response.body.scan(/id="employee_(\d+)"/).flatten.map(&:to_i)
    end

    context 'with basic rendering' do
      let!(:employee) { create(:employee) }

      before { get employees_path }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'lists the employee' do
        expect(response.body).to include(employee.employee_code)
      end
    end

    context 'with more records than fit on one page' do
      let(:exchange_rate) { create(:exchange_rate) }
      let(:page_size) { 25 }

      # 30 records: page 1 fills exactly, page 2 proves the offset.
      # rubocop:disable FactoryBot/ExcessiveCreateList
      let!(:employees) { create_list(:employee, 30, exchange_rate: exchange_rate) }
      # rubocop:enable FactoryBot/ExcessiveCreateList

      context 'without a page param' do
        before { get employees_path }

        it 'renders a full page of employees' do
          expect(rendered_employee_ids.size).to eq(page_size)
        end

        it 'renders the first page of records' do
          expect(rendered_employee_ids).to eq(employees.first(page_size).map(&:id))
        end

        it 'renders the pagination nav' do
          expect(response.body).to include('aria-label="Pagination"')
        end
      end

      context 'with different page param than 1' do
        before { get employees_path(page: 2) }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'renders only the remaining records' do
          expect(rendered_employee_ids.size).to eq(employees.size - page_size)
        end

        it 'renders the records offset past the first page' do
          expect(rendered_employee_ids).to eq(employees.drop(page_size).map(&:id))
        end
      end

      context 'with a page beyond the last' do
        before { get employees_path(page: 999) }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'renders no employees' do
          expect(rendered_employee_ids).to be_empty
        end

        it 'explains that the page is empty' do
          expect(response.body).to include('No employees on this page.')
        end

        it 'does not claim there are no employees at all' do
          expect(response.body).not_to include('No employees yet.')
        end
      end
    end

    context 'when handling Turbo Frame requests' do
      let(:exchange_rate) { create(:exchange_rate) }
      # rubocop:disable FactoryBot/ExcessiveCreateList
      let!(:employees) { create_list(:employee, 30, exchange_rate: exchange_rate) }
      # rubocop:enable FactoryBot/ExcessiveCreateList
      let(:page_size) { 25 }

      context 'when the whole page is requested (no frame)' do
        before { get employees_path(page: 2) }

        it 'renders the aggregate bar' do
          expect(response.body).to include('data-aggregate-bar')
        end

        it 'renders the filter sidebar' do
          expect(response.body).to include('data-filter-sidebar')
        end
      end

      context 'when only the employee list frame is requested' do
        before { get employees_path(page: 2), headers: { "Turbo-Frame" => "employee_list" } }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'still renders the requested page of employees' do
          expect(rendered_employee_ids).to eq(employees.drop(page_size).map(&:id))
        end

        it 'does not render the aggregate bar' do
          expect(response.body).not_to include('data-aggregate-bar')
        end

        it 'does not render the filter sidebar' do
          expect(response.body).not_to include('data-filter-sidebar')
        end
      end

      context 'when a different frame is requested' do
        before { get employees_path, headers: { "Turbo-Frame" => "some_other_frame" } }

        it 'still renders the aggregate bar' do
          expect(response.body).to include('data-aggregate-bar')
        end
      end
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
