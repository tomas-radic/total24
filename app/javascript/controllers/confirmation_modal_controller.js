import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {
    const modal = document.getElementById("confirmation-modal")
    if (modal) {
      modal.addEventListener("show.bs.modal", event => {
        // Extract info from button's data-* attributes
        const triggerButton = event.relatedTarget
        const title = triggerButton.getAttribute("data-bs-title")
        const message = triggerButton.getAttribute("data-bs-message")
        const actionPath = triggerButton.getAttribute("data-bs-action-path")
        const actionData = triggerButton.getAttribute("data-bs-action-data")

        // If necessary, initiate an Ajax request here
        // and then do the updating in a callback.

        // Create element consts
        const titleEl = modal.querySelector("#confirmation-modal-label")
        const messageEl = modal.querySelector("#confirmation-modal-message")
        const submitEl = modal.querySelector("#confirmation-modal-submit")

        // Update modal's content
        titleEl.textContent = title
        messageEl.textContent = message
        submitEl.href = actionPath

        // Update submit button's data-* attributes
        if (actionData) {
          const dataAttributes = JSON.parse(actionData)
          Object.entries(dataAttributes).forEach(([key, value]) => {
            submitEl.setAttribute(`data-${key.replace(/_/g, '-')}`, value)
          })
        }
      })
    }
  }
}
