class RegistrationsController < ApplicationController
  before_action :set_event_and_division, only: [:new, :create, :destroy, :toggle]
  before_action :require_has_team, only: [:new, :create, :new_for_athlete, :create_for_athlete, :toggle]
  before_action :set_athlete, only: [:new_for_athlete, :create_for_athlete]
  before_action :set_event_for_athlete, only: [:new_for_athlete, :create_for_athlete]
  
  # Division-based registration (register multiple athletes for ONE division)
  # Used by checkbox form at /events/:event_id/divisions/:division_id/registrations/new
  def new
    scope = current_user.superadmin? ? Athlete.all : current_user.administered_team.athletes
    @eligible_athletes = scope.where(id: @division.eligible_athletes(current_user))
  end
  
  def create
    athlete_ids = Array(params[:athlete_ids]).map(&:to_i)
    
    # Scope to only athletes the user can manage
    if current_user.superadmin?
      manageable_athlete_ids = @division.athletes.ids
    else
      manageable_athlete_ids = @division.athletes.where(team_id: current_user.administered_team.id).ids
    end

    # Remove unchecked registrations (ONLY from user's manageable athletes)
    (manageable_athlete_ids - athlete_ids).each do |athlete_id|
      @division.registrations.find_by(athlete_id: athlete_id)&.destroy
    end

    # Add new registrations
    (athlete_ids - manageable_athlete_ids).each do |athlete_id|
      athlete = Athlete.find(athlete_id)
      next unless current_user.superadmin? || current_user.can_manage_event?(@event) || athlete.team_id == current_user.administered_team.id
      
      @division.registrations.create!(athlete_id: athlete_id)
    end

    redirect_to event_division_path(@event, @division),
                notice: "Registrations updated successfully!"
  end
  
  # NEW: Toggle single athlete registration (for icon buttons)
  def toggle
    athlete_id = params[:athlete_ids].first.to_i
    athlete = Athlete.find(athlete_id)
    
    # Security check
    unless current_user.superadmin? || current_user.can_manage_event?(@event) || athlete.team_id == current_user.administered_team&.id
      redirect_to event_division_path(@event, @division), alert: "Not authorized"
      return
    end
    
    registration = @division.registrations.find_by(athlete_id: athlete_id)
    
    if registration
      # Already registered - this shouldn't happen, but handle it
      redirect_to event_division_path(@event, @division), alert: "Athlete already registered"
    else
      # Create new registration
      @division.registrations.create!(athlete_id: athlete_id)
      redirect_to event_division_path(@event, @division), notice: "#{athlete.fullname} registered successfully"
    end
  end
  
  def destroy
    registration = Registration.find(params[:id])
    @division = registration.division
    @event = @division.event
    athlete = registration.athlete
    
    # Security check
    unless current_user.superadmin? || 
           current_user.can_manage_event?(@event) || 
           athlete.team_id == current_user.administered_team&.id
      redirect_to event_division_path(@event, @division), alert: "Not authorized"
      return
    end
    
    registration.destroy
    redirect_to event_division_path(@event, @division), notice: "#{athlete.fullname} unregistered successfully"
  end
  
  # Athlete-based registration (register ONE athlete for multiple divisions)
  # Used by checkbox form at /athletes/:athlete_id/events/:event_id/register
  # def new_for_athlete
  #   @divisions = @event.divisions.select do |div|
  #     eligible_ids = div.eligible_athletes(current_user).pluck(:id)
  #     eligible_ids.include?(@athlete.id)
  #   end
    
  #   @eligible_divisions = @athlete.divisions.where(event: @event)
  # end
  
  # def create_for_athlete
  #   division_ids = Array(params[:division_ids]).compact.map(&:to_i)
  #   current_registered = @athlete.registrations.joins(:division).where(divisions: { event_id: @event.id })
  #   current_division_ids = current_registered.pluck(:division_id)
    
  #   # Remove unchecked
  #   (current_division_ids - division_ids).each do |div_id|
  #     @athlete.registrations.joins(:division).find_by(divisions: { id: div_id, event_id: @event.id })&.destroy
  #   end
    
  #   # Add new
  #   (division_ids - current_division_ids).each do |div_id|
  #     @athlete.registrations.create!(division_id: div_id)
  #   end
    
  #   redirect_to athletes_path, notice: "#{@athlete.fullname} registered successfully!"
  # end
  
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