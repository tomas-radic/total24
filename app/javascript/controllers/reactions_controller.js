import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "reactionsCount"
  ]

  connect() {
    // this.initTooltip()
  }

  initTooltip() {
    // window.bootstrap = require('bootstrap/dist/js/bootstrap.bundle.js')
    return new bootstrap.Tooltip(this.reactionsCountTarget)
    // this.reactionsCountTarget.tooltip()
  }
}
