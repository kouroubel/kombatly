class DivisionsController < ApplicationController
  before_action :set_event
  before_action :set_division, only: [:show, :edit, :update, :destroy]
  before_action :require_admin_or_team, only: [:show]
  before_action :require_admin, only: [:new, :create, :edit, :update, :destroy]

  # GET /events/:event_id/divisions/new
  def new
    @division = @event.divisions.new
  end

  # POST /events/:event_id/divisions
  def create
    @division = @event.divisions.new(division_params)

    if @division.save
      redirect_to @event, notice: "Division created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /events/:event_id/divisions/:id/edit
  def edit
  end

  # PATCH/PUT /events/:event_id/divisions/:id
  def update
    if @division.update(division_params)
      redirect_to @event, notice: "Division updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def show
    @event = @division.event
  
    @eligible_athletes = Athlete
      .joins(:team)
      .where(sex: @division.sex, belt: @division.belt)
      .where("weight >= ? AND weight <= ?", @division.min_weight, @division.max_weight)
      .select { |athlete| athlete_age(athlete) >= @division.min_age && athlete_age(athlete) <= @division.max_age }
  end

  # DELETE /events/:event_id/divisions/:id
  def destroy
    @division.destroy
    redirect_to @event, notice: "Division deleted successfully."
  end

  private
  
  def require_admin_or_team
    unless current_user.admin? || current_user.team?
      redirect_to @event, alert: "Not authorized"
    end
  end
  
  def require_admin
    unless current_user.admin?
      redirect_to @event, alert: "Not authorized"
    end
  end


  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_division
    @division = @event.divisions.find(params[:id])
  end
  
  def eligible_athletes
    Athlete
      .where(sex: sex, belt: belt)
      .where("weight >= ? AND weight <= ?", min_weight, max_weight)
      .select { |a| age(a) >= min_age && age(a) <= max_age }
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
      :name,
      :min_age, :max_age,
      :min_weight, :max_weight,
      :belt,
      :sex
    )
  end
end
