class Team < ApplicationRecord
  # New way: using join table
  has_one :team_admin_role, dependent: :destroy
  has_one :team_admin, through: :team_admin_role, source: :user
  
  has_many :athletes, dependent: :destroy
  has_many :registrations, through: :athletes
  
  validates :name, presence: true
  
  before_destroy :prevent_direct_deletion, prepend: true
  
  def destroy_with_admin!
    @allow_deletion = true
    destroy!
  end
  
  private
  
  def prevent_direct_deletion
    unless @allow_deletion
      errors.add(:base, "Delete the team admin user to remove this team")
      throw(:abort)
    end
  end
end