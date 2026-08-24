# frozen_string_literal: true

# [whisker] Listens for incoming messages and triggers AI auto-reply
# when the inbox has ai_auto_reply enabled and no agents are available.
class AiAutoReplyListener < BaseListener
  include Singleton

  def message_created(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation

    AiAutoReplyService.new(
      account: account,
      conversation: conversation,
      message: message
    ).perform
  end
end
