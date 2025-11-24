class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]
  before_action :require_can_manage_team, only: [:edit, :update, :destroy]
  before_action :prevent_multiple_teams, only: [:new, :create]
  
  def index
    if current_user.superadmin?
      @teams = Team.all.order(:name)
    elsif current_user.administered_team.present?
      @teams = [current_user.administered_team]
    else
      @teams = []
    end
  end
  
  def show
    unless current_user.can_manage_team?(@team)
      redirect_to teams_path, alert: "Not authorized to view this team"
    end
  end
  
  def new
    @team = Team.new
  end
  
  def create
    @team = Team.new(team_params)
    
    if @team.save
      TeamAdminRole.create!(user: current_user, team: @team)
      redirect_to @team, notice: "Team created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @team.update(team_params)
      redirect_to @team, notice: "Team updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @team.destroy
      redirect_to teams_path, notice: "Team deleted successfully."
    else
      redirect_to teams_path, alert: @team.errors.full_messages.join(", ")
    end
  end
  
  private
  
  def set_team
    @team = Team.find(params[:id])
  end
  
  def require_can_manage_team
    unless current_user.can_manage_team?(@team)
      redirect_to teams_path, alert: "Not authorized"
    end
  end
  
  def prevent_multiple_teams
    if current_user.superadmin?
      redirect_to teams_path, alert: "Superadmin cannot create teams"
    elsif current_user.administered_team.present?
      redirect_to teams_path, alert: "You already have a team. You can only manage one team."
    end
  end
  
  def team_params
    params.require(:team).permit(:name)
  end
end