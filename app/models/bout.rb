class Bout < ApplicationRecord
  belongs_to :division
  belongs_to :athlete_a, class_name: "Athlete", optional: true
  belongs_to :athlete_b, class_name: "Athlete", optional: true
  belongs_to :winner, class_name: "Athlete", optional: true
  has_many :point_events, dependent: :destroy
end