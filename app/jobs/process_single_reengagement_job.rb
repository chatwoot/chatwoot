# frozen_string_literal: true

class ProcessSingleReengagementJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(reengagement_id)
    reengagement = ConversationReengagement.find_by(id: reengagement_id)

    unless reengagement&.status == 'active'
      reengagement&.clear_processing!
      return
    end

    AgentBots::ReengagementService.new(reengagement).execute
  rescue StandardError => e
    Rails.logger.error "ProcessSingleReengagementJob failed for #{reengagement_id}: #{e.message}"
    reengagement&.clear_processing!
  end
end
