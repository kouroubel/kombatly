class Athlete < ApplicationRecord
  
  belongs_to :team
  has_many :registrations, dependent: :destroy
  has_many :divisions, through: :registrations
  
  validates :birthdate, presence: true
  validates :weight, presence: true
  validates :rank, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 13 }
  
  validate :check_registration_eligibility, on: :update
  
  SEXES = ["Male", "Female"].freeze
  validates :sex, inclusion: { in: SEXES }, allow_nil: true
  
  RANK_SYSTEMS = {
    karate: {
      1 => '10th Kyu (White)',
      2 => '9th Kyu (Yellow)',
      3 => '8th Kyu (Orange)',
      4 => '7th Kyu (Green)',
      5 => '6th Kyu (Blue)',
      6 => '5th Kyu (Purple)',
      7 => '4th Kyu (Purple)',
      8 => '3rd Kyu (Brown)',
      9 => '2nd Kyu (Brown)',
      10 => '1st Kyu (Brown)',
      11 => '1st Dan (Black)',
      12 => '2nd Dan (Black)',
      13 => '3rd Dan (Black)'
    },
    taekwondo: {
      1 => '10th Gup (White)',
      2 => '9th Gup (White/Yellow)',
      3 => '8th Gup (Yellow)',
      4 => '7th Gup (Yellow/Green)',
      5 => '6th Gup (Green)',
      6 => '5th Gup (Green/Blue)',
      7 => '4th Gup (Blue)',
      8 => '3rd Gup (Blue/Red)',
      9 => '2nd Gup (Red)',
      10 => '1st Gup (Red/Black)',
      11 => '1st Dan (Black)',
      12 => '2nd Dan (Black)',
      13 => '3rd Dan (Black)'
    },
    # judo: {
    #   1 => '6th Kyu (White)',
    #   2 => '5th Kyu (Yellow)',
    #   3 => '4th Kyu (Orange)',
    #   4 => '3rd Kyu (Green)',
    #   5 => '2nd Kyu (Blue)',
    #   6 => '1st Kyu (Brown)',
    #   7 => '1st Dan (Black)',
    #   8 => '2nd Dan (Black)',
    #   9 => '3rd Dan (Black)',
    #   10 => '4th Dan (Black)',
    #   11 => '5th Dan (Black)',
    #   12 => '6th Dan (Black)',
    #   13 => '7th Dan (Black)'
    # }
  }.freeze
  
  def rank_name(sport_type)
    RANK_SYSTEMS[sport_type.to_sym][rank] || "Unknown Rank"
  end
  
  private
    def check_registration_eligibility
      return unless persisted? # Skip for new records
      
      # Check if critical attributes changed
      critical_changes = changes.slice('birthdate', 'weight', 'rank', 'sex')
      return if critical_changes.empty?
      
      # Find divisions where athlete is registered
      registered_divisions = divisions.includes(:event)
      
      # Check if athlete would still be eligible for each division with new attributes
      ineligible_divisions = registered_divisions.reject do |division|
        would_be_eligible_for?(division)
      end
      
      if ineligible_divisions.any?
        division_names = ineligible_divisions.map { |d| "#{d.event.name} - #{d.name}" }.join(", ")
        errors.add(:base, "Cannot update: athlete is registered for divisions they would no longer be eligible for: #{division_names}. Please unregister first.")
      end
    end
    
    def would_be_eligible_for?(division)
      age = ((Time.zone.now - (birthdate || self.birthdate_was).to_time) / 1.year.seconds).floor
      
      division.sex == (sex || self.sex_was) &&
      age.between?(division.min_age, division.max_age) &&
      (weight || self.weight_was).between?(division.min_weight, division.max_weight) &&
      (rank || self.rank_was).between?(division.min_rank, division.max_rank)
    end
  
end