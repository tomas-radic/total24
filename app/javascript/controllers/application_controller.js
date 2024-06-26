import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "loadTime"
  ]

  connect() {
    this.loadTimeTarget.textContent = Math.floor(Date.now() / 1000)

    window.addEventListener("focus", this.autoreload);

    var timer = null;
    const ar = this.autoreload;

    window.addEventListener('scroll', function() {
      if (timer !== null) {
        clearTimeout(timer);
      }

      timer = setTimeout(() => ar(), 300);
    }, false);
  }

  autoreload() {
    var now = Math.floor(Date.now() / 1000)
    var loadTime = parseInt(document.querySelectorAll('[data-application-target="loadTime"]')[0].textContent)

    if ((now - loadTime) > 3600) { // if > 1 hour
      location.reload()
    }
  }
}
