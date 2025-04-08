import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "reactionsCount"
  ]

  connect() {
    this.initTooltip()
  }

  initTooltip() {
    return new window.bootstrap.Tooltip(this.reactionsCountTarget)
  }
}
