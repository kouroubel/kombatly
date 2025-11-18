class Event < ApplicationRecord
  has_many :divisions, dependent: :destroy
  has_many :registrations, through: :divisions

end
