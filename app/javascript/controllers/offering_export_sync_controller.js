import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["investorBtcInput", "finderBtcInput", "finderExportBtcInput"]
  static values = {
    carriedInterestPercent: { type: Number, default: 0 },
    finderFeePercent: { type: Number, default: 5 }
  }

  connect() {
    this.sync = this.sync.bind(this)
    if (this.hasInvestorBtcInputTarget) {
      this.investorBtcInputTarget.addEventListener("input", this.sync)
      this.sync()
    }
  }

  disconnect() {
    if (this.hasInvestorBtcInputTarget) {
      this.investorBtcInputTarget.removeEventListener("input", this.sync)
    }
  }

  sync() {
    if (!this.hasInvestorBtcInputTarget) return

    const formatted = this.calculateFinderFee(this.investorBtcInputTarget.value)
    if (formatted === null) return

    if (this.hasFinderBtcInputTarget) {
      this.finderBtcInputTarget.value = formatted
      this.finderBtcInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
    if (this.hasFinderExportBtcInputTarget) {
      this.finderExportBtcInputTarget.value = formatted
    }
  }

  calculateFinderFee(rawTotal) {
    const total = parseFloat(rawTotal)
    if (Number.isNaN(total) || total <= 0) return null

    const carriedRate = this.carriedInterestPercentValue / 100
    if (carriedRate <= 0) return null

    const finderRate = this.finderFeePercentValue / 100
    const finderFee = total * carriedRate * finderRate
    return finderFee.toFixed(8)
  }
}
