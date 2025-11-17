class EventsController < ApplicationController

  before_action :set_event, only: %i[show edit update destroy]
  before_action :require_admin_or_team, only: [:index, :show]
  before_action :require_admin, only: [:new, :create, :edit, :update, :destroy]

  def index
    @events = Event.all.order(start_date: :asc)
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to events_path, notice: "Event created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    @divisions = @event.divisions
  end

  def edit; end

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
  
  def require_admin_or_team
    unless current_user.admin? || current_user.team?
      redirect_to events_path, alert: "Not authorized"
    end
  end
  
  def require_admin
    unless current_user.admin?
      redirect_to events_path, alert: "Not authorized"
    end
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :location, :start_date, :description)
  end
end
