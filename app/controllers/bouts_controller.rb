class BoutsController < ApplicationController
  # before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: :swap
  
  before_action :set_bout, only: [:swap_athletes]
  
  def swap_athletes
    if @bout.update(athlete_a_id: params[:athlete_a_id], athlete_b_id: params[:athlete_b_id])
      head :ok
    else
      render json: { errors: @bout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /bouts/swap
  def swap
    source = params.require(:source).permit(:athlete_id, :bout_id, :slot)
    target = params.require(:target).permit(:athlete_id, :bout_id, :slot)

    # normalize empty strings to nil
    source_athlete_id = source[:athlete_id].presence
    target_athlete_id = target[:athlete_id].presence

    s_bout = Bout.find_by(id: source[:bout_id])
    t_bout = Bout.find_by(id: target[:bout_id])

    return head :bad_request if s_bout.nil? || t_bout.nil?

    # ensure slots are 'a' or 'b'
    unless %w[a b].include?(source[:slot]) && %w[a b].include?(target[:slot])
      return head :bad_request
    end

    ActiveRecord::Base.transaction do
      # update source bout: set its slot to target_athlete_id
      if source[:slot] == "a"
        s_bout.update!(athlete_a_id: target_athlete_id)
      else
        s_bout.update!(athlete_b_id: target_athlete_id)
      end

      # update target bout: set its slot to source_athlete_id
      if target[:slot] == "a"
        t_bout.update!(athlete_a_id: source_athlete_id)
      else
        t_bout.update!(athlete_b_id: source_athlete_id)
      end

      # Clear winners for any bout that had participants changed
      s_bout.update!(winner_id: nil) if s_bout.winner_id.present?
      t_bout.update!(winner_id: nil) if t_bout.winner_id.present?
    end

    head :ok
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Swap failed: #{e.record.errors.full_messages.join(", ")}")
    render plain: "Swap failed: #{e.record.errors.full_messages.join(', ')}", status: :unprocessable_entity
  end
  
  private

  def set_bout
    @bout = Bout.find(params[:id])
  end
  
  
end
