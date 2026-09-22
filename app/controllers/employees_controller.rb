class EmployeesController < ApplicationController
  before_action :set_employee, only: %i[edit update destroy]

  def index
    filtered = Employee::FilterService.new(listing_params).filter_employees
    employees = Employee::SortService.new(listing_params).sort_employees(filtered)
    @pagy, @employees = pagy(employees.includes(:exchange_rate))
    load_sidebar_data(employees) unless list_frame_request?
  end

  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      redirect_to employees_path, notice: "Employee created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to employees_path, notice: "Employee updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    notice = "Employee deleted."
    respond_to do |format|
      format.html { redirect_to employees_path, notice: notice }
      format.turbo_stream { flash.now[:notice] = notice }
    end
  end

  private

  def list_frame_request?
    turbo_frame_request_id == "employee_list"
  end

  def load_sidebar_data(employees)
    @salary_summary = Employee::SalaryAggregationService.new(employees).aggregate_summary
    @exchange_rates = ExchangeRate.order(:currency)
    @sidebar_data_loaded = true
  end

  def listing_params
    params.permit(:full_name, :employee_code, :department, :country, :job_title, :exchange_rate_id,
                  :sort_by, :sort_dir,
                  normalized_usd_salary: %i[from to], created_at: %i[from to], updated_at: %i[from to])
  end

  def set_employee
    @employee = Employee.find_by(id: params[:id])
    return if @employee

    redirect_to employees_path, alert: "Employee not found.", status: :see_other
  end

  def employee_params
    params.expect(employee: %i[employee_code full_name job_title department country local_salary exchange_rate_id])
  end
end
