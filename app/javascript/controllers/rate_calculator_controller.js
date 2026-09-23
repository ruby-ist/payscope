import { Controller } from "@hotwired/stimulus"

// Multiplies the typed amount by the row's rate, entirely client-side —
// this never touches the persisted rate, it's just "1 EUR = X USD" scaled up.
export default class extends Controller {
  static targets = [ "amount", "result" ]
  static values = { rate: Number }

  calculate() {
    const amount = Number(this.amountTarget.value)
    if (!Number.isFinite(amount)) return

    this.resultTarget.textContent = this.format(amount * this.rateValue)
  }

  format(value) {
    const rounded = Number(value.toFixed(6))
    return Number.isInteger(rounded) ? rounded.toFixed(1) : rounded.toString()
  }
}
