import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"

export default class extends Controller {
  static values = { config: Object }

  connect() {
    this.chart = echarts.init(this.element)
    this.chart.setOption(this.configValue)
  }

  disconnect() {
    this.chart.dispose()
  }
}
