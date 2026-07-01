# frozen_string_literal: true

USAGE = <<~USAGE
  Usage:
    bundle exec rails runner script/conversation_message_lock.rb ACCOUNT_ID CONVERSATION_DISPLAY_ID lock "reason"
    bundle exec rails runner script/conversation_message_lock.rb ACCOUNT_ID CONVERSATION_DISPLAY_ID unlock
USAGE

account_id, conversation_display_id, action, reason = ARGV

abort USAGE if account_id.blank? || conversation_display_id.blank? || action.blank?

conversation = Account.find(account_id).conversations.find_by!(display_id: conversation_display_id)

case action
when 'lock'
  conversation.lock_message_creation!(reason: reason)
  puts "Locked message creation for conversation #{conversation.display_id}"
when 'unlock'
  conversation.unlock_message_creation!
  puts "Unlocked message creation for conversation #{conversation.display_id}"
else
  abort USAGE
end
