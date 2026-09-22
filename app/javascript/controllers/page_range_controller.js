import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  update({ target }) {
    if (target.id !== "employee_list") return

    const source = target.querySelector("[data-page-range]")
    if (source) this.element.textContent = source.dataset.pageRange
  }
}
