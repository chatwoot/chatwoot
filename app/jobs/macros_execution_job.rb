class MacrosExecutionJob < ApplicationJob
  queue_as :medium

  def perform(macro, conversation_id:)
    account = macro.account
    conversation = account.conversations.find_by(display_id: conversation_id)

    ::Macros::ExecutionService.new(macro, account, conversation).perform if conversation.present?
  end
end
