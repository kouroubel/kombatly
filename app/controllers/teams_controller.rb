# app/controllers/teams_controller.rb
class TeamsController < ApplicationController

  before_action :set_team, only: [:show, :edit, :update, :destroy]
  before_action :require_can_manage_team, only: [:new, :create, :edit, :update, :destroy]
  
  def index
    if admin?
      @teams = Team.all
    else
      @teams = [current_user.administered_team].compact # team admins see only their team. compact removes nil if the user doesn't have a team (safety check)
    end
  end

  def show
  end
  
  def new
    @team = Team.new
  end
  
   def create
    @team = Team.new(team_params)
    # Team admins automatically assign their own id
    @team.team_admin_id = current_user.team_id unless current_user.admin?

    if @team.save
      redirect_to teams_path, notice: "Team created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @team.update(team_params)
      redirect_to teams_path, notice: "Team updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @team.destroy
    redirect_to teams_path, notice: "Team deleted"
  end

  private
  
  def require_can_manage_team
    redirect_to teams_path, alert: "Not authorized" unless current_user&.can_manage_team?
  end

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    if current_user.admin?
      # Admin can assign team_admin_id from form
      params.require(:team).permit(:name, :team_admin_id)
    else
      # Normal team cannot choose team_admin_id
      params.require(:team).permit(:name)
    end
  end


end
