# class BoutSwapService
#   VALID_SLOTS = %w[a b].freeze
  
#   def initialize(params)
#     @source = params[:source]
#     @target = params[:target]
#   end
  
#   def execute
#     return error("Invalid parameters") unless valid_params?
    
#     source_bout = Bout.find_by(id: @source[:bout_id])
#     target_bout = Bout.find_by(id: @target[:bout_id])
    
#     return error("Bout not found") unless source_bout && target_bout
    
#     perform_swap(source_bout, target_bout)
    
#     { success: true }
#   rescue ActiveRecord::RecordInvalid => e
#     error("Swap failed: #{e.record.errors.full_messages.join(', ')}")
#   rescue StandardError => e
#     Rails.logger.error("Unexpected swap error: #{e.message}")
#     error("An unexpected error occurred")
#   end
  
#   private
  
#   def valid_params?
#     @source && @target &&
#       VALID_SLOTS.include?(@source[:slot]) &&
#       VALID_SLOTS.include?(@target[:slot])
#   end
  
#   def perform_swap(source_bout, target_bout)
#     source_athlete_id = @source[:athlete_id].presence
#     target_athlete_id = @target[:athlete_id].presence
    
#     ActiveRecord::Base.transaction do
#       # Update source bout slot with target's athlete
#       update_bout_slot(source_bout, @source[:slot], target_athlete_id)
      
#       # Update target bout slot with source's athlete
#       update_bout_slot(target_bout, @target[:slot], source_athlete_id)
      
#       # Clear winners if athletes changed
#       clear_winner_if_needed(source_bout)
#       clear_winner_if_needed(target_bout)
#     end
#   end
  
#   def update_bout_slot(bout, slot, athlete_id)
#     attribute = slot == "a" ? :athlete_a_id : :athlete_b_id
#     bout.update!(attribute => athlete_id)
#   end
  
#   def clear_winner_if_needed(bout)
#     bout.update!(winner_id: nil) if bout.winner_id.present?
#   end
  
#   def error(message)
#     { success: false, error: message }
#   end
# end