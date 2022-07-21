class MacrosExecutionJob < ApplicationJob
  queue_as :medium

  def perform(macro, conversation_ids:, user:)
    account = macro.account
    conversations = account.conversations.where(display_id: conversation_ids.to_a)

    return if conversations.blank?

    conversations.each do |conversation|
      ::Macros::ExecutionService.new(macro, conversation, user).perform
    end
  end
end
