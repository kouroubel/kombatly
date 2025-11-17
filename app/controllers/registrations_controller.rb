class RegistrationsController < ApplicationController
  before_action :set_event
  before_action :set_division, except: [:new_for_athlete, :create_for_athlete]
  before_action :set_athlete, only: [:new_for_athlete, :create_for_athlete]
  
  before_action :authorize_athlete_access, only: [:new_for_athlete, :create_for_athlete]

  def new
    # Team admins: only their team, only eligible, exclude already registered
    scope = current_user.admin? ? Athlete.all : current_user.team.athletes

    @eligible_athletes =
      scope
        .where(id: @division.eligible_athletes)
        # .where.not(id: @division.athletes.ids)
  end

  def create
    athlete_ids = Array(params[:athlete_ids]).map(&:to_i) # selected athletes
    current_registered_ids = @division.athletes.ids
  
    # Remove unchecked registrations
    (current_registered_ids - athlete_ids).each do |athlete_id|
      @division.registrations.find_by(athlete_id: athlete_id)&.destroy
    end
  
    # Add new registrations
    (athlete_ids - current_registered_ids).each do |athlete_id|
      @division.registrations.create!(athlete_id: athlete_id)
    end
  
    redirect_to event_division_path(@event, @division),
                notice: "Registrations updated successfully!"
  end
  
  def new_for_athlete
    # Eligible divisions for this athlete
    @eligible_divisions = @event.divisions.select do |d|
      d.eligible_athletes.include?(@athlete)
    end
  end

  # POST /athletes/:athlete_id/events/:event_id/register
  def create_for_athlete
    division_ids = params[:division_ids] || []
  
    # First, remove registrations for divisions that were unchecked
    @athlete.registrations.where(division: @event.divisions)
            .where.not(division_id: division_ids)
            .destroy_all
  
    # Then, create registrations for checked divisions if they don't exist
    division_ids.each do |division_id|
      division = @event.divisions.find(division_id)
      @athlete.registrations.find_or_create_by(division: division)
    end
  
    redirect_to athlete_path(@athlete), notice: "Registrations updated."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_division
    @division = @event.divisions.find(params[:division_id])
  end
  
  def set_athlete
    @athlete = Athlete.find(params[:athlete_id])
  end
  
  def authorize_athlete_access
    return if current_user.admin?
  
    # team admin: can only manage athletes from their own team
    unless @athlete.team_id == current_user.team_id
      redirect_to athlete_path(@athlete), alert: "You are not allowed to manage this athlete."
    end
  end

  def registration_params
    params.permit(athlete_ids: [])
  end
end
