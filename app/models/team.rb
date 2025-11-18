class Team < ApplicationRecord
  
  # The user who administers this team
  belongs_to :team_admin, class_name: "User", foreign_key: :team_admin_id, optional: true
  # after_destroy :destroy_team_admin
  
  has_many :users, dependent: :destroy
  has_many :athletes, dependent: :destroy
  has_many :registrations, through: :athletes
  
  # ensures that no two teams can have the same admin.
  validates :team_admin_id, uniqueness: { message: "is already assigned to another team" }
  
  
  private

  def destroy_team_admin
    # Only destroy if the team_admin exists
    team_admin&.destroy
  end
  
end
