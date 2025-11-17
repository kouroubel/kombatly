class Team < ApplicationRecord
  
  # The user who administers this team
  belongs_to :team_admin, class_name: "User", foreign_key: :team_admin_id
  
  has_many :users, dependent: :destroy
  has_many :athletes, dependent: :destroy
  has_many :registrations, through: :athletes
  
end
