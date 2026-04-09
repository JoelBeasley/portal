import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggle", "hamburgerIcon", "closeIcon"]

  connect() {
    this.onResize = () => {
      if (window.matchMedia("(min-width: 768px)").matches) this.close()
    }
    this.onEscape = (e) => {
      if (e.key === "Escape") this.close()
    }
    window.addEventListener("resize", this.onResize)
    document.addEventListener("keydown", this.onEscape)
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
    document.removeEventListener("keydown", this.onEscape)
  }

  toggle() {
    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "true")
    if (this.hasHamburgerIconTarget && this.hasCloseIconTarget) {
      this.hamburgerIconTarget.classList.add("hidden")
      this.closeIconTarget.classList.remove("hidden")
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    if (this.hasHamburgerIconTarget && this.hasCloseIconTarget) {
      this.hamburgerIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
    }
  }

  navigate() {
    this.close()
  }
}
