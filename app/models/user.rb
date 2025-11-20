class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :trackable

  enum role: { 
    pending: 0, 
    superadmin: 1, 
    organizer: 2, 
    team_admin: 3
  }

  # Team administration (both organizers and team_admins can have teams)
  has_one :team_admin_role, dependent: :destroy
  has_one :administered_team, through: :team_admin_role, source: :team
  
  # Events organized (only for organizers and superadmin)
  has_many :organized_events, class_name: 'Event', foreign_key: :organizer_id, dependent: :nullify
  
  # Set role before creation
  before_create :assign_initial_role
  before_destroy :destroy_administered_team
  
  # Backward compatibility helpers (so existing code still works)
  def admin?
    superadmin? || organizer?
  end
  
  def team?
    team_admin? || organizer?  # Organizers can also act as team admins
  end
  
  # New role helper methods
  def can_manage_team?
    organizer? || team_admin?
  end
  
  def can_create_events?
    superadmin? || organizer?
  end
  
  def can_manage_event?(event)
    return true if superadmin?
    return false if event.organizer_id.nil?
    event.organizer_id == id
  end
  
  def needs_approval?
    pending?
  end
  
  private
  
  def assign_initial_role
    if User.count == 0
      self.role = :superadmin  # First user is superadmin
    else
      self.role = :pending     # All other users need approval
    end
  end
  
  def destroy_administered_team
    administered_team&.destroy_with_admin!
  end
end