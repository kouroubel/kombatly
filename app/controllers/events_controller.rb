class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]
  # before_action :require_can_manage_team, only: [:index, :show]
  before_action :require_can_create_events, only: [:new, :create]
  before_action :require_can_manage_event, only: [:edit, :update, :destroy]

  # def index
  #   if current_user.superadmin?
  #     @events = Event.all.order(start_date: :asc)
  #   elsif current_user.organizer?
  #     @events = current_user.organized_events.order(start_date: :asc)
  #   else
  #     @events = Event.all.order(start_date: :asc)
  #   end
  # end
  
  
  def index
    @events = Event.all.order(start_date: :desc)
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    
    # Superadmin can create events without being the organizer
    # Organizers automatically become the organizer of their events
    @event.organizer = current_user unless current_user.superadmin?
    
    if @event.save
      redirect_to events_path, notice: "Event created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    @divisions = @event.divisions
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to events_path, notice: "Event updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, alert: "Event deleted."
  end

  private
  
  def require_can_manage_team_or_admin
    redirect_to events_path, alert: "Not authorized" unless current_user&.can_manage_team?
  end
  
  def require_can_create_events
    unless current_user&.can_create_events?
      redirect_to events_path, alert: "Not authorized"
    end
  end
  
  def require_can_manage_event
    unless current_user&.can_manage_event?(@event)
      redirect_to events_path, alert: "Not authorized"
    end
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :location, :start_date, :end_date, :description, :organizer_id)
  end
end