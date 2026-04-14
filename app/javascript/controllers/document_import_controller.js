import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "mappings", "template", "emptyState", "documentTypeSelect", "customTypeField"]
  static values = { investors: Array, investments: Array }

  connect() {
    this.syncCustomTypeField()
    this.syncAllRows()
  }

  renderMappings() {
    if (!this.hasFileInputTarget || !this.hasMappingsTarget || !this.hasTemplateTarget) return

    const files = Array.from(this.fileInputTarget.files || [])
    this.mappingsTarget.innerHTML = ""

    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.toggle("hidden", files.length > 0)
    }

    files.forEach((file, idx) => {
      const html = this.templateTarget.innerHTML
        .replaceAll("__INDEX__", String(idx))
        .replaceAll("__FILENAME__", this.escapeHtml(file.name))
      this.mappingsTarget.insertAdjacentHTML("beforeend", html)
      const row = this.mappingsTarget.lastElementChild
      this.applyGuessedMapping(row, file.name)
    })

    this.syncAllRows()
  }

  syncInvestments(event) {
    const row = event.currentTarget.closest(".document-mapping-row")
    if (!row) return
    this.syncRow(row)
  }

  removeRow(event) {
    event.preventDefault()
    const row = event.currentTarget.closest(".document-mapping-row")
    if (!row) return

    const rowIndex = Number.parseInt(row.dataset.rowIndex || "", 10)
    const files = this.hasFileInputTarget ? Array.from(this.fileInputTarget.files || []) : []

    if (Number.isInteger(rowIndex) && rowIndex >= 0 && files.length > 0) {
      const dt = new DataTransfer()
      files.forEach((file, idx) => {
        if (idx !== rowIndex) dt.items.add(file)
      })
      this.fileInputTarget.files = dt.files
      this.renderMappings()
      return
    }

    row.remove()
    this.syncAllRows()
    if (this.hasEmptyStateTarget && this.hasMappingsTarget) {
      this.emptyStateTarget.classList.toggle("hidden", this.mappingsTarget.children.length > 0)
    }
  }

  syncCustomTypeField() {
    if (!this.hasDocumentTypeSelectTarget || !this.hasCustomTypeFieldTarget) return
    const selectedType = this.documentTypeSelectTarget.value
    this.customTypeFieldTarget.classList.toggle("hidden", selectedType !== "custom")
  }

  syncAllRows() {
    if (!this.hasMappingsTarget) return
    this.mappingsTarget.querySelectorAll(".document-mapping-row").forEach((row) => this.syncRow(row))
  }

  syncRow(row) {
    const userSelect = row.querySelector("[data-document-import-role='user-select']")
    const investmentSelect = row.querySelector("[data-document-import-role='investment-select']")
    if (!userSelect || !investmentSelect) return

    const selectedUserId = userSelect.value
    const options = Array.from(investmentSelect.options)

    options.forEach((option) => {
      const ownerId = option.dataset.userId
      const isPlaceholder = !option.value
      const visible = isPlaceholder || !selectedUserId || ownerId === selectedUserId
      option.hidden = !visible
      option.disabled = !visible
    })

    const selectedOption = investmentSelect.selectedOptions[0]
    if (selectedOption && selectedOption.hidden) {
      investmentSelect.value = ""
    }

    investmentSelect.disabled = selectedUserId === ""
  }

  applyGuessedMapping(row, filename) {
    if (!row || !filename) return

    const userSelect = row.querySelector("[data-document-import-role='user-select']")
    const investmentSelect = row.querySelector("[data-document-import-role='investment-select']")
    if (!userSelect || !investmentSelect) return

    const guess = this.guessMapping(filename)
    if (!guess) return

    if (guess.userId) {
      userSelect.value = String(guess.userId)
      this.syncRow(row)
    }
    if (guess.investmentId) {
      investmentSelect.value = String(guess.investmentId)
    }
  }

  guessMapping(filename) {
    const filenameTokens = this.tokens(filename)
    if (filenameTokens.size === 0) return null

    const bestInvestment = this.bestInvestmentMatch(filenameTokens)
    if (bestInvestment && bestInvestment.score >= 0.6) {
      return { userId: bestInvestment.userId, investmentId: bestInvestment.id }
    }

    const bestInvestor = this.bestInvestorMatch(filenameTokens)
    if (bestInvestor && bestInvestor.score >= 0.6) {
      return { userId: bestInvestor.id, investmentId: null }
    }

    return null
  }

  bestInvestorMatch(filenameTokens) {
    let best = null
    this.investorsValue.forEach((investor) => {
      const candidateTokens = this.tokens([investor.fullName, investor.email].join(" "))
      const score = this.tokenScore(filenameTokens, candidateTokens)
      if (!best || score > best.score) {
        best = { id: investor.id, score }
      }
    })
    return best
  }

  bestInvestmentMatch(filenameTokens) {
    let best = null
    this.investmentsValue.forEach((investment) => {
      const haystack = [
        investment.listTitle,
        investment.companyOrNickname,
        investment.userFullName,
        investment.offeringName
      ].filter(Boolean).join(" ")
      const candidateTokens = this.tokens(haystack)
      const score = this.tokenScore(filenameTokens, candidateTokens)
      if (!best || score > best.score) {
        best = {
          id: investment.id,
          userId: investment.userId,
          score
        }
      }
    })
    return best
  }

  tokenScore(filenameTokens, candidateTokens) {
    if (filenameTokens.size === 0 || candidateTokens.size === 0) return 0
    let matches = 0
    filenameTokens.forEach((token) => {
      if (candidateTokens.has(token)) matches += 1
    })
    return matches / Math.max(2, Math.min(filenameTokens.size, candidateTokens.size))
  }

  tokens(value) {
    return new Set(
      String(value || "")
        .toLowerCase()
        .replace(/\.[a-z0-9]+$/i, " ")
        .replace(/[^a-z0-9]+/g, " ")
        .split(" ")
        .map((part) => part.trim())
        .filter((part) => part.length >= 2)
    )
  }

  escapeHtml(value) {
    return value
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll("\"", "&quot;")
      .replaceAll("'", "&#039;")
  }
}
