import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "btcInput", "exportBtcInput", "usdHint"]
  static values = { btcUsdPrice: Number }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.updateUsdHint = this.updateUsdHint.bind(this)
    if (this.hasBtcInputTarget) {
      this.btcInputTarget.addEventListener("input", this.updateUsdHint)
      this.updateUsdHint()
    }
    if (!this.modalTarget.classList.contains("hidden")) {
      document.body.classList.add("overflow-hidden")
      document.addEventListener("keydown", this.handleKeydown)
    }
  }

  disconnect() {
    if (this.hasBtcInputTarget) {
      this.btcInputTarget.removeEventListener("input", this.updateUsdHint)
    }
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

  updateUsdHint() {
    if (!this.hasBtcInputTarget || !this.hasUsdHintTarget || this.btcUsdPriceValue <= 0) return

    const btc = parseFloat(this.btcInputTarget.value)
    if (Number.isNaN(btc) || btc <= 0) {
      this.usdHintTarget.textContent = ""
      return
    }

    const usd = btc * this.btcUsdPriceValue
    this.usdHintTarget.textContent = `${this.formatUsd(usd)} USD`
  }

  formatUsd(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
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
