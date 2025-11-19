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
    // Check if tournament has started
    const anyWinnerBadge = document.querySelector('.winner-badge')
    
    if (anyWinnerBadge) {
      event.preventDefault()
      alert("Cannot swap athletes - tournament has already started!")
      return
    }
    
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
    
    if (!athleteId || athleteId === "null" || athleteId === "") {
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
      
      // Handle semi-final - fetch and update both bouts from server
      if (data.is_semi_final) {
        await this.reloadFinalAndConsolationBouts(data.next_bout_id, data.consolation_bout_id)
        return
      }
      
      // If changing winner, remove old winner from next round first
      if (isChangingWinner && oldWinnerId && data.next_bout_id) {
        await this.removeAthleteFromNextRound(data.next_bout_id, oldWinnerId)
      }
      
      // Update next round with new winner (for non-semi-finals)
      if (data.next_bout_id) {
        await this.updateNextRoundBout(data.next_bout_id, athleteId, athleteName, data)
      }
      
    } catch (error) {
      console.error("Error setting winner:", error)
      alert("Failed to set winner: " + error.message)
    }
  }
  
  async reloadFinalAndConsolationBouts(finalBoutId, consolationBoutId) {
    try {
      // Fetch final bout data
      const finalResponse = await fetch(`/bouts/${finalBoutId}.json`, {
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      
      if (!finalResponse.ok) throw new Error("Failed to fetch final bout")
      
      const finalData = await finalResponse.json()
      
      // Fetch consolation bout data
      const consolationResponse = await fetch(`/bouts/${consolationBoutId}.json`, {
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      
      if (!consolationResponse.ok) throw new Error("Failed to fetch consolation bout")
      
      const consolationData = await consolationResponse.json()
      
      // Update Final bout in DOM
      await this.updateBoutFromData(finalBoutId, finalData)
      
      // Update Consolation bout in DOM
      await this.updateBoutFromData(consolationBoutId, consolationData)
      
      console.log("Final and Consolation bouts updated successfully")
      
    } catch (error) {
      console.error("Error reloading bouts:", error)
    }
  }
  
  async updateBoutFromData(boutId, boutData) {
    const boutElement = document.querySelector(`[data-bout-id="${boutId}"]`)
    if (!boutElement) return
    
    // Update slot A
    const slotA = boutElement.querySelector('.slot-a')
    if (slotA && boutData.athlete_a) {
      slotA.dataset.athleteId = boutData.athlete_a.id
      slotA.innerHTML = `
        <div class="athlete-name fw-bold">${boutData.athlete_a.fullname}</div>
        <small class="team-name text-muted">${boutData.athlete_a.team_name}</small>
      `
      slotA.classList.add('swap-success')
      setTimeout(() => slotA.classList.remove('swap-success'), 600)
    }
    
    // Update slot B
    const slotB = boutElement.querySelector('.slot-b')
    if (slotB && boutData.athlete_b) {
      slotB.dataset.athleteId = boutData.athlete_b.id
      slotB.innerHTML = `
        <div class="athlete-name fw-bold">${boutData.athlete_b.fullname}</div>
        <small class="team-name text-muted">${boutData.athlete_b.team_name}</small>
      `
      slotB.classList.add('swap-success')
      setTimeout(() => slotB.classList.remove('swap-success'), 600)
    }
    
    // Check if both slots filled and add pending badge
    if (boutData.athlete_a && boutData.athlete_b) {
      let pendingBadge = boutElement.querySelector('.pending-badge')
      if (!pendingBadge) {
        pendingBadge = document.createElement('div')
        pendingBadge.className = 'pending-badge mt-2 text-center'
        boutElement.appendChild(pendingBadge)
      }
      pendingBadge.innerHTML = `
        <span class="badge bg-secondary">
          <i class="fa fa-clock me-1"></i>
          Click athlete to set winner
        </span>
      `
    }
  }

async reloadFinalAndConsolationBouts(finalBoutId, consolationBoutId) {
  try {
    // Fetch final bout data
    const finalResponse = await fetch(`/bouts/${finalBoutId}.json`, {
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    
    if (!finalResponse.ok) throw new Error("Failed to fetch final bout")
    
    const finalData = await finalResponse.json()
    
    // Fetch consolation bout data
    const consolationResponse = await fetch(`/bouts/${consolationBoutId}.json`, {
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    
    if (!consolationResponse.ok) throw new Error("Failed to fetch consolation bout")
    
    const consolationData = await consolationResponse.json()
    
    // Update Final bout in DOM
    await this.updateBoutFromData(finalBoutId, finalData)
    
    // Update Consolation bout in DOM
    await this.updateBoutFromData(consolationBoutId, consolationData)
    
    console.log("Final and Consolation bouts updated successfully")
    
  } catch (error) {
    console.error("Error reloading bouts:", error)
  }
}

async updateBoutFromData(boutId, boutData) {
  const boutElement = document.querySelector(`[data-bout-id="${boutId}"]`)
  if (!boutElement) return
  
  // Update slot A
  const slotA = boutElement.querySelector('.slot-a')
  if (slotA && boutData.athlete_a) {
    slotA.dataset.athleteId = boutData.athlete_a.id
    slotA.innerHTML = `
      <div class="athlete-name fw-bold">${boutData.athlete_a.fullname}</div>
      <small class="team-name text-muted">${boutData.athlete_a.team_name}</small>
    `
    slotA.classList.add('swap-success')
    setTimeout(() => slotA.classList.remove('swap-success'), 600)
  }
  
  // Update slot B
  const slotB = boutElement.querySelector('.slot-b')
  if (slotB && boutData.athlete_b) {
    slotB.dataset.athleteId = boutData.athlete_b.id
    slotB.innerHTML = `
      <div class="athlete-name fw-bold">${boutData.athlete_b.fullname}</div>
      <small class="team-name text-muted">${boutData.athlete_b.team_name}</small>
    `
    slotB.classList.add('swap-success')
    setTimeout(() => slotB.classList.remove('swap-success'), 600)
  }
  
  // Check if both slots filled and add pending badge
  if (boutData.athlete_a && boutData.athlete_b) {
    let pendingBadge = boutElement.querySelector('.pending-badge')
    if (!pendingBadge) {
      pendingBadge = document.createElement('div')
      pendingBadge.className = 'pending-badge mt-2 text-center'
      boutElement.appendChild(pendingBadge)
    }
    pendingBadge.innerHTML = `
      <span class="badge bg-secondary">
        <i class="fa fa-clock me-1"></i>
        Click athlete to set winner
      </span>
    `
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
      return id && id !== 'null' && id !== '' && !slot.textContent.includes('TBD')
    })
    
    if (!anyFilled) {
      const winnerBadge = nextBoutElement.querySelector('.winner-badge')
      if (winnerBadge) winnerBadge.remove()
    }
  }
  
  async updateConsolationBout(consolationBoutId, loserId, loserName, data) {
    const consolationBoutElement = document.querySelector(`[data-bout-id="${consolationBoutId}"]`)
    
    if (!consolationBoutElement) {
      console.error("Consolation bout not found in DOM:", consolationBoutId)
      return
    }
    
    // Find the empty slot
    const slots = consolationBoutElement.querySelectorAll('.athlete-slot')
    let targetSlot = null
    
    slots.forEach(slot => {
      const id = slot.dataset.athleteId
      if ((!id || id === 'null' || id === '' || slot.textContent.includes('TBD')) && !targetSlot) {
        targetSlot = slot
      }
    })
    
    if (targetSlot) {
      targetSlot.dataset.athleteId = loserId
      const teamName = data.loser_team || "Advanced"
      
      targetSlot.innerHTML = `
        <div class="athlete-name fw-bold">${loserName}</div>
        <small class="team-name text-muted">${teamName}</small>
      `
      
      targetSlot.classList.add('swap-success')
      setTimeout(() => {
        targetSlot.classList.remove('swap-success')
      }, 600)
      
      // Check if consolation bout now has both athletes
      const allSlots = consolationBoutElement.querySelectorAll('.athlete-slot')
      const bothFilled = Array.from(allSlots).every(slot => {
        const id = slot.dataset.athleteId
        return id && id !== 'null' && id !== '' && !slot.textContent.includes('TBD')
      })
      
      if (bothFilled) {
        let pendingBadge = consolationBoutElement.querySelector('.pending-badge')
        if (!pendingBadge) {
          pendingBadge = document.createElement('div')
          pendingBadge.className = 'pending-badge mt-2 text-center'
          consolationBoutElement.appendChild(pendingBadge)
        }
        pendingBadge.innerHTML = `
          <span class="badge bg-secondary">
            <i class="fa fa-clock me-1"></i>
            Click athlete to set winner
          </span>
        `
      }
    }
  }
  
  async updateNextRoundBout(nextBoutId, athleteId, athleteName, data) {
    const nextBoutElement = document.querySelector(`[data-bout-id="${nextBoutId}"]`)
    
    if (!nextBoutElement) {
      console.error("Next bout not found in DOM:", nextBoutId)
      return
    }
    
    // Check if this is the champion bout
    const isChampionBout = nextBoutElement.classList.contains('champion-display')
    
    if (isChampionBout) {
      // Update champion display without reload
      await this.updateChampionSlots(nextBoutId, data)
      return
    }
    
    // Check if this bout is the FINAL or CONSOLATION
    const boutTitle = nextBoutElement.querySelector('.text-primary, .text-warning')
    const isFinalBout = boutTitle && boutTitle.textContent.includes('Championship Final')
    const isConsolationBout = boutTitle && boutTitle.textContent.includes('3rd Place Match')
    
    // For semi-finals updating the FINAL, only update if this is the winner
    // The loser should NOT update the final
    if (isFinalBout) {
      console.log("Updating FINAL bout with winner")
    } else if (isConsolationBout) {
      console.log("Skipping consolation - this is handled separately")
      return // Don't update consolation here - it's handled by updateConsolationBout
    }
    
    // Find the empty slot
    const slots = nextBoutElement.querySelectorAll('.athlete-slot')
    let targetSlot = null
    
    slots.forEach(slot => {
      const id = slot.dataset.athleteId
      if (id === athleteId.toString()) {
        targetSlot = slot
      } else if ((!id || id === 'null' || id === '' || slot.textContent.includes('TBD')) && !targetSlot) {
        targetSlot = slot
      }
    })
    
    if (targetSlot && targetSlot.dataset.athleteId !== athleteId.toString()) {
      targetSlot.dataset.athleteId = athleteId
      const teamName = data.winner_team || "Advanced"
      
      targetSlot.classList.remove('winner-slot')
      
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
        return id && id !== 'null' && id !== '' && !slot.textContent.includes('TBD')
      })
      
      if (bothFilled) {
        let pendingBadge = nextBoutElement.querySelector('.pending-badge')
        if (!pendingBadge) {
          pendingBadge = document.createElement('div')
          pendingBadge.className = 'pending-badge mt-2 text-center'
          nextBoutElement.appendChild(pendingBadge)
        }
        pendingBadge.innerHTML = `
          <span class="badge bg-secondary">
            <i class="fa fa-clock me-1"></i>
            Click athlete to set winner
          </span>
        `
      }
    }
  }
  
  async updateChampionSlots(championBoutId, data) {
    // Fetch the latest champion bout data
    try {
      const response = await fetch(`/bouts/${championBoutId}.json`, {
        headers: {
          "X-CSRF-Token": this.csrfToken
        }
      })
      
      if (!response.ok) {
        console.error("Failed to fetch champion bout data")
        return
      }
      
      const boutData = await response.json()
      const championElement = document.querySelector(`[data-bout-id="${championBoutId}"]`)
      
      if (!championElement) return
      
      // Update 1st place (gold)
      const goldSlot = championElement.querySelector('.champion-slot-gold')
      if (goldSlot && boutData.athlete_a) {
        goldSlot.dataset.athleteId = boutData.athlete_a.id
        goldSlot.innerHTML = `
          <div class="text-center">
            <i class="fa fa-trophy fa-2x mb-2" style="color: #ffd700;"></i>
          </div>
          <div class="athlete-name fw-bold">${boutData.athlete_a.fullname}</div>
          <small class="team-name text-muted">${boutData.athlete_a.team_name}</small>
          <div class="winner-badge mt-2 text-center">
            <span class="badge text-dark" style="background-color: #ffd700;">
              🥇 1st Place
            </span>
          </div>
        `
      }
      
      // Update 2nd place (silver)
      const silverSlot = championElement.querySelector('.champion-slot-silver')
      if (silverSlot && boutData.second_place_athlete) {
        silverSlot.dataset.athleteId = boutData.second_place_athlete.id
        silverSlot.innerHTML = `
          <div class="text-center">
            <i class="fa fa-medal fa-2x mb-2" style="color: #c0c0c0;"></i>
          </div>
          <div class="athlete-name fw-bold">${boutData.second_place_athlete.fullname}</div>
          <small class="team-name text-muted">${boutData.second_place_athlete.team_name}</small>
          <div class="winner-badge mt-2 text-center">
            <span class="badge text-dark" style="background-color: #c0c0c0;">
              🥈 2nd Place
            </span>
          </div>
        `
      }
      
      // Update 3rd place (bronze)
      const bronzeSlot = championElement.querySelector('.champion-slot-bronze')
      if (bronzeSlot && boutData.athlete_b) {
        bronzeSlot.dataset.athleteId = boutData.athlete_b.id
        bronzeSlot.innerHTML = `
          <div class="text-center">
            <i class="fa fa-medal fa-2x mb-2" style="color: #cd7f32;"></i>
          </div>
          <div class="athlete-name fw-bold">${boutData.athlete_b.fullname}</div>
          <small class="team-name text-muted">${boutData.athlete_b.team_name}</small>
          <div class="winner-badge mt-2 text-center">
            <span class="badge text-white" style="background-color: #cd7f32;">
              🥉 3rd Place
            </span>
          </div>
        `
      }
      
      console.log("Champion slots updated successfully")
      
    } catch (error) {
      console.error("Error updating champion slots:", error)
    }
  }
}