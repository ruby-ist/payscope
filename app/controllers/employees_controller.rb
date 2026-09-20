class EmployeesController < ApplicationController
  before_action :set_employee, only: %i[edit update destroy]

  def index
    @employees = Employee.all
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

  def set_employee
    @employee = Employee.find_by(id: params[:id])
    return if @employee

    redirect_to employees_path, alert: "Employee not found.", status: :see_other
  end

  def employee_params
    params.expect(employee: %i[employee_code full_name job_title department country local_salary exchange_rate_id])
  end
end
