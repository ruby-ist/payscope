import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"

const MIN_PIE_HEIGHT_PX = 320
const PIE_LEGEND_ITEM_HEIGHT_PX = 26
const PIE_HEIGHT_PADDING_PX = 80

export default class extends Controller {
  static values = { config: Object }

  connect() {
    const option = this.configValue
    const series = option.series?.[0]

    if (series?.type === "pie") this.growForLegend(series)
    if (series?.type === "bar") this.abbreviateBarNumbers(option, series)

    this.chart = echarts.init(this.element)
    this.chart.setOption(option)
  }

  disconnect() {
    this.chart.dispose()
  }

  // A legend that wraps into extra columns is harder to scan than one long
  // list, so the container grows tall enough to fit every item in a single
  // column instead of letting ECharts wrap it. The pie's own "50%" vertical
  // center then follows that taller height for free.
  growForLegend(series) {
    const itemCount = series.data.length
    const height = Math.max(MIN_PIE_HEIGHT_PX, itemCount * PIE_LEGEND_ITEM_HEIGHT_PX + PIE_HEIGHT_PADDING_PX)
    this.element.style.height = `${height}px`
  }

  // Only the on-bar top label and the salary axis ticks are abbreviated —
  // the tooltip keeps showing the exact figure, since that's what someone
  // hovers in to check precisely.
  abbreviateBarNumbers(option, series) {
    series.label = { ...series.label, formatter: ({ value }) => abbreviateNumber(value) }
    option.yAxis = { ...option.yAxis, axisLabel: { ...option.yAxis?.axisLabel, formatter: abbreviateNumber } }
  }
}

function abbreviateNumber(value) {
  const magnitude = Math.abs(value)
  if (magnitude >= 1_000_000) return `${trimTrailingZero(value / 1_000_000)}M`
  if (magnitude >= 1_000) return `${trimTrailingZero(value / 1_000)}K`

  return `${value}`
}

function trimTrailingZero(value) {
  return value.toFixed(1).replace(/\.0$/, "")
}
