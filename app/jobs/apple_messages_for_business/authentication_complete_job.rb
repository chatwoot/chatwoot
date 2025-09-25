class AppleMessagesForBusiness::AuthenticationCompleteJob < ApplicationJob
  queue_as :default

  def perform(channel_id, auth_session_id, auth_result)
    channel = Channel::AppleMessagesForBusiness.find(channel_id)

    # Update auth session with result
    auth_sessions = channel.auth_sessions || {}
    auth_sessions[auth_session_id] = auth_result.merge(
      'completed_at' => Time.current.iso8601,
      'status' => auth_result['success'] ? 'completed' : 'failed'
    )

    channel.update!(auth_sessions: auth_sessions)

    # Create message to notify about authentication completion
    if auth_result['success']
      create_success_message(channel, auth_result)
    else
      create_error_message(channel, auth_result)
    end

    Rails.logger.info "[AMB Auth] Authentication #{auth_result['success'] ? 'completed' : 'failed'} for channel #{channel_id}"
  end

  private

  def create_success_message(channel, auth_result)
    inbox = channel.inbox
    conversation = inbox.conversations.first # Or find appropriate conversation
    return unless conversation

    # Create a system message about successful authentication
    Message.create!(
      conversation: conversation,
      inbox: inbox,
      account: inbox.account,
      message_type: :incoming,
      content: "Authentication completed successfully for #{auth_result['provider']}",
      sender: conversation.contact
    )
  end

  def create_error_message(channel, auth_result)
    inbox = channel.inbox
    conversation = inbox.conversations.first # Or find appropriate conversation
    return unless conversation

    # Create a system message about failed authentication
    Message.create!(
      conversation: conversation,
      inbox: inbox,
      account: inbox.account,
      message_type: :incoming,
      content: "Authentication failed: #{auth_result['error']}",
      sender: conversation.contact
    )
  end
end