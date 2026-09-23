class ExchangeRatesController < ApplicationController
  before_action :set_exchange_rate, only: %i[edit update destroy]

  def index
    load_index
  end

  # Both new and edit re-render the index with one frame switched into its form
  # state, so the page works the same whether Turbo swaps the frame or the
  # browser follows the link as a full navigation.
  def new
    load_index(showing_new_form: true)
    render :index
  end

  def edit
    load_index(editing_exchange_rate: @exchange_rate)
    render :index
  end

  def create
    @exchange_rate = ExchangeRate.new(exchange_rate_params)
    if @exchange_rate.save
      notice = "Exchange rate created."
      respond_to do |format|
        format.html { redirect_to exchange_rates_path, notice: notice }
        format.turbo_stream { flash.now[:notice] = notice }
      end
    else
      respond_to do |format|
        format.html do
          load_index(new_exchange_rate: @exchange_rate, showing_new_form: true)
          render :index, status: :unprocessable_entity
        end
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @exchange_rate.update(exchange_rate_params)
      notice = "Exchange rate updated."
      respond_to do |format|
        format.html { redirect_to exchange_rates_path, notice: notice }
        format.turbo_stream { flash.now[:notice] = notice }
      end
    else
      respond_to do |format|
        format.html do
          load_index(editing_exchange_rate: @exchange_rate)
          render :index, status: :unprocessable_entity
        end
        format.turbo_stream { render :update, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @exchange_rate.destroy
    notice = "Exchange rate deleted."
    respond_to do |format|
      format.html { redirect_to exchange_rates_path, notice: notice }
      format.turbo_stream { flash.now[:notice] = notice }
    end
  rescue ActiveRecord::InvalidForeignKey
    render_delete_blocked
  end

  private

  def render_delete_blocked
    alert = "Can't delete #{@exchange_rate.currency}: employees are still using it."
    respond_to do |format|
      format.html { redirect_to exchange_rates_path, alert: alert, status: :see_other }
      format.turbo_stream do
        flash.now[:alert] = alert
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash"), status: :unprocessable_entity
      end
    end
  end

  def set_exchange_rate
    @exchange_rate = ExchangeRate.find_by(id: params[:id])
    return if @exchange_rate

    redirect_to exchange_rates_path, alert: "Exchange rate not found.", status: :see_other
  end

  def exchange_rate_params
    params.expect(exchange_rate: %i[currency rate])
  end

  def load_index(new_exchange_rate: ExchangeRate.new, editing_exchange_rate: nil, showing_new_form: false)
    @exchange_rates = ExchangeRate.order(:created_at, :id).all
    @new_exchange_rate = new_exchange_rate
    @editing_exchange_rate = editing_exchange_rate
    @showing_new_form = showing_new_form
  end
end
