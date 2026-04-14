import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    if (!this.hasPanelTarget) return
    this.show(this.panelTargets[0]?.dataset.tabId)
  }

  activate(event) {
    const tabId = event.currentTarget.dataset.tabId
    this.show(tabId)
  }

  show(tabId) {
    if (!tabId) return

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.tabId === tabId
      tab.setAttribute("aria-selected", active ? "true" : "false")
      tab.classList.toggle("bg-white", active)
      tab.classList.toggle("text-blue-700", active)
      tab.classList.toggle("border-blue-200", active)
      tab.classList.toggle("shadow-sm", active)
      tab.classList.toggle("text-gray-600", !active)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.tabId !== tabId)
    })
  }
}
