import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss after 3 seconds
    setTimeout(() => {
      this.close()
    }, 3000)
  }

  close() {
    const alert = bootstrap.Alert.getOrCreateInstance(this.element)
    alert.close()
  }
}