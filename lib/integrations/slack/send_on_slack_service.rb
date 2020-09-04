class Integrations::Slack::SendOnSlackService < Base::SendOnChannelService
  pattr_initialize [:message!, :hook!]

  def perform
    # overriding the base class logic since the validations are different in this case.
    # FIXME: for now we will only send messages from widget to slack
    return unless valid_channel_for_slack?
    # we don't want message loop in slack
    return if message.external_source_id_slack.present?
    # we don't want to start slack thread from agent conversation as of now
    return if message.outgoing? && conversation.identifier.blank?

    perform_reply
  end

  private

  def valid_channel_for_slack?
    # slack wouldn't be an idean interface to reply to tweets, hence disabling that case
    return false if channel.is_a?(Channel::TwitterProfile) && conversation.additional_attributes['type'] == 'tweet'

    true
  end

  def perform_reply
    send_message
    update_reference_id
  end

  def message_content
    private_indicator = message.private? ? 'private: ' : ''
    if conversation.identifier.present?
      "#{private_indicator}#{message.content}"
    else
      "*Inbox: #{message.inbox.name} [#{message.inbox.inbox_type}]* \n\n #{message.content}"
    end
  end

  def avatar_url(sender)
    sender.try(:avatar_url) || "#{ENV['FRONTEND_URL']}/admin/avatar_square.png"
  end

  def send_message
    sender = message.sender
    sender_type = sender.class == Contact ? 'Contact' : 'Agent'
    sender_name = sender.try(:name) ? "#{sender_type}: #{sender.try(:name)}" : sender_type

    @slack_message = slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: message_content,
      username: sender_name,
      thread_ts: conversation.identifier,
      icon_url: avatar_url(sender)
    )
  end

  def update_reference_id
    return if conversation.identifier

    conversation.update!(identifier: @slack_message['ts'])
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end
end
