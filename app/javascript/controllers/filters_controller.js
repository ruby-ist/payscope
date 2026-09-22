import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  requestSubmit() {
    this.element.requestSubmit()
  }

  submit(event) {
    const blankFields = [ ...event.target.elements ].filter(
      (field) => field.name && !field.disabled && field.value.trim() === ""
    )

    blankFields.forEach((field) => { field.disabled = true })
    setTimeout(() => blankFields.forEach((field) => { field.disabled = false }), 0)
  }
}
