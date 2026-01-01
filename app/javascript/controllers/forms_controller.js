import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lockableField", "locker", "hideToggler", "hideToggleable"
  ]

  connect() {

  }

  toggleLockFields() {
    this.lockableFieldTargets.forEach((e, idx) => {
      e.disabled = !this.lockerTarget.checked
    })
  }

  toggleHidden() {
    var hideToggleable = this.hideTogglerTarget.closest(".hide-toggler-wrapper")
        .querySelector(".hide-toggleable")

    if (this.hideTogglerTarget.checked) {
      hideToggleable.classList.remove("visually-hidden")
    } else {
      hideToggleable.classList.add("visually-hidden")
    }
  }

  clearField(event) {
    const targetId = event.params.targetId || event.currentTarget.dataset.targetId
    const relatedFields = event.params.relatedFields || event.currentTarget.dataset.relatedFields

    if (targetId) {
      document.getElementById(targetId).value = ""
    }

    if (relatedFields) {
      relatedFields.split("|").forEach((id) => {
        const element = document.getElementById(id)
        if (element) {
          element.value = ""
        }
      })
    }
  }
}
