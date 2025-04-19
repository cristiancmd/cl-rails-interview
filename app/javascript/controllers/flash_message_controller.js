import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.fadeAndClose()
    }, 3000)
  }

  close() {
    this.fadeAndClose()
  }

  fadeAndClose() {
    this.element.classList.add("fade-out")
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
