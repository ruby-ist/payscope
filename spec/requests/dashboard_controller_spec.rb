require 'rails_helper'

RSpec.describe DashboardController do
  describe 'GET /dashboard' do
    let(:exchange_rate) { create(:exchange_rate, rate: 1) }

    before do
      create(:employee, department: 'Engineering', job_title: 'Engineer', country: 'USA',
                         exchange_rate: exchange_rate, local_salary: 50_000)
      create(:employee, department: 'Finance', job_title: 'Manager', country: 'India',
                         exchange_rate: exchange_rate, local_salary: 150_000)
    end

    context 'with no params' do
      before { get dashboard_path }

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'defaults to grouping by department, summed, rendered as a pie chart' do
        expect(response.body).to include('&quot;type&quot;:&quot;pie&quot;')
      end

      it 'turns off autocomplete on the controls form, so a refresh cannot restore stale selections' do
        form = Nokogiri::HTML(response.body).at_css('form[action="/dashboard"]')
        expect(form['autocomplete']).to eq('off')
      end
    end

    context 'with a bar-producing aggregation' do
      before { get dashboard_path(group_by: 'country', aggregation: 'max') }

      it 'renders the chart config with the requested group-by labels' do
        expect(response.body).to include('&quot;data&quot;:[&quot;India&quot;,&quot;USA&quot;]')
      end

      it 'renders the chart config as a bar series' do
        expect(response.body).to include('&quot;type&quot;:&quot;bar&quot;')
      end

      it 'keeps the fixed chart height on the canvas div, not the turbo-frame tag' do
        canvas = Nokogiri::HTML(response.body).at_css('#salary_chart [data-controller="chart"]')
        expect(canvas['class']).to include('h-80')
      end

      it "keeps the turbo-frame tag's own class constant regardless of chart type" do
        frame = Nokogiri::HTML(response.body).at_css('#salary_chart')
        expect(frame['class']).to eq('block p-4')
      end
    end

    context 'with a pie-producing aggregation' do
      before { get dashboard_path(group_by: 'job_title', aggregation: 'count') }

      it 'renders the chart config with name/value pairs' do
        expect(response.body).to include('&quot;name&quot;:&quot;Engineer&quot;,&quot;value&quot;:1')
      end

      it 'leaves the canvas div free to grow in JS instead of clamping its height in CSS' do
        canvas = Nokogiri::HTML(response.body).at_css('#salary_chart [data-controller="chart"]')
        expect(canvas['class']).not_to include('h-80')
      end

      it "keeps the turbo-frame tag's own class constant regardless of chart type" do
        frame = Nokogiri::HTML(response.body).at_css('#salary_chart')
        expect(frame['class']).to eq('block p-4')
      end
    end

    context 'with a date range narrowing out every record' do
      before { get dashboard_path(created_at: { from: 1.year.from_now.to_date.to_s }) }

      it 'renders an empty breakdown rather than erroring' do
        expect(response.body).to include('&quot;data&quot;:[]')
      end
    end

    context 'with tampered group-by and aggregation params' do
      before { get dashboard_path(group_by: 'salary; DROP TABLE employees;', aggregation: 'nonsense') }

      it 'falls back to safe defaults instead of erroring' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the chart frame is requested' do
      before do
        get dashboard_path(group_by: 'country', aggregation: 'max'),
            headers: { "Turbo-Frame" => "salary_chart" }
      end

      it 'includes the requested chart inside the frame' do
        expect(response.body).to include('id="salary_chart"')
      end

      it 'reflects the requested params in the chart data' do
        expect(response.body).to include('&quot;type&quot;:&quot;bar&quot;')
      end
    end

    context 'when selecting group by in the controls form' do
      before { get dashboard_path }

      it 'checks the option matching the active group-by' do
        expect(response.body).to match(/name="group_by" id="group_by_department"[^>]*checked/)
      end
    end
  end
end
