class OttivCompletePastItemsJob < ApplicationJob
  queue_as :low

  def perform
    Rails.logger.info 'OttivCompletePastItemsJob: Starting to auto-complete past items'
    
    completed_count = 0
    
    OttivCalendarItem.active.where('end_at < ? OR (end_at IS NULL AND start_at < ?)', 
                                   1.hour.ago, 1.hour.ago).find_each do |item|
      item.complete!
      completed_count += 1
      Rails.logger.info "OttivCompletePastItemsJob: Completed item #{item.id} - #{item.title}"
    rescue StandardError => e
      Rails.logger.error "OttivCompletePastItemsJob: Error completing item #{item.id}: #{e.message}"
    end
    
    Rails.logger.info "OttivCompletePastItemsJob: Completed #{completed_count} items"
  end
end

