class Bout < ApplicationRecord
  belongs_to :division
  belongs_to :athlete_a, class_name: "Athlete", optional: true
  belongs_to :athlete_b, class_name: "Athlete", optional: true
  belongs_to :winner, class_name: "Athlete", optional: true
  belongs_to :second_place_athlete, class_name: "Athlete", optional: true   # this is the loser of the final that gets the second place. *only* the final bout uses this
  has_many :point_events, dependent: :destroy
end