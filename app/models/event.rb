class Event < ApplicationRecord
  belongs_to :organizer, class_name: 'User', foreign_key: :organizer_id
  
  has_many :divisions, dependent: :destroy
  has_many :registrations, through: :divisions
  
  # Validations
  validates :name, presence: true
  validates :start_date, presence: true
  
  def team_fees_breakdown
    # Get all registrations for this event with athlete and division
    regs = registrations.includes(:athlete, :division)
    
    # Group by team
    by_team = regs.group_by { |r| r.athlete.team }
    
    # Calculate fees per team
    by_team.transform_values do |team_regs|
      {
        total: team_regs.sum { |r| r.division.cost },
        by_division: team_regs.group_by(&:division).transform_values do |div_regs|
          {
            count: div_regs.count,
            cost: div_regs.first.division.cost,
            total: div_regs.count * div_regs.first.division.cost
          }
        end
      }
    end
  end
  
  # Scopes
  scope :upcoming, -> { where('start_date >= ?', Date.today) }
  scope :past, -> { where('start_date < ?', Date.today) }
end