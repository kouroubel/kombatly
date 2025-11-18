class Registration < ApplicationRecord
  belongs_to :athlete
  belongs_to :division
  delegate :event, to: :division    # Allows: registration.event (equivalent to belongs_to :event, through: :division which is not permitted)
  
  validates :athlete_id, uniqueness: { scope: :division_id }
end
