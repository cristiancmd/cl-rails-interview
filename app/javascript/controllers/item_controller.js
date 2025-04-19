import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  toggle(event) {
    this.makeRequest(event.target.dataset.url)
  }

  toggleAll(event) {
    this.makeRequest(event.target.dataset.url)
  }
  
  makeRequest(url) {
    fetch(url, {
      method: "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": this.csrfToken()
      }
    })
    .then(response => {
      if (!response.ok) {
        console.error("Error in update:", response.status)
      }
    })
    .catch(error => console.error("Error:", error))
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']").content
  }
}
