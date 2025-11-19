# class BoutsController < ApplicationController
#   before_action :authenticate_user!
#   before_action :set_bout, only: [:show, :swap_athletes, :set_winner, :create_point_event]
  
#   # GET /bouts/:id
#   def show
#     @point_events = @bout.point_events.includes(:athlete).order(scored_at: :asc)
#   end
  
#   # PATCH /bouts/:id/set_winner
#   def set_winner
#     winner = Athlete.find_by(id: params[:winner_id])
    
#     unless winner && [@bout.athlete_a_id, @bout.athlete_b_id].include?(winner.id)
#       return render json: { error: "Invalid winner" }, status: :unprocessable_entity
#     end
    
#     if @bout.update(winner: winner)
#       advance_winner(@bout)
#       render json: { success: true, winner_id: winner.id }, status: :ok
#     else
#       render json: { errors: @bout.errors.full_messages }, status: :unprocessable_entity
#     end
#   end
  
#   # POST /bouts/:id/create_point_event
#   def create_point_event
#     point_event = @bout.point_events.build(point_event_params)
    
#     if point_event.save
#       render json: { success: true, point_event: point_event }, status: :created
#     else
#       render json: { errors: point_event.errors.full_messages }, status: :unprocessable_entity
#     end
#   end
  
#   # PATCH /bouts/:id/swap_athletes (within same bout)
#   def swap_athletes
#     if @bout.update(bout_params)
#       @bout.update(winner_id: nil) # Clear winner when athletes change
#       head :ok
#     else
#       render json: { errors: @bout.errors.full_messages }, status: :unprocessable_entity
#     end
#   end
  
#   # POST /bouts/swap (between different bouts)
#   def swap
#     result = BoutSwapService.new(swap_params).execute
    
#     if result[:success]
#       head :ok
#     else
#       render json: { error: result[:error] }, status: :unprocessable_entity
#     end
#   end
  
#   private
  
#   def set_bout
#     @bout = Bout.find(params[:id])
#   end
  
#   def bout_params
#     params.permit(:athlete_a_id, :athlete_b_id)
#   end
  
#   def point_event_params
#     params.require(:point_event).permit(:athlete_id, :points, :technique, :scored_at)
#   end
  
#   def swap_params
#     params.permit(
#       source: [:athlete_id, :bout_id, :slot],
#       target: [:athlete_id, :bout_id, :slot]
#     )
#   end
  
#   def advance_winner(bout)
#     return unless bout.next_bout_id.present?
    
#     next_bout = Bout.find_by(id: bout.next_bout_id)
#     return unless next_bout
    
#     if bout.next_slot == "a"
#       next_bout.update(athlete_a: bout.winner, winner_id: nil)
#     elsif bout.next_slot == "b"
#       next_bout.update(athlete_b: bout.winner, winner_id: nil)
#     end
#   end
# end

class BoutsController < ApplicationController
  before_action :require_admin, only: [:swap]
  skip_before_action :verify_authenticity_token, only: [:swap]

  def swap
    source = params[:source]
    target = params[:target]

    unless valid_swap_params?(source, target)
      render json: { error: "Invalid parameters" }, status: :unprocessable_entity
      return
    end

    source_bout = Bout.find_by(id: source[:bout_id])
    target_bout = Bout.find_by(id: target[:bout_id])

    unless source_bout && target_bout
      render json: { error: "Bout not found" }, status: :not_found
      return
    end

    ActiveRecord::Base.transaction do
      swap_athletes(source_bout, target_bout, source, target)
    end

    render json: { 
      success: true, 
      message: "Athletes swapped successfully"
    }, status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Swap error: #{e.message}")
    render json: { error: "An error occurred" }, status: :internal_server_error
  end
  
  def set_winner
    @bout = Bout.find(params[:id])
    winner_id = params[:winner_id]
    
    unless current_user&.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
    
    if winner_id.to_i == @bout.athlete_a_id || winner_id.to_i == @bout.athlete_b_id
      @bout.update!(winner_id: winner_id)
      
      # Advance winner to next round
      result = @bout.division.advance_winner_to_next_round(@bout)
      
      winner = Athlete.find(winner_id)
      
      render json: { 
        success: true, 
        winner_id: winner_id,
        winner_name: winner.fullname,
        next_bout_id: result[:next_bout]&.id,
        next_round: result[:next_bout]&.round
      }, status: :ok
    else
      render json: { error: "Invalid winner" }, status: :unprocessable_entity
    end
  end

  private

  def valid_swap_params?(source, target)
    return false unless source && target
    return false unless source[:bout_id] && source[:slot]
    return false unless target[:bout_id] && target[:slot]
    return false unless ["a", "b"].include?(source[:slot])
    return false unless ["a", "b"].include?(target[:slot])
    true
  end

  def swap_athletes(source_bout, target_bout, source_params, target_params)
    source_slot = source_params[:slot]
    target_slot = target_params[:slot]

    source_athlete_id = source_slot == "a" ? source_bout.athlete_a_id : source_bout.athlete_b_id
    target_athlete_id = target_slot == "a" ? target_bout.athlete_a_id : target_bout.athlete_b_id

    if source_bout.id == target_bout.id
      source_bout.update!(
        athlete_a_id: target_athlete_id,
        athlete_b_id: source_athlete_id
      )
    else
      if source_slot == "a"
        source_bout.update!(athlete_a_id: target_athlete_id)
      else
        source_bout.update!(athlete_b_id: target_athlete_id)
      end

      if target_slot == "a"
        target_bout.update!(athlete_a_id: source_athlete_id)
      else
        target_bout.update!(athlete_b_id: source_athlete_id)
      end
    end
  end

  def require_admin
    unless current_user&.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end