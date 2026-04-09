import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userSelect", "label"]
  static values = { users: Array }

  connect() {
    this.syncLabel()
  }

  syncLabel() {
    if (!this.hasUserSelectTarget || !this.hasLabelTarget) return
    const id = this.userSelectTarget.value
    const row = this.usersValue.find((u) => String(u.id) === String(id))
    if (!row) return
    const full = [row.first_name, row.last_name].filter(Boolean).join(" ").trim()
    if (full) this.labelTarget.value = full
  }
}
