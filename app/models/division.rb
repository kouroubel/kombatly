class Division < ApplicationRecord
  belongs_to :event
  has_many :registrations, dependent: :destroy
  has_many :athletes, through: :registrations
  has_many :bouts, dependent: :destroy
  
  # Generate first-round bouts with minimal same-team conflicts
  def generate_first_round_bouts
    athletes = registrations.map(&:athlete).shuffle
    return if athletes.size < 1  # Changed from < 2
    
    unpaired = athletes.dup
    pairs = []
    
    # Pair athletes while we have at least 2
    while unpaired.size > 1
      a1 = unpaired.shift
      idx = unpaired.index { |ath| ath.team_id != a1.team_id }
      idx ||= 0
      a2 = unpaired.delete_at(idx)
      pairs << [a1, a2]
    end
    
    # Create normal bouts
    pairs.each do |a1, a2|
      bouts.create!(athlete_a: a1, athlete_b: a2, round: 1)
    end
    
    # Handle bye if odd number remains
    if unpaired.any?
      bye_athlete = unpaired.shift
      bouts.create!(athlete_a: bye_athlete, athlete_b: nil, round: 1)
    end
  end
  
  def eligible_athletes
    Athlete.where(
      sex: sex,
      belt: belt
    ).where("EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN ? AND ?", min_age, max_age)
     .where(weight: min_weight..max_weight)
  end
  
  def generate_next_round
    # Find the current highest round
    current_round = bouts.maximum(:round) || 0
    
    # Get all bouts from current round
    current_bouts = bouts.where(round: current_round)
    
    # Check if all bouts have winners
    bouts_without_winners = current_bouts.where(winner_id: nil)
    if bouts_without_winners.any?
      return {
        success: false,
        error: "Cannot generate next round: #{bouts_without_winners.count} bout(s) still need winners"
      }
    end
    
    # Get all winners from current round
    winners = current_bouts.map(&:winner).compact
    
    # Check if we have enough winners for next round
    if winners.size < 2
      return {
        success: false,
        error: "Tournament complete! We have a champion: #{winners.first&.fullname}"
      }
    end
    
    # Shuffle winners for next round matchups
    unpaired = winners.shuffle
    pairs = []
    
    # Pair winners
    while unpaired.size > 1
      a1 = unpaired.shift
      # Try to avoid same team again
      idx = unpaired.index { |ath| ath.team_id != a1.team_id }
      idx ||= 0
      a2 = unpaired.delete_at(idx)
      pairs << [a1, a2]
    end
    
    # Create bouts for next round
    next_round = current_round + 1
    pairs.each do |a1, a2|
      bouts.create!(athlete_a: a1, athlete_b: a2, round: next_round)
    end
    
    # Handle bye if odd number
    if unpaired.any?
      bouts.create!(athlete_a: unpaired.first, athlete_b: nil, round: next_round)
    end
    
    {
      success: true,
      message: "Round #{next_round} generated successfully with #{pairs.size + unpaired.size} bout(s)!"
    }
  end
  
  def advance_winner_to_next_round(bout)
    return { success: false, error: "Bout has no winner" } unless bout.winner_id
    
    current_round = bout.round
    next_round = current_round + 1
    
    # Determine position in current round (0-indexed)
    current_round_bouts = bouts.where(round: current_round).order(:id)
    bout_position = current_round_bouts.index(bout)
    
    return { success: false, error: "Bout not found in round" } unless bout_position
    
    # Calculate which bout in next round (pair bouts: 0,1 -> 0; 2,3 -> 1; etc)
    next_bout_position = bout_position / 2
    
    # Determine if winner goes to slot A or B (even position -> A, odd -> B)
    slot = bout_position.even? ? "a" : "b"
    
    # Find or create the next round bout
    next_round_bouts = bouts.where(round: next_round).order(:id)
    next_bout = next_round_bouts[next_bout_position]
    
    unless next_bout
      # Create the bout if it doesn't exist yet
      next_bout = bouts.create!(
        round: next_round,
        athlete_a: nil,
        athlete_b: nil
      )
    end
    
    # Place winner in appropriate slot
    if slot == "a"
      next_bout.update!(athlete_a_id: bout.winner_id)
    else
      next_bout.update!(athlete_b_id: bout.winner_id)
    end
    
    { success: true, next_bout: next_bout }
  end

end
