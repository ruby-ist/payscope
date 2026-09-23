require 'rails_helper'

RSpec.describe Dashboard::Employee::SalaryChartPresenterService do
  subject(:chart_config) { described_class.new(breakdown, aggregation, group_by, chart_type).create_chart_config }

  let(:breakdown) { { 'Engineering' => 150_000, 'Finance' => 90_000 } }
  let(:group_by) { 'department' }

  describe 'serializing BigDecimal aggregates, as Postgres SUM/AVG/MIN/MAX return' do
    let(:breakdown) { { 'Engineering' => BigDecimal('150000.5'), 'Finance' => BigDecimal('90000.25') } }
    let(:aggregation) { 'sum' }
    let(:chart_type) { :pie }

    it 'serializes values as JSON numbers rather than quoted strings' do
      expect(chart_config.to_json).to include('"value":150000.5')
    end
  end

  describe 'the chart type it renders' do
    let(:aggregation) { 'min' }

    context 'when the caller passes :pie' do
      let(:chart_type) { :pie }

      it 'renders a pie series regardless of the aggregation' do
        expect(chart_config[:series].first[:type]).to eq('pie')
      end
    end

    context 'when the caller passes :bar' do
      let(:chart_type) { :bar }

      it 'renders a bar series regardless of the aggregation' do
        expect(chart_config[:series].first[:type]).to eq('bar')
      end
    end
  end

  describe 'aggregations that render as a pie chart' do
    let(:chart_type) { :pie }

    %w[sum count].each do |aggregation_name|
      context "with the #{aggregation_name} aggregation" do
        let(:aggregation) { aggregation_name }

        it 'produces a pie series' do
          expect(chart_config[:series].first[:type]).to eq('pie')
        end

        it 'shapes the breakdown into name/value pairs' do
          expect(chart_config[:series].first[:data]).to eq(
            [ { name: 'Engineering', value: 150_000 }, { name: 'Finance', value: 90_000 } ]
          )
        end

        it 'labels each slice with its value and percentage share' do
          expect(chart_config[:series].first[:label]).to eq(show: true, formatter: '{b}: {c} ({d}%)')
        end

        it 'shifts the pie left to leave room for the legend on the right' do
          expect(chart_config[:series].first[:center]).to eq(%w[40% 50%])
        end

        it 'places the legend vertically along the right edge' do
          expect(chart_config[:legend]).to eq(orient: 'vertical', right: 10, top: 'middle')
        end

        it 'titles the chart to describe what the slices represent' do
          expected_title = aggregation_name == 'sum' ? 'Sum salary (USD)' : 'Count'
          expect(chart_config[:title]).to eq(text: expected_title, left: '40%', textAlign: 'center', top: 10)
        end

        it 'centers the title over the pie itself, not the legend-widened chart area' do
          expect(chart_config[:title][:left]).to eq(chart_config[:series].first[:center].first)
        end

        context 'with a long-decimal value' do
          let(:breakdown) { { 'Engineering' => 126_740.680625 } }

          it 'rounds the displayed value to two decimal places' do
            expect(chart_config[:series].first[:data]).to eq([ { name: 'Engineering', value: 126_740.68 } ])
          end
        end
      end
    end
  end

  describe 'aggregations that render as a bar chart' do
    let(:chart_type) { :bar }

    %w[min max avg].each do |aggregation_name|
      context "with the #{aggregation_name} aggregation" do
        let(:aggregation) { aggregation_name }

        it 'produces a bar series' do
          expect(chart_config[:series].first[:type]).to eq('bar')
        end

        it 'uses the breakdown labels as the category axis' do
          expect(chart_config[:xAxis][:data]).to eq(%w[Engineering Finance])
        end

        it 'uses the breakdown values as the series data' do
          expect(chart_config[:series].first[:data]).to eq([ 150_000, 90_000 ])
        end

        it 'shows every category label rather than an auto-thinned subset' do
          expect(chart_config[:xAxis][:axisLabel]).to include(interval: 0)
        end

        it 'labels each bar with its value' do
          expect(chart_config[:series].first[:label]).to eq(show: true, position: 'top')
        end

        it 'colors the bars with the brand primary color' do
          expect(chart_config[:series].first[:itemStyle]).to eq(color: '#FF6F59')
        end

        context 'when grouped by job title' do
          let(:group_by) { 'job_title' }

          it 'names the category axis after the group-by dimension' do
            expect(chart_config[:xAxis][:name]).to eq('Job title')
          end
        end

        it 'names the value axis after the aggregation' do
          expect(chart_config[:yAxis][:name]).to eq("#{aggregation_name.capitalize} salary (USD)")
        end

        it 'positions the category axis name below its labels rather than off to the side' do
          expect(chart_config[:xAxis][:nameLocation]).to eq('middle')
        end

        it 'positions the value axis name centered rather than above the axis' do
          expect(chart_config[:yAxis][:nameLocation]).to eq('middle')
        end

        it 'rotates the value axis name to run alongside the vertical axis' do
          expect(chart_config[:yAxis][:nameRotate]).to eq(90)
        end

        it 'reserves grid space so labels and axis names are not clipped by the canvas edge' do
          expect(chart_config[:grid]).to include(containLabel: true)
        end

        it 'gives the plot area equal left and right margins so it sits centered' do
          expect(chart_config[:grid][:left]).to eq(chart_config[:grid][:right])
        end

        context 'with a long-decimal value' do
          let(:breakdown) { { 'Engineering' => 126_740.680625, 'Finance' => 90_000 } }

          it 'rounds the bar value label to two decimal places' do
            expect(chart_config[:series].first[:data]).to eq([ 126_740.68, 90_000 ])
          end
        end
      end
    end
  end
end
