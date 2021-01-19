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
    # slack wouldn't be an ideal interface to reply to tweets, hence disabling that case
    return false if channel.is_a?(Channel::TwitterProfile) && conversation.additional_attributes['type'] == 'tweet'

    true
  end

  def perform_reply
    send_message

    return unless @slack_message

    update_reference_id
    update_external_source_id_slack
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
    @slack_message = slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: message_content,
      username: sender_name(message.sender),
      thread_ts: conversation.identifier,
      icon_url: avatar_url(message.sender)
    )
  rescue Slack::Web::Api::Errors::AccountInactive => e
    Rails.logger.info e
    hook.authorization_error!
    hook.disable if hook.enabled?
  end

  def sender_name(sender)
    sender.try(:name) ? "#{sender_type(sender)}: #{sender.try(:name)}" : sender_type(sender)
  end

  def sender_type(sender)
    sender.instance_of?(Contact) ? 'Contact' : 'Agent'
  end

  def update_reference_id
    return if conversation.identifier

    conversation.update!(identifier: @slack_message['ts'])
  end

  def update_external_source_id_slack
    return unless @slack_message['message']

    message.update!(external_source_id_slack: "cw-origin-#{@slack_message['message']['ts']}")
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end
end
