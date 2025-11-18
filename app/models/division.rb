class Division < ApplicationRecord
  belongs_to :event
  has_many :registrations, dependent: :destroy
  has_many :athletes, through: :registrations
  has_many :bouts, dependent: :destroy
  
  # Generate first-round bouts with minimal same-team conflicts
  def generate_first_round_bouts
    athletes = registrations.map(&:athlete).shuffle
    return if athletes.size < 2

    # Group athletes by team
    teams = athletes.group_by(&:team_id)

    # Prepare list of athletes to pair
    unpaired = athletes.dup
    pairs = []

    while unpaired.size >= 2
      a1 = unpaired.shift

      # Try to pick a2 from different team if possible
      idx = unpaired.index { |ath| ath.team_id != a1.team_id }
      if idx
        a2 = unpaired.delete_at(idx)
      else
        # fallback: no other team, pair with any
        a2 = unpaired.shift
      end

      pairs << [a1, a2]
    end

    # Handle bye if odd number
    if unpaired.any?
      # Create a bout with only athlete_a and winner is automatically set
      bye_athlete = unpaired.shift
      bouts.create!(athlete_a: bye_athlete, athlete_b: bye_athlete, winner: bye_athlete, round: 1)
    end

    # Create bouts
    pairs.each do |a1, a2|
      bouts.create!(athlete_a: a1, athlete_b: a2, round: 1)
    end
  end

  def eligible_athletes
    Athlete.where(
      sex: sex,
      belt: belt
    ).where("EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN ? AND ?", min_age, max_age)
     .where(weight: min_weight..max_weight)
  end
end
