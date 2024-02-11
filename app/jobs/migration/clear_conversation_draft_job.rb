# Delete migration and spec after 2 consecutive releases.
class Migration::ClearConversationDraftJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    account = Account.find_by(id: 1)

    counter = 0
    account.conversations.each do |convo|
      key = format(Redis::Alfred::CONVERSATION_DRAFT_MESSAGE, conversation_id: convo.id, account_id: account.id)
      convo.clear_draft_message
      counter += 1
      print '.'
    end

    puts "\ncleared_conversation_drafts: #{counter}"
  end
end
