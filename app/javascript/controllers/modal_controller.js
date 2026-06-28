import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    if (this.openValue) this.show()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  openValueChanged() {
    if (this.openValue) {
      this.show()
    } else {
      this.hide()
    }
  }

  open(event) {
    event?.preventDefault()
    this.openValue = true
  }

  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) this.close()
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }

  show() {
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.handleKeydown)
  }

  hide() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.handleKeydown)
  }
}
