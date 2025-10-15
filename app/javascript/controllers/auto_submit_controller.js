import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const form = this.element;
    fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
      }
    });
  }
}
