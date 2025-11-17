class Registration < ApplicationRecord
  belongs_to :athlete
  belongs_to :division
  
  validates :athlete_id, uniqueness: { scope: :division_id }
end
