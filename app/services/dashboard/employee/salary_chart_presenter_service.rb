module Dashboard
  module Employee
    class SalaryChartPresenterService
      DISPLAY_PRECISION = 2
      BAR_COLOR = "#FF6F59".freeze
      PIE_TITLES = {
        "sum" => "Sum salary (USD)",
        "count" => "Count"
      }.freeze

      def initialize(breakdown, aggregation, group_by, chart_type)
        @breakdown = breakdown
        @aggregation = aggregation.to_s
        @group_by = group_by.to_s
        @chart_type = chart_type
      end

      def create_chart_config
        @chart_type == :pie ? pie_config : bar_config
      end

      private

      def pie_config
        {
          title: { text: PIE_TITLES.fetch(@aggregation, @aggregation.capitalize), left: "center", top: 10 },
          tooltip: { trigger: "item" },
          legend: { bottom: 10 },
          series: [ { name: @aggregation.capitalize, type: "pie", radius: "60%", center: [ "50%", "45%" ],
                      label: { show: true, formatter: "{b}: {c} ({d}%)" },
                      data: @breakdown.map { |label, value| { name: label, value: rounded(value) } } } ]
        }
      end

      def bar_config
        {
          tooltip: { trigger: "axis" },
          grid: { top: 80, right: 90, bottom: 80, left: 90, containLabel: true },
          xAxis: { type: "category", name: @group_by.humanize, nameLocation: "middle", nameGap: 75,
                   data: @breakdown.keys, axisLabel: { interval: 0, rotate: 30 } },
          yAxis: { type: "value", name: "#{@aggregation.capitalize} salary (USD)",
                   nameLocation: "middle", nameGap: 70, nameRotate: 90 },
          series: [ { name: @aggregation.capitalize, type: "bar", label: { show: true, position: "top" },
                      itemStyle: { color: BAR_COLOR },
                      data: @breakdown.values.map { |value| rounded(value) } } ]
        }
      end

      def rounded(value)
        value.to_f.round(DISPLAY_PRECISION)
      end
    end
  end
end
