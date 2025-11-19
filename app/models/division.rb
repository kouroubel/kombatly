class Division < ApplicationRecord
  belongs_to :event
  has_many :registrations, dependent: :destroy
  has_many :athletes, through: :registrations
  has_many :bouts, dependent: :destroy
  
  def generate_complete_bracket
    athletes = registrations.map(&:athlete).shuffle
    return if athletes.size < 2
    
    # Calculate rounds: we need rounds to get down to 2 athletes (semi-finals)
    total_athletes = athletes.size
    # normal_rounds = Math.log2(total_athletes).ceil      # this is for brackets without consolation final. simple elimination
    normal_rounds = (Math.log2(total_athletes) - 1).ceil  # this is for brackets with consolation final. -1 because semis lead to final
    normal_rounds = 1 if normal_rounds < 1
    
    # Generate first round with actual athletes (AVOID SAME TEAM)
    unpaired = athletes.dup
    first_round_bouts = []
    
    while unpaired.size > 1
      a1 = unpaired.shift
      # Try to find opponent from DIFFERENT team
      idx = unpaired.index { |ath| ath.team_id != a1.team_id }
      idx ||= 0
      a2 = unpaired.delete_at(idx)
      first_round_bouts << bouts.create!(athlete_a: a1, athlete_b: a2, round: 1, bout_type: "normal")
    end
    
    # Handle bye if odd number
    if unpaired.any?
      first_round_bouts << bouts.create!(athlete_a: unpaired.first, athlete_b: nil, round: 1, bout_type: "normal")
    end
    
    # Generate normal rounds (up to semi-finals)
    current_round_bouts = first_round_bouts
    
    (2..normal_rounds).each do |round_number|
      next_round_bouts = []
      num_bouts = (current_round_bouts.size / 2.0).ceil
      
      num_bouts.times do
        next_round_bouts << bouts.create!(athlete_a: nil, athlete_b: nil, round: round_number, bout_type: "normal")
      end
      
      current_round_bouts = next_round_bouts
    end
    
    # Create Final and Consolation bouts
    final_round = normal_rounds + 1
    bouts.create!(athlete_a: nil, athlete_b: nil, round: final_round, bout_type: "final")
    bouts.create!(athlete_a: nil, athlete_b: nil, round: final_round, bout_type: "consolation")
    
    # Create Champion display slot
    champion_round = final_round + 1
    bouts.create!(athlete_a: nil, athlete_b: nil, round: champion_round, bout_type: "champion")
  end
  
  def place_winner_in_next_round(bout)
    return { success: false } unless bout.winner_id
    
    # If this is the final, advance winner to 1st place and loser to 2nd place
    if bout.bout_type == "final"
      champion_bout = bouts.find_by(bout_type: "champion")
      if champion_bout
        # Winner goes to athlete_a (1st place)
        champion_bout.update!(athlete_a_id: bout.winner_id)
        
        # Loser goes to loser_id (2nd place)
        loser_id = bout.winner_id == bout.athlete_a_id ? bout.athlete_b_id : bout.athlete_a_id
        champion_bout.update!(loser_id: loser_id) if loser_id  # Changed from second_place_athlete_id
      end
      return { success: true, next_bout: champion_bout, bout_type: "champion" }
    end
    
    # If this is consolation, advance winner to 3rd place
    if bout.bout_type == "consolation"
      champion_bout = bouts.find_by(bout_type: "champion")
      # 3rd place winner goes to athlete_b slot in champion bout
      champion_bout.update!(athlete_b_id: bout.winner_id) if champion_bout
      return { success: true, next_bout: champion_bout, bout_type: "champion" }
    end
    
    # Check if this is a semi-final (round before final)
    final_bout = bouts.find_by(bout_type: "final")
    is_semi_final = (bout.round == final_bout.round - 1) if final_bout
    
    if is_semi_final
      # Semi-final winner goes to final
      current_round_bouts = bouts.where(round: bout.round, bout_type: "normal").order(:id)
      bout_index = current_round_bouts.to_a.index(bout)
      slot = bout_index.even? ? "a" : "b"
      
      if slot == "a"
        final_bout.update!(athlete_a_id: bout.winner_id)
      else
        final_bout.update!(athlete_b_id: bout.winner_id)
      end
      
      return { success: true, next_bout: final_bout, bout_type: "final" }
    end
    
    # Normal bout - standard progression
    current_round = bout.round
    next_round = current_round + 1
    
    current_round_bouts = bouts.where(round: current_round, bout_type: "normal").order(:id)
    bout_index = current_round_bouts.to_a.index(bout)
    
    return { success: false } unless bout_index
    
    next_bout_index = bout_index / 2
    slot = bout_index.even? ? "a" : "b"
    
    next_round_bouts = bouts.where(round: next_round, bout_type: "normal").order(:id)
    next_bout = next_round_bouts[next_bout_index]
    
    return { success: false } unless next_bout
    
    if slot == "a"
      next_bout.update!(athlete_a_id: bout.winner_id)
    else
      next_bout.update!(athlete_b_id: bout.winner_id)
    end
    
    { success: true, next_bout: next_bout, bout_type: "normal" }
  end
  
  def place_loser_in_consolation(bout)
    return { success: false } unless bout.winner_id
    
    # Only applies to semi-finals
    final_bout = bouts.find_by(bout_type: "final")
    is_semi_final = (bout.round == final_bout.round - 1) if final_bout
    
    return { success: false } unless is_semi_final
    
    # Determine loser
    loser_id = if bout.winner_id == bout.athlete_a_id
      bout.athlete_b_id
    else
      bout.athlete_a_id
    end
    
    return { success: false } unless loser_id
    
    # Place loser in consolation bout
    consolation_bout = bouts.find_by(bout_type: "consolation")
    current_round_bouts = bouts.where(round: bout.round, bout_type: "normal").order(:id)
    bout_index = current_round_bouts.to_a.index(bout)
    slot = bout_index.even? ? "a" : "b"
    
    if slot == "a"
      consolation_bout.update!(athlete_a_id: loser_id)
    else
      consolation_bout.update!(athlete_b_id: loser_id)
    end
    
    { success: true, consolation_bout: consolation_bout }
  end
  
  def eligible_athletes
    Athlete.where(
      sex: sex,
      belt: belt
    ).where("EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN ? AND ?", min_age, max_age)
     .where(weight: min_weight..max_weight)
  end
end