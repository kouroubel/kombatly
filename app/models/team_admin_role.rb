class TeamAdminRole < ApplicationRecord
  belongs_to :user
  belongs_to :team
  
  validates :user_id, uniqueness: { message: "is already an admin of another team" }
  validates :team_id, uniqueness: { message: "already has an admin" }
end