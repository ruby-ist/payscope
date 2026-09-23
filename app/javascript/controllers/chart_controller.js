import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"

const MOBILE_BREAKPOINT_PX = 768 // matches --breakpoint-md, docs/design_notes.md §11
const MIN_PIE_HEIGHT_PX = 320
const MOBILE_PIE_HEIGHT_PX = 360
const PIE_LEGEND_ITEM_HEIGHT_PX = 26
const PIE_HEIGHT_PADDING_PX = 80
const MOBILE_BAR_GRID = { top: 40, right: 70, bottom: 70, left: 70 }

export default class extends Controller {
  static values = { config: Object }

  connect() {
    const option = this.configValue
    const series = option.series?.[0]

    if (series?.type === "pie") this.layoutPie(option, series)
    if (series?.type === "bar") this.layoutBar(option, series)

    this.chart = echarts.init(this.element)
    this.chart.setOption(option)
  }

  disconnect() {
    this.chart.dispose()
  }

  // Desktop: legend to the right, chart grows tall enough to fit every entry
  // in one column (see growForLegend). Mobile has no room to the right, so
  // the legend moves below the pie instead — a "scroll" legend paginates
  // overflow within a fixed height rather than needing the chart to grow.
  layoutPie(option, series) {
    if (window.innerWidth < MOBILE_BREAKPOINT_PX) {
      option.legend = { orient: "horizontal", type: "scroll", bottom: 0, left: "center" }
      series.center = [ "50%", "45%" ]
      this.element.style.height = `${MOBILE_PIE_HEIGHT_PX}px`
    } else {
      this.growForLegend(series)
    }
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

  // Desktop keeps the server-built grid margins as-is. Mobile has much less
  // width to spare, so the margins shrink there instead of reclaiming that
  // space on every screen size.
  layoutBar(option, series) {
    if (window.innerWidth < MOBILE_BREAKPOINT_PX) option.grid = { ...option.grid, ...MOBILE_BAR_GRID }
    this.abbreviateBarNumbers(option, series)
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
