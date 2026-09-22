class DashboardController < ApplicationController
  CHART_TYPES = {
    "sum" => :pie,
    "count" => :pie,
    "min" => :bar,
    "max" => :bar,
    "avg" => :bar
  }.freeze
  DEFAULT_CHART_TYPE = :bar

  def show
    report = build_report

    @group_by = report.group_by
    @aggregation = report.aggregation
    @from = params.dig(:created_at, :from)
    @to = params.dig(:created_at, :to)
    @chart_config = build_chart_config(report)
  end

  private

  def build_report
    Dashboard::Employee::SalaryReportService.new(
      group_by: params[:group_by],
      aggregation: params[:aggregation],
      from: params.dig(:created_at, :from),
      to: params.dig(:created_at, :to)
    )
  end

  def build_chart_config(report)
    chart_type = CHART_TYPES.fetch(report.aggregation, DEFAULT_CHART_TYPE)
    Dashboard::Employee::SalaryChartPresenterService.new(report.aggregate_salaries, report.aggregation,
                                                          report.group_by, chart_type).create_chart_config
  end
end
