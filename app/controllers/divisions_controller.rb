class DivisionsController < ApplicationController
  before_action :set_event
  before_action :set_division, only: [:show, :edit, :update, :destroy, :generate_bracket]
  # before_action :require_can_manage_team, only: [:show]
  before_action :require_can_manage_event, only: [:new, :create, :edit, :update, :destroy, :generate_bracket]
  
  def new
    @division = @event.divisions.new
  end
  
  def create
    @division = @event.divisions.new(division_params)
    if @division.save
      redirect_to @event, notice: "Division created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @division.update(division_params)
      redirect_to @event, notice: "Division updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end
    
  def show
    @event = @division.event
    @bouts_by_round = @division.bouts.order(:round, :id).group_by(&:round)
    @eligible_athletes = @division.eligible_athletes(current_user)
  end
  
  def destroy
    @division.destroy
    redirect_to @event, notice: "Division deleted successfully."
  end
  
  def generate_bracket
    @division.bouts.destroy_all
    @division.generate_complete_bracket
    flash[:notice] = "Bracket successfully generated."
    redirect_to event_division_path(@division.event, @division)
  end
  
  private
  
  def require_can_manage_team
    redirect_to @event, alert: "Not authorized" unless current_user&.can_manage_team?
  end
  
  def require_can_manage_event
    unless current_user&.can_manage_event?(@event)
      redirect_to @event, alert: "Not authorized"
    end
  end
  
  def set_event
    @event = Event.find(params[:event_id])
  end
  
  def set_division
    @division = @event.divisions.find(params[:id])
  end
  
  def athlete_age(athlete)
    return unless athlete.birthdate
    now = Date.today
    now.year - athlete.birthdate.year -
      ((now.month > athlete.birthdate.month ||
       (now.month == athlete.birthdate.month && now.day >= athlete.birthdate.day)) ? 0 : 1)
  end
  
  def division_params
    params.require(:division).permit(
      :name, :cost,
      :min_age, :max_age,
      :min_weight, :max_weight,
      :belt, :sex
    )
  end
end