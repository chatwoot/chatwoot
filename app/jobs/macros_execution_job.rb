class MacrosExecutionJob < ApplicationJob
  queue_as :medium

  def perform(macro, conversation_ids:, user:)
    account = macro.account
    conversations = account.conversations.where(display_id: conversation_ids.to_a)
    account_user = account.account_users.find_by(user_id: user.id)

    return if conversations.blank?

    if account_user.blank?
      log_skipped_execution(macro, conversations, user, reason: 'missing_account_membership')
      return
    end

    user_context = { user: user, account: account, account_user: account_user }

    conversations.each do |conversation|
      unless ConversationPolicy.new(user_context, conversation).show?
        log_skipped_execution(macro, [conversation], user, reason: 'conversation_access_denied')
        next
      end

      ::Macros::ExecutionService.new(macro, conversation, user).perform
    end
  end

  private

  def log_skipped_execution(macro, conversations, user, reason:)
    Rails.logger.info({
      event: 'macro_execution_skipped',
      reason: reason,
      account_id: macro.account_id,
      macro_id: macro.id,
      user_id: user.id,
      conversation_ids: conversations.pluck(:id),
      conversation_display_ids: conversations.pluck(:display_id)
    }.to_json)
  end
end
