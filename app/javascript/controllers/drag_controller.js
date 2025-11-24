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

  // Fetch rendered HTML from Rails for a regular athlete slot
  async fetchSlotContent(athleteId, options = {}) {
    const params = new URLSearchParams()
    
    if (athleteId) {
      params.append('athlete_id', athleteId)
    }
    
    if (options.show_medal) params.append('show_medal', 'true')
    if (options.medal_color) params.append('medal_color', options.medal_color)
    if (options.show_trophy) params.append('show_trophy', 'true')
    if (options.place_badge) {
      params.append('place_badge[class]', options.place_badge.class)
      params.append('place_badge[style]', options.place_badge.style)
      params.append('place_badge[text]', options.place_badge.text)
    }
    if (options.corner_badge) {
      params.append('corner_badge[class]', options.corner_badge.class)
      params.append('corner_badge[style]', options.corner_badge.style)
      params.append('corner_badge[text]', options.corner_badge.text)
    }
    
    const response = await fetch(`/bouts/render_slot?${params}`, {
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    
    if (!response.ok) throw new Error("Failed to fetch slot content")
    return await response.text()
  }

  // Fetch rendered HTML from Rails for a champion slot
  async fetchChampionSlotContent(athleteId, place) {
    const params = new URLSearchParams()
    
    if (athleteId) {
      params.append('athlete_id', athleteId)
    }
    
    // Configure based on place
    if (place === 1) {
      params.append('medal_icon', 'trophy')
      params.append('medal_color', '#ffd700')
      params.append('badge_class', 'text-dark')
      params.append('badge_style', 'background-color: #ffd700;')
      params.append('badge_text', '🥇 1st Place')
    } else if (place === 2) {
      params.append('medal_icon', 'medal')
      params.append('medal_color', '#c0c0c0')
      params.append('badge_class', 'text-dark')
      params.append('badge_style', 'background-color: #c0c0c0;')
      params.append('badge_text', '🥈 2nd Place')
    } else if (place === 3) {
      params.append('medal_icon', 'medal')
      params.append('medal_color', '#cd7f32')
      params.append('badge_class', 'text-white')
      params.append('badge_style', 'background-color: #cd7f32;')
      params.append('badge_text', '🥉 3rd Place')
    }
    
    const response = await fetch(`/bouts/render_champion_slot?${params}`, {
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    
    if (!response.ok) throw new Error("Failed to fetch champion slot content")
    return await response.text()
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
      
      matchBox.querySelectorAll('.athlete-slot').forEach(slot => {
        slot.classList.remove('winner-slot')
      })
      
      athleteSlot.classList.add('winner-slot')
      
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
      
      if (data.is_semi_final) {
        await this.reloadFinalAndConsolationBouts(data.next_bout_id, data.consolation_bout_id)
        return
      }
      
      if (isChangingWinner && oldWinnerId && data.next_bout_id) {
        await this.removeAthleteFromNextRound(data.next_bout_id, oldWinnerId)
      }
      
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
      const finalResponse = await fetch(`/bouts/${finalBoutId}.json`, {
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      
      if (!finalResponse.ok) throw new Error("Failed to fetch final bout")
      const finalData = await finalResponse.json()
      
      const consolationResponse = await fetch(`/bouts/${consolationBoutId}.json`, {
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      
      if (!consolationResponse.ok) throw new Error("Failed to fetch consolation bout")
      const consolationData = await consolationResponse.json()
      
      await this.updateBoutFromData(finalBoutId, finalData)
      await this.updateBoutFromData(consolationBoutId, consolationData)
      
      console.log("Final and Consolation bouts updated successfully")
      
    } catch (error) {
      console.error("Error reloading bouts:", error)
    }
  }
  
  async updateBoutFromData(boutId, boutData) {
    const boutElement = document.querySelector(`[data-bout-id="${boutId}"]`)
    if (!boutElement) return
    
    // Update slot A (AKA - red)
    const slotA = boutElement.querySelector('.slot-a')
    if (slotA) {
      if (boutData.athlete_a) {
        slotA.dataset.athleteId = boutData.athlete_a.id
        slotA.innerHTML = await this.fetchSlotContent(boutData.athlete_a.id, {
          corner_badge: {
            class: 'bg-danger text-white',
            style: '',
            text: 'AKA'
          }
        })
        slotA.classList.add('swap-success')
        setTimeout(() => slotA.classList.remove('swap-success'), 600)
      } else {
        slotA.dataset.athleteId = ""
        slotA.innerHTML = await this.fetchSlotContent(null, {
          corner_badge: {
            class: 'bg-danger text-white',
            style: '',
            text: 'AKA'
          }
        })
      }
    }
    
    // Update slot B (SHIRO - blue)
    const slotB = boutElement.querySelector('.slot-b')
    if (slotB) {
      if (boutData.athlete_b) {
        slotB.dataset.athleteId = boutData.athlete_b.id
        slotB.innerHTML = await this.fetchSlotContent(boutData.athlete_b.id, {
          corner_badge: {
            class: 'bg-primary text-white',
            style: '',
            text: 'SHIRO'
          }
        })
        slotB.classList.add('swap-success')
        setTimeout(() => slotB.classList.remove('swap-success'), 600)
      } else {
        slotB.dataset.athleteId = ""
        slotB.innerHTML = await this.fetchSlotContent(null, {
          corner_badge: {
            class: 'bg-primary text-white',
            style: '',
            text: 'SHIRO'
          }
        })
      }
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
    
    const slots = nextBoutElement.querySelectorAll('.athlete-slot')
    for (const slot of slots) {
      if (slot.dataset.athleteId === oldWinnerId.toString()) {
        slot.dataset.athleteId = ""
        
        // Determine which corner badge to use based on slot class
        const isSlotA = slot.classList.contains('slot-a')
        const cornerBadge = isSlotA 
          ? { class: 'bg-danger text-white', style: '', text: 'AKA' }
          : { class: 'bg-primary text-white', style: '', text: 'SHIRO' }
        
        slot.innerHTML = await this.fetchSlotContent(null, { corner_badge: cornerBadge })
        slot.classList.remove('winner-slot')
        slot.classList.add('swap-error')
        setTimeout(() => slot.classList.remove('swap-error'), 400)
      }
    }
    
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
  
  async updateNextRoundBout(nextBoutId, athleteId, athleteName, data) {
    const nextBoutElement = document.querySelector(`[data-bout-id="${nextBoutId}"]`)
    
    if (!nextBoutElement) {
      console.error("Next bout not found in DOM:", nextBoutId)
      return
    }
    
    const isChampionBout = nextBoutElement.classList.contains('champion-display')
    
    if (isChampionBout) {
      await this.updateChampionSlots(nextBoutId, data)
      return
    }
    
    const boutTitle = nextBoutElement.querySelector('.text-primary, .text-warning')
    const isFinalBout = boutTitle && boutTitle.textContent.includes('Championship Final')
    const isConsolationBout = boutTitle && boutTitle.textContent.includes('3rd Place Match')
    
    if (isConsolationBout) {
      console.log("Skipping consolation - handled separately")
      return
    }
    
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
      targetSlot.classList.remove('winner-slot')
      
      // ALWAYS determine which corner badge to use based on slot class
      const isSlotA = targetSlot.classList.contains('slot-a')
      const cornerBadge = isSlotA 
        ? { class: 'bg-danger text-white', style: '', text: 'AKA' }
        : { class: 'bg-primary text-white', style: '', text: 'SHIRO' }
      
      targetSlot.innerHTML = await this.fetchSlotContent(athleteId, { corner_badge: cornerBadge })
      targetSlot.classList.add('swap-success')
      setTimeout(() => targetSlot.classList.remove('swap-success'), 600)
      
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
    try {
      const response = await fetch(`/bouts/${championBoutId}.json`, {
        headers: { "X-CSRF-Token": this.csrfToken }
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
        goldSlot.innerHTML = await this.fetchChampionSlotContent(boutData.athlete_a.id, 1)
      }
      
      // Update 2nd place (silver)
      const silverSlot = championElement.querySelector('.champion-slot-silver')
      if (silverSlot && boutData.loser) {
        silverSlot.dataset.athleteId = boutData.loser.id
        silverSlot.innerHTML = await this.fetchChampionSlotContent(boutData.loser.id, 2)
      }
      
      // Update 3rd place (bronze)
      const bronzeSlot = championElement.querySelector('.champion-slot-bronze')
      if (bronzeSlot && boutData.athlete_b) {
        bronzeSlot.dataset.athleteId = boutData.athlete_b.id
        bronzeSlot.innerHTML = await this.fetchChampionSlotContent(boutData.athlete_b.id, 3)
      }
      
      console.log("Champion slots updated successfully")
      
    } catch (error) {
      console.error("Error updating champion slots:", error)
    }
  }
}