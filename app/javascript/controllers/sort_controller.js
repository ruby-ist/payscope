import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["column", "direction", "toggle", "ascIcon", "descIcon"]
  static values = { ascendingLabel: String, descendingLabel: String }

  submit() {
    this.columnTarget.form.requestSubmit()
  }

  toggle() {
    const ascending = this.directionTarget.value !== "asc"

    this.directionTarget.value = ascending ? "asc" : "desc"
    this.ascIconTarget.classList.toggle("hidden", !ascending)
    this.descIconTarget.classList.toggle("hidden", ascending)

    const label = ascending ? this.ascendingLabelValue : this.descendingLabelValue
    this.toggleTarget.title = label
    this.toggleTarget.setAttribute("aria-label", label)

    this.submit()
  }
}
