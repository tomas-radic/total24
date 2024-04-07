import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "anonymizeEmail"
  ]

  confirmAnonymize(event) {
    var enableSubmit = (event.target.value === event.target.dataset["confirmationEmail"])
    event.target.parentElement.querySelector("input[type=submit]").disabled = !enableSubmit
  }
}
