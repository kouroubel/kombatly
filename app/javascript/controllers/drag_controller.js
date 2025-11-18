import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slot"]

  connect() {
    console.log("DragController connected!")

    this.slotTargets.forEach(slot => {
      slot.addEventListener("dragstart", this.dragStart.bind(this))
      slot.addEventListener("dragover", this.dragOver.bind(this))
      slot.addEventListener("drop", this.drop.bind(this))
    })
  }

  dragStart(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  async drop(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (!this.dragged || target === this.dragged) return

    // Store original athlete IDs for sending to server
    const sourceAthleteId = this.dragged.dataset.athleteId
    const targetAthleteId = target.dataset.athleteId

    // Swap inner text in the UI
    const tempText = this.dragged.innerText
    this.dragged.innerText = target.innerText
    target.innerText = tempText

    // Swap data-athlete-id in the UI
    this.dragged.dataset.athleteId = targetAthleteId
    target.dataset.athleteId = sourceAthleteId

    // Determine slots (a or b)
    const sourceSlot = this.dragged.classList.contains("slot-a") ? "a" : "b"
    const targetSlot = target.classList.contains("slot-a") ? "a" : "b"

    // Bout IDs
    const sourceBoutId = this.dragged.closest(".match-box").dataset.boutId
    const targetBoutId = target.closest(".match-box").dataset.boutId

    // Send original athlete IDs to server
    const payload = {
      source: { athlete_id: sourceAthleteId, bout_id: sourceBoutId, slot: sourceSlot },
      target: { athlete_id: targetAthleteId, bout_id: targetBoutId, slot: targetSlot }
    }

    try {
      const response = await fetch("/bouts/swap", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) console.error("Failed to swap bouts")
    } catch (error) {
      console.error("Error swapping bouts:", error)
    }
  }
}
