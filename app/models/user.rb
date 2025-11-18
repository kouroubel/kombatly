class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :trackable
         
  # # Team admin
  has_one :team, foreign_key: :team_admin_id, dependent: :nullify
  # # Athlete user
  belongs_to :team, optional: true
  
  before_create :assign_initial_role
         
  enum role: { pending: 0, admin: 1, team: 2, athlete: 3 }
  
  private

  def assign_initial_role
    if User.count == 0
      self.role = :admin
    else
      # self.role = :pending
    end
  end
  
end
