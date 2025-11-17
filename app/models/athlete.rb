class Athlete < ApplicationRecord
  
  belongs_to :team
  has_many :registrations, dependent: :destroy
  has_many :divisions, through: :registrations
  
  validates :birthdate, presence: true
  validates :weight, presence: true
  
  BELTS = ["White", "Yellow", "Green", "Blue", "Red", "Brown" ,"Black"].freeze
  validates :belt, inclusion: { in: BELTS }, allow_nil: true
  
  SEXES = ["Male", "Female"].freeze
  validates :sex, inclusion: { in: SEXES }, allow_nil: true
  
end
