class Event < ApplicationRecord
  belongs_to :organizer, class_name: 'User', foreign_key: :organizer_id
  
  has_many :divisions, dependent: :destroy
  has_many :registrations, through: :divisions
  
  # Validations
  validates :name, presence: true
  validates :start_date, presence: true
  
  # Scopes
  scope :upcoming, -> { where('start_date >= ?', Date.today) }
  scope :past, -> { where('start_date < ?', Date.today) }
end