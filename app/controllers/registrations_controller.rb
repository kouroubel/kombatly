class RegistrationsController < ApplicationController
  before_action :set_event_and_division, only: [:new, :create]
  before_action :require_has_team, only: [:new, :create, :new_for_athlete, :create_for_athlete]
  before_action :set_athlete, only: [:new_for_athlete, :create_for_athlete]
  before_action :set_event_for_athlete, only: [:new_for_athlete, :create_for_athlete]
  
  # Division-based registration (register multiple athletes for ONE division)
  def new
    # Superadmin: all athletes, Organizer/Team Admin: only their team
    scope = current_user.superadmin? ? Athlete.all : current_user.administered_team.athletes

    @eligible_athletes = scope.where(id: @division.eligible_athletes(current_user))
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
  
  # Athlete-based registration (register ONE athlete for multiple divisions)
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
  
  def set_event_and_division
    @event = Event.find(params[:event_id])
    @division = @event.divisions.find(params[:division_id])
  end
  
  def set_athlete
    @athlete = Athlete.find(params[:athlete_id])
  end
  
  def set_event_for_athlete
    @event = Event.find(params[:event_id])
  end
  
  def require_has_team
    unless current_user.superadmin? || current_user.administered_team.present?
      redirect_to root_path, alert: "You need a team to register athletes"
    end
  end
end