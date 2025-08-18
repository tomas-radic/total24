import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [

  ]

  connect() {
    this.element.addEventListener('show.bs.dropdown', function () {
      fetch("/player/notifications/mark_all_as_seen",
          {
            method: "POST",
            headers: {
              Accept: "text/vnd.turbo-stream.html",
              "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
            }
          })
          .then(r => r.text())
          .then(html => Turbo.renderStreamMessage(html))
    })
  }
}
