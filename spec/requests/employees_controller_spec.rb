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

      it 'offers a working "New employee" link' do
        expect(response.body).to include(%(href="#{new_employee_path}"))
      end

      it "titles the salary chip with the normalized USD amount" do
        title = ApplicationController.helpers.salary_div_title(employee)
        expect(response.body).to include(%(title="#{title}"))
      end
    end

    context 'when there are no exchange rates yet' do
      before { get employees_path }

      it 'marks the "New employee" button as disabled with an explanatory aria-label' do
        button = Nokogiri::HTML(response.body).at_css('button[aria-label="Create an exchange rate first"]')
        expect(button['aria-disabled']).to eq('true')
      end

      it 'gives the "New employee" button a hover tooltip explaining why' do
        button = Nokogiri::HTML(response.body).at_css('button[aria-label="Create an exchange rate first"]')
        expect(button['title']).to eq('Create an exchange rate first')
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

    context 'when filtering and sorting' do
      let(:ada) do
        create(:employee, employee_code: 'EMP-001', full_name: 'Ada Lovelace', department: 'Engineering',
                          exchange_rate: create(:exchange_rate, currency: 'GBP', rate: 1), local_salary: 100_000)
      end

      let(:grace) do
        create(:employee, employee_code: 'EMP-002', full_name: 'Grace Hopper', department: 'Finance',
                          exchange_rate: create(:exchange_rate, currency: 'USD', rate: 1), local_salary: 150_000)
      end

      let(:linus) do
        create(:employee, employee_code: 'EMP-003', full_name: 'Linus Pauling', department: 'Operations',
                          exchange_rate: create(:exchange_rate, currency: 'INR', rate: 1), local_salary: 50_000)
      end

      before { [ ada, grace, linus ] }

      context 'without any filter' do
        before { get employees_path }

        it 'sums every employee into the aggregate bar' do
          expect(response.body).to include('300,000.00')
        end
      end

      context 'with a filter applied' do
        before { get employees_path(department: 'Finance') }

        it 'renders only the matching employees' do
          expect(rendered_employee_ids).to eq([ grace.id ])
        end

        it 'aggregates the filtered set' do
          expect(response.body).to include('150,000.00')
        end

        it 'leaves the filtered-away salaries out of the aggregates' do
          expect(response.body).not_to include('100,000.00')
        end

        it 'keeps the submitted filter in the form' do
          expect(response.body).to include('value="Finance"')
        end
      end

      context 'with a sort applied' do
        before { get employees_path(sort_by: 'full_name', sort_dir: 'desc') }

        it 'renders the employees in the requested order' do
          expect(rendered_employee_ids).to eq([ linus.id, grace.id, ada.id ])
        end
      end

      context 'with a sort on the currency association' do
        before { get employees_path(sort_by: 'currency', sort_dir: 'asc') }

        it 'orders by the exchange rate currency' do
          expect(rendered_employee_ids).to eq([ ada.id, linus.id, grace.id ])
        end
      end

      context 'with a tampered sort param' do
        before { get employees_path(sort_by: 'employees.id; DROP TABLE employees', sort_dir: 'up') }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'falls back to the default order' do
          expect(rendered_employee_ids).to eq([ ada.id, grace.id, linus.id ])
        end
      end

      context 'with filters on a full page request' do
        let(:sort_direction_input) { response.body[/<input[^>]*id="sort_dir"[^>]*>/] }

        before { get employees_path(department: 'Finance', sort_by: 'full_name', sort_dir: 'desc') }

        it 'renders the filter sidebar' do
          expect(response.body).to include('data-filter-sidebar')
        end

        it 'offers the known currencies in the filter form' do
          expect(response.body).to include(%(<option value="#{grace.exchange_rate_id}">USD</option>))
        end

        it 'marks the requested sort column as selected' do
          expect(response.body).to include('<option selected="selected" value="full_name">')
        end

        it 'carries the requested direction on the toggle' do
          expect(response.body).to include('<input type="hidden" name="sort_dir" id="sort_dir" value="desc"')
        end

        it 'submits the direction with the filter form it sits outside of' do
          expect(sort_direction_input).to include(%(form="employee_filters"))
        end

        it 'shows the arrow for the direction in effect' do
          expect(response.body).to include('<span data-sort-target="descIcon">')
        end

        it 'hides the arrow for the other direction' do
          expect(response.body).to include('<span class="hidden" data-sort-target="ascIcon">')
        end

        it 'labels the toggle with the order in effect' do
          expect(response.body).to include('aria-label="Sorted descending')
        end
      end

      context 'when the results frame is requested' do
        before { get employees_path(department: 'Finance'), headers: { "Turbo-Frame" => "employee_results" } }

        it 'aggregates the filtered set' do
          expect(response.body).to include('150,000.00')
        end
      end

      context 'when only the employee list frame is requested' do
        before do
          get employees_path(department: 'Finance', sort_by: 'full_name', sort_dir: 'desc'),
              headers: { "Turbo-Frame" => "employee_list" }
        end

        it 'still applies the filter' do
          expect(rendered_employee_ids).to eq([ grace.id ])
        end

        it 'does not render the aggregate bar' do
          expect(response.body).not_to include('data-aggregate-bar')
        end
      end
    end

    context 'when paginating a filtered and sorted listing' do
      let(:outsider) { create(:employee, department: 'Finance', exchange_rate: create(:exchange_rate)) }

      let(:pagination_links) do
        nav = response.body[%r{<nav[^>]*aria-label="Pagination".*?</nav>}m].to_s
        nav.scan(/href="([^"]*)"/).flatten.map { |href| CGI.unescapeHTML(href) }
      end

      before do
        # rubocop:disable FactoryBot/ExcessiveCreateList
        create_list(:employee, 30, department: 'Engineering', exchange_rate: create(:exchange_rate))
        # rubocop:enable FactoryBot/ExcessiveCreateList
        outsider
        get employees_path(department: 'Engineering', sort_by: 'employee_code', sort_dir: 'desc')
      end

      it 'reports the page slice under the aggregate count' do
        expect(response.body).to include('(showing 1–25)')
      end

      it 'renders a pagination nav above and below the rows' do
        expect(response.body.scan('aria-label="Pagination"').size).to eq(2)
      end

      it 'hands the page slice to the frame for the count card to pick up' do
        expect(response.body).to include('data-page-range="(showing 1–25)"')
      end

      it 'carries the filter into every page link' do
        expect(pagination_links).to all(include('department=Engineering'))
      end

      it 'carries the sort column into every page link' do
        expect(pagination_links).to all(include('sort_by=employee_code'))
      end

      it 'carries the sort direction into every page link' do
        expect(pagination_links).to all(include('sort_dir=desc'))
      end

      context 'when following a page link' do
        before do
          get employees_path(department: 'Engineering', sort_by: 'employee_code', sort_dir: 'desc', page: 2),
              headers: { "Turbo-Frame" => "employee_list" }
        end

        it 'keeps the filter applied' do
          expect(rendered_employee_ids).not_to include(outsider.id)
        end

        it 'renders only the remainder of the filtered set' do
          expect(rendered_employee_ids.size).to eq(5)
        end

        it 'hands the next page slice to the frame' do
          expect(response.body).to include('data-page-range="(showing 26–30)"')
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

    it 'turns off autocomplete on the employee code field' do
      field = Nokogiri::HTML(response.body).at_css('#employee_employee_code')
      expect(field['autocomplete']).to eq('off')
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

      it 'replaces the whole results frame, not just the row' do
        expect(response.body).to include('action="replace" target="employee_results"')
      end

      it 'no longer renders the deleted employee' do
        expect(response.body).not_to include(employee.employee_code)
      end

      it 'updates the flash with the deletion notice' do
        expect(response.body).to include('Employee deleted.')
      end

      it 'removes the employee' do
        expect(Employee.exists?(employee.id)).to be(false)
      end

      it 'shows the empty state instead of a stale pagination nav' do
        expect(response.body).to include('No employees yet.')
      end
    end

    context 'with turbo_stream format when other employees remain' do
      before do
        create(:employee)
        delete employee_path(employee), as: :turbo_stream
      end

      it 'refreshes the aggregate count to reflect the remaining employees' do
        values = Nokogiri::HTML(response.body).css('.numeric.py-4').map(&:text)
        expect(values.last).to eq('1')
      end
    end

    context 'with an unknown id' do
      before { delete employee_path(id: 0) }

      it 'redirects to the employees index' do
        expect(response).to redirect_to(employees_path)
      end
    end
  end

  describe "the delete button's form action" do
    let!(:employee) { create(:employee) }

    before { get employees_path(sort_by: 'employee_code', sort_dir: 'desc') }

    it 'carries the current sort along, so deleting a row keeps the listing in place' do
      form = Nokogiri::HTML(response.body).at_css("form[action*='/employees/#{employee.id}']")
      expect(form['action']).to include('sort_by=employee_code')
    end
  end
end
