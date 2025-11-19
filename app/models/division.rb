class Division < ApplicationRecord
  belongs_to :event
  has_many :registrations, dependent: :destroy
  has_many :athletes, through: :registrations
  has_many :bouts, dependent: :destroy
  
  def generate_complete_bracket
    athletes = registrations.map(&:athlete).shuffle
    return if athletes.size < 2
    
    # Calculate total rounds needed (including winner round)
    total_athletes = athletes.size
    total_rounds = Math.log2(total_athletes).ceil + 1  # +1 for winner display
    
    # Generate first round with actual athletes (AVOID SAME TEAM)
    unpaired = athletes.dup
    first_round_bouts = []
    
    while unpaired.size > 1
      a1 = unpaired.shift
      # Try to find opponent from DIFFERENT team
      idx = unpaired.index { |ath| ath.team_id != a1.team_id }
      idx ||= 0  # Fallback if all same team
      a2 = unpaired.delete_at(idx)
      first_round_bouts << bouts.create!(athlete_a: a1, athlete_b: a2, round: 1)
    end
    
    # Handle bye if odd number
    if unpaired.any?
      first_round_bouts << bouts.create!(athlete_a: unpaired.first, athlete_b: nil, round: 1)
    end
    
    # Generate all subsequent rounds with TBD (nil) athletes
    current_round_bouts = first_round_bouts
    
    (2..total_rounds).each do |round_number|
      next_round_bouts = []
      
      # Create half as many bouts as previous round (rounded up)
      num_bouts = (current_round_bouts.size / 2.0).ceil
      num_bouts.times do
        next_round_bouts << bouts.create!(athlete_a: nil, athlete_b: nil, round: round_number)
      end
      
      current_round_bouts = next_round_bouts
    end
  end
  
  def place_winner_in_next_round(bout)
    return { success: false } unless bout.winner_id
    
    current_round = bout.round
    next_round = current_round + 1
    
    # Find position in current round
    current_round_bouts = bouts.where(round: current_round).order(:id)
    bout_index = current_round_bouts.to_a.index(bout)
    
    return { success: false } unless bout_index
    
    # Calculate next round bout index and slot
    next_bout_index = bout_index / 2
    slot = bout_index.even? ? "a" : "b"
    
    # Find the next round bout
    next_round_bouts = bouts.where(round: next_round).order(:id)
    next_bout = next_round_bouts[next_bout_index]
    
    return { success: false } unless next_bout
    
    # Place winner in correct slot
    if slot == "a"
      next_bout.update!(athlete_a_id: bout.winner_id)
    else
      next_bout.update!(athlete_b_id: bout.winner_id)
    end
    
    { success: true, next_bout: next_bout }
  end
  
  def eligible_athletes
    Athlete.where(
      sex: sex,
      belt: belt
    ).where("EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN ? AND ?", min_age, max_age)
     .where(weight: min_weight..max_weight)
  end
end