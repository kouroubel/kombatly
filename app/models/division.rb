class Division < ApplicationRecord
  belongs_to :event
  has_many :registrations, dependent: :destroy
  has_many :athletes, through: :registrations
  has_many :bouts, dependent: :destroy

  def eligible_athletes
    Athlete.where(
      sex: sex,
      belt: belt
    ).where("EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN ? AND ?", min_age, max_age)
     .where(weight: min_weight..max_weight)
  end
end
