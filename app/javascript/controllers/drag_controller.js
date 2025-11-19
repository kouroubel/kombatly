import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slot"]
  static values = {
    swapUrl: { type: String, default: "/bouts/swap" }
  }

  connect() {
    console.log("DragController connected!")
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    this.slotTargets.forEach(slot => {
      slot.addEventListener("dragstart", this.dragStart.bind(this))
      slot.addEventListener("dragend", this.dragEnd.bind(this))
      slot.addEventListener("dragover", this.dragOver.bind(this))
      slot.addEventListener("dragenter", this.dragEnter.bind(this))
      slot.addEventListener("dragleave", this.dragLeave.bind(this))
      slot.addEventListener("drop", this.drop.bind(this))
    })
  }

  dragStart(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("dragging")
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("dragging")
    this.slotTargets.forEach(slot => {
      slot.classList.remove("drop-target")
    })
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  dragEnter(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (target !== this.dragged) {
      target.classList.add("drop-target")
    }
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("drop-target")
  }

  async drop(event) {
    event.preventDefault()
    const target = event.currentTarget
    target.classList.remove("drop-target")
    
    if (!this.dragged || target === this.dragged) return

    const originalDraggedHTML = this.dragged.innerHTML
    const originalTargetHTML = target.innerHTML
    const originalDraggedAthleteId = this.dragged.dataset.athleteId
    const originalTargetAthleteId = target.dataset.athleteId

    const sourceSlot = this.dragged.classList.contains("slot-a") ? "a" : "b"
    const targetSlot = target.classList.contains("slot-a") ? "a" : "b"
    const sourceBoutId = this.dragged.closest(".match-box").dataset.boutId
    const targetBoutId = target.closest(".match-box").dataset.boutId

    this.swapElements(this.dragged, target)

    const payload = {
      source: { 
        athlete_id: originalDraggedAthleteId, 
        bout_id: sourceBoutId, 
        slot: sourceSlot 
      },
      target: { 
        athlete_id: originalTargetAthleteId, 
        bout_id: targetBoutId, 
        slot: targetSlot 
      }
    }

    try {
      const response = await fetch(this.swapUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || `Server error: ${response.status}`)
      }

      this.showFeedback(target, "success")
      console.log("Athletes swapped successfully")
    } catch (error) {
      console.error("Error swapping athletes:", error)
      
      this.dragged.innerHTML = originalDraggedHTML
      target.innerHTML = originalTargetHTML
      this.dragged.dataset.athleteId = originalDraggedAthleteId
      target.dataset.athleteId = originalTargetAthleteId
      
      this.showFeedback(target, "error")
      alert(`Failed to swap athletes: ${error.message}`)
    }
  }

  swapElements(source, target) {
    const tempHTML = source.innerHTML
    source.innerHTML = target.innerHTML
    target.innerHTML = tempHTML
    
    const tempAthleteId = source.dataset.athleteId
    source.dataset.athleteId = target.dataset.athleteId
    target.dataset.athleteId = tempAthleteId
  }

  showFeedback(element, type) {
    const feedbackClass = type === "success" ? "swap-success" : "swap-error"
    element.classList.add(feedbackClass)
    setTimeout(() => {
      element.classList.remove(feedbackClass)
    }, 600)
  }

  get csrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ""
  }

  disconnect() {
    this.slotTargets.forEach(slot => {
      slot.removeEventListener("dragstart", this.dragStart)
      slot.removeEventListener("dragend", this.dragEnd)
      slot.removeEventListener("dragover", this.dragOver)
      slot.removeEventListener("dragenter", this.dragEnter)
      slot.removeEventListener("dragleave", this.dragLeave)
      slot.removeEventListener("drop", this.drop)
    })
  }
  
  async selectWinner(event) {
    const athleteSlot = event.currentTarget
    const athleteId = athleteSlot.dataset.athleteId
    const boutId = athleteSlot.closest(".match-box").dataset.boutId
    const matchBox = athleteSlot.closest(".match-box")
    
    if (!athleteId || athleteId === "null") {
      alert("Cannot select TBD as winner")
      return
    }
    
    // Check if this bout already has a winner (changing winner)
    const existingWinner = matchBox.querySelector('.winner-slot')
    const isChangingWinner = existingWinner && existingWinner !== athleteSlot
    const oldWinnerId = existingWinner ? existingWinner.dataset.athleteId : null
    
    try {
      const response = await fetch(`/bouts/${boutId}/set_winner`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ 
          winner_id: athleteId,
          previous_winner_id: oldWinnerId
        })
      })
      
      if (!response.ok) {
        const errorText = await response.text()
        console.error("Server response:", errorText)
        throw new Error("Failed to set winner")
      }
      
      const data = await response.json()
      
      // Remove winner highlighting from both slots
      matchBox.querySelectorAll('.athlete-slot').forEach(slot => {
        slot.classList.remove('winner-slot')
      })
      
      // Add winner highlighting to selected athlete
      athleteSlot.classList.add('winner-slot')
      
      // Update or create winner badge
      let winnerBadge = matchBox.querySelector('.winner-badge')
      const athleteName = athleteSlot.querySelector('.athlete-name')?.textContent || 'Selected Athlete'
      
      if (winnerBadge) {
        winnerBadge.innerHTML = `
          <span class="badge bg-success">
            <i class="fa fa-trophy me-1"></i>
            Winner: ${athleteName}
          </span>
        `
      } else {
        const pendingBadge = matchBox.querySelector('.pending-badge')
        if (pendingBadge) {
          pendingBadge.remove()
        }
        
        const newBadge = document.createElement('div')
        newBadge.className = 'winner-badge mt-2 text-center'
        newBadge.innerHTML = `
          <span class="badge bg-success">
            <i class="fa fa-trophy me-1"></i>
            Winner: ${athleteName}
          </span>
        `
        matchBox.appendChild(newBadge)
      }
      
      console.log("Winner set successfully", data)
      
      // If changing winner, remove old winner from next round first
      if (isChangingWinner && oldWinnerId && data.next_bout_id) {
        await this.removeAthleteFromNextRound(data.next_bout_id, oldWinnerId)
      }
      
      // Update next round with new winner (only if next_bout_id exists)
      if (data.next_bout_id && data.next_round) {
        await this.updateNextRoundBout(data.next_bout_id, athleteId, athleteName, data)
      }
      
    } catch (error) {
      console.error("Error setting winner:", error)
      alert("Failed to set winner: " + error.message)
    }
  }

  async removeAthleteFromNextRound(nextBoutId, oldWinnerId) {
    const nextBoutElement = document.querySelector(`[data-bout-id="${nextBoutId}"]`)
    if (!nextBoutElement) return
    
    // Find and clear the slot with old winner
    const slots = nextBoutElement.querySelectorAll('.athlete-slot')
    slots.forEach(slot => {
      if (slot.dataset.athleteId === oldWinnerId.toString()) {
        slot.dataset.athleteId = ""
        slot.innerHTML = '<div class="text-muted fst-italic">TBD</div>'
        
        // Remove winner highlighting if it exists
        slot.classList.remove('winner-slot')
        
        // Add a brief animation
        slot.classList.add('swap-error')
        setTimeout(() => {
          slot.classList.remove('swap-error')
        }, 400)
      }
    })
    
    // Remove winner badge from next round bout if both slots are now empty
    const allSlots = nextBoutElement.querySelectorAll('.athlete-slot')
    const anyFilled = Array.from(allSlots).some(slot => {
      const id = slot.dataset.athleteId
      return id && id !== 'null' && !slot.textContent.includes('TBD')
    })
    
    if (!anyFilled) {
      const winnerBadge = nextBoutElement.querySelector('.winner-badge')
      if (winnerBadge) winnerBadge.remove()
    }
  }
  
  async updateNextRoundBout(nextBoutId, athleteId, athleteName, data) {
    try {
      // Find the next round bout element
      let nextBoutElement = document.querySelector(`[data-bout-id="${nextBoutId}"]`)
      
      if (!nextBoutElement) {
        // Create the next round bout dynamically
        await this.createNextRoundBout(nextBoutId, data.next_round, athleteId, athleteName, data)
        return
      }
      
      // Find the empty slot (TBD) or slot with matching athlete_id
      const slots = nextBoutElement.querySelectorAll('.athlete-slot')
      let targetSlot = null
      
      slots.forEach(slot => {
        const id = slot.dataset.athleteId
        if (id === athleteId.toString()) {
          targetSlot = slot
        } else if ((!id || id === 'null' || slot.textContent.includes('TBD')) && !targetSlot) {
          targetSlot = slot
        }
      })
      
      if (targetSlot && targetSlot.dataset.athleteId !== athleteId.toString()) {
        targetSlot.dataset.athleteId = athleteId
        const teamName = data.winner_team || "Advanced"
        
        targetSlot.innerHTML = `
          <div class="athlete-name fw-bold">${athleteName}</div>
          <small class="team-name text-muted">${teamName}</small>
        `
        
        targetSlot.classList.add('swap-success')
        setTimeout(() => {
          targetSlot.classList.remove('swap-success')
        }, 600)
        
        const allSlots = nextBoutElement.querySelectorAll('.athlete-slot')
        const bothFilled = Array.from(allSlots).every(slot => {
          const id = slot.dataset.athleteId
          return id && id !== 'null' && !slot.textContent.includes('TBD')
        })
        
        if (bothFilled) {
          let pendingBadge = nextBoutElement.querySelector('.pending-badge')
          if (!pendingBadge) {
            pendingBadge = document.createElement('div')
            pendingBadge.className = 'pending-badge mt-2 text-center'
            nextBoutElement.appendChild(pendingBadge)
          }
          pendingBadge.innerHTML = `
            <span class="badge bg-warning text-dark">
              <i class="fa fa-clock me-1"></i>
              Click athlete to set winner
            </span>
          `
        }
      }
    } catch (error) {
      console.error("Error updating next round bout:", error)
    }
  }

  async createNextRoundBout(boutId, roundNumber, athleteId, athleteName, data) {
    try {
      const bracketContainer = document.querySelector('.bracket-container')
      if (!bracketContainer) return
      
      // Find or create the round column
      let roundColumn = document.querySelector(`[data-round="${roundNumber}"]`)
      
      if (!roundColumn) {
        // Create new round column
        roundColumn = document.createElement('div')
        roundColumn.className = 'round-column'
        roundColumn.dataset.round = roundNumber
        
        // Calculate total rounds from first round bouts
        const firstRoundColumn = document.querySelector('[data-round="1"]')
        if (!firstRoundColumn) return
        
        const firstRoundBouts = firstRoundColumn.querySelectorAll('.match-box').length
        // Total rounds = log2(first_round_bouts) + 1 (approximately)
        const totalRounds = Math.ceil(Math.log2(firstRoundBouts)) + 1
        
        let roundName = `Round ${roundNumber}`
        
        if (roundNumber == totalRounds) {
          roundName = 'Final'
        } else if (roundNumber == totalRounds - 1) {
          roundName = 'Semi-Finals'
        }
        
        roundColumn.innerHTML = `<h5 class="mb-3 text-center">${roundName}</h5>`
        bracketContainer.appendChild(roundColumn)
      }
      
      // Create the match box
      const matchBox = document.createElement('div')
      matchBox.className = 'match-box'
      matchBox.id = `bout-${boutId}`
      matchBox.dataset.boutId = boutId
      
      const teamName = data.winner_team || "Advanced"
      
      matchBox.innerHTML = `
        <div class="slot athlete-slot slot-a" data-drag-target="slot" data-athlete-id="${athleteId}" data-action="click->drag#selectWinner" draggable="true">
          <div class="athlete-name fw-bold">${athleteName}</div>
          <small class="team-name text-muted">${teamName}</small>
        </div>
        <div class="vs-divider text-center my-2">
          <small class="text-muted fw-bold">vs</small>
        </div>
        <div class="slot athlete-slot slot-b" data-drag-target="slot" data-athlete-id="" data-action="click->drag#selectWinner" draggable="true">
          <div class="text-muted fst-italic">TBD</div>
        </div>
      `
      
      roundColumn.appendChild(matchBox)
      
      // Add success animation
      matchBox.classList.add('swap-success')
      setTimeout(() => {
        matchBox.classList.remove('swap-success')
      }, 600)
      
      // Re-setup drag and drop for new elements
      this.setupDragAndDrop()
    } catch (error) {
      console.error("Error creating next round bout:", error)
    }
  }
}