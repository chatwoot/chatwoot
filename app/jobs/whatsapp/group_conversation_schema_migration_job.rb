class Whatsapp::GroupConversationSchemaMigrationJob < ApplicationJob
  queue_as :low

  def perform
    stats = Whatsapp::GroupConversationSchemaMigrationService.new.perform
    Rails.logger.info(
      "[WHATSAPP][GROUP] schema migration bootstrap completed inboxes=#{stats[:inboxes]} skipped=#{stats[:skipped]} " \
      "conversations=#{stats[:conversations]} members=#{stats[:members]}"
    )
  end
end
