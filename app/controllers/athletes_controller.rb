class AthletesController < ApplicationController
  before_action :set_athlete, only: [:show, :edit, :update, :destroy]
  before_action :require_has_team, only: [:new, :create, :edit, :update, :destroy]
  before_action :restrict_team_access, only: [:show, :edit, :update, :destroy]
  
  def index
    if current_user.superadmin?
      @athletes = Athlete.includes(:team).order('teams.name, athletes.fullname')
    elsif current_user.administered_team.present?
      @athletes = current_user.administered_team.athletes.order(:fullname)
    else
      @athletes = Athlete.none
    end
  end
  
  def show
  end
  
  def new
    @athlete = Athlete.new
    @teams = get_teams_for_select
  end
  
  def create
    @athlete = Athlete.new(athlete_params)
    
    # Non-superadmins can only create athletes for their own team
    unless current_user.superadmin?
      @athlete.team = current_user.administered_team
    end
    
    if @athlete.save
      redirect_to athletes_path, notice: "Athlete created successfully."
    else
      @teams = get_teams_for_select
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @teams = get_teams_for_select
  end
  
  def update
    # Prevent non-superadmins from changing the team
    update_params = current_user.superadmin? ? athlete_params : athlete_params.except(:team_id)
    
    if @athlete.update(update_params)
      redirect_to athletes_path, notice: "Athlete updated successfully."
    else
      @teams = get_teams_for_select
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @athlete.destroy
    redirect_to athletes_path, notice: "Athlete deleted successfully."
  end
  
  private
  
  def set_athlete
    @athlete = Athlete.find(params[:id])
  end
  
  def require_has_team
    unless current_user.superadmin? || current_user.administered_team.present?
      redirect_to root_path, alert: "You need a team to manage athletes"
    end
  end
  
  def restrict_team_access
    return if current_user.superadmin?
    
    unless @athlete.team_id == current_user.administered_team&.id
      redirect_to athletes_path, alert: "You can only access athletes from your own team"
    end
  end
  
  def get_teams_for_select
    if current_user.superadmin?
      Team.all.order(:name)
    else
      [current_user.administered_team].compact
    end
  end
  
  def athlete_params
    params.require(:athlete).permit(:fullname, :birthdate, :weight, :rank, :sex, :card_number, :team_id)
  end
end