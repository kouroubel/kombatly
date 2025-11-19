import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss after 3 seconds
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getInstance(this.element)
      if (bsAlert) {
        bsAlert.close()
      }
    }, 3000)
  }
}