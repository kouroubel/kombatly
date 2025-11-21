class AthletesController < ApplicationController

  before_action :set_athlete, only: [:show, :edit, :update, :destroy]
  before_action :require_can_manage_team, only: [:new, :create, :edit, :update, :destroy]
  before_action :restrict_team_admin_access, only: [:show, :edit, :update, :destroy]


  def index
    if current_user.superadmin?
      @athletes = Athlete.includes(:team).order('teams.name, athletes.fullname')
    elsif current_user.can_manage_team?
      # Only show their team's athletes
      if current_user.administered_team.present?
        @athletes = current_user.administered_team.athletes.order(:fullname)
      else
        @athletes = Athlete.none
      end
    else
      @athletes = Athlete.none
    end
  end

  def show; end
    

  def new
    @athlete = Athlete.new
  end

  def create
    @athlete = Athlete.new(athlete_params)
    # Team admins automatically assign their own id
    @athlete.team_id = current_user.team_id unless current_user.admin?

    if @athlete.save
      redirect_to athletes_path, notice: "Athlete created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit; end

  def update
    # Teams cannot change the team
    params[:athlete].delete(:team_id) unless current_user.admin?

    if @athlete.update(athlete_params)
      redirect_to athletes_path, notice: "Athlete updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @athlete.destroy
    redirect_to athletes_path, notice: "Athlete deleted"
  end

  private

  def set_athlete
    @athlete = Athlete.find(params[:id])
  end
  
  def require_can_manage_team
    redirect_to root_path, alert: "Not authorized" unless current_user&.can_manage_team?
  end
  
  def restrict_team_admin_access
    return if current_user.admin?
  
    unless @athlete.team_id == current_user.team_id
      redirect_to athletes_path, alert: "You are not allowed to access this athlete."
    end
  end

  def athlete_params
    params.require(:athlete).permit(:fullname, :birthdate, :weight, :belt, :sex, :card_number, :team_id)
  end


end
