module Public
  class EventsController < ApplicationController
    skip_before_action :authenticate_user!
    
    before_action :set_event, only: [:show]
    
    def index
      @upcoming_events = Event.where('start_date >= ?', Date.today).order(:start_date)
      @past_events = Event.where('start_date < ?', Date.today).order(start_date: :desc).limit(10)
    end
    
    def show
      @divisions = @event.divisions.includes(:bouts, athletes: :team).order(:name)
    end
    
    private
    
    def set_event
      @event = Event.find(params[:id])
    end
  end
end