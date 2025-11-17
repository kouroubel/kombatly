class Event < ApplicationRecord
  has_many :divisions, dependent: :destroy
  has_many :registrations, dependent: :destroy
end
