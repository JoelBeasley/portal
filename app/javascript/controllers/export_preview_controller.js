import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "btcInput", "exportBtcInput"]

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    if (!this.modalTarget.classList.contains("hidden")) {
      document.body.classList.add("overflow-hidden")
      document.addEventListener("keydown", this.handleKeydown)
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  prepareExport(event) {
    if (!this.hasBtcInputTarget || !this.hasExportBtcInputTarget) return

    const btcAmount = this.btcInputTarget.value.trim()
    if (!btcAmount) {
      event.preventDefault()
      this.btcInputTarget.focus()
      this.btcInputTarget.reportValidity?.()
      return
    }

    this.exportBtcInputTarget.value = btcAmount
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.handleKeydown)
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) this.close()
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }
}
