class AthletesController < ApplicationController

  before_action :set_athlete, only: [:show, :edit, :update, :destroy]
  before_action :require_admin_or_team, only: [:new, :create, :edit, :update, :destroy]
  before_action :restrict_team_admin_access, only: [:show, :edit, :update, :destroy]

  def index
    if current_user.admin?
      @athletes = Athlete.includes(:team).order(:fullname)
    elsif current_user.team?
      @athletes = Athlete.includes(:team)
                         .where(team_id: current_user.team_id)
                         .order(:fullname)
    else
      # Optional: block access
      redirect_to root_path, alert: "Not authorized"
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
  
  def require_admin_or_team
    redirect_to root_path, alert: "Not authorized" unless current_user.admin? || current_user.team?
  end
  
  def restrict_team_admin_access
    return if current_user.admin?
  
    unless @athlete.team_id == current_user.team_id
      redirect_to athletes_path, alert: "You are not allowed to access this athlete."
    end
  end

  def athlete_params
    params.require(:athlete).permit(:fullname, :birthdate, :weight, :belt, :sex, :team_id)
  end



end
