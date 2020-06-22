class Integrations::Slack::OutgoingMessageBuilder
  attr_reader :hook, :message

  def self.perform(hook, message)
    new(hook, message).perform
  end

  def initialize(hook, message)
    @hook = hook
    @message = message
  end

  def perform
    return if message.source_id.present?

    send_message
    update_reference_id
  end

  private

  def conversation
    @conversation ||= message.conversation
  end

  def contact
    @contact ||= conversation.contact
  end

  def agent
    @agent ||= message.user
  end

  def message_content
    if conversation.identifier.present?
      message.content
    else
      "*Inbox: #{message.inbox.name}* \n\n #{message.content}"
    end
  end

  def avatar_url(sender)
    sender.try(:avatar_url) || "#{ENV['FRONTEND_URL']}/admin/avatar_square.png"
  end

  def send_message
    sender = message.outgoing? ? agent : contact
    sender_type = sender.class == Contact ? 'Contact' : 'Agent'

    @slack_message = slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: message_content,
      username: "#{sender_type}: #{sender.try(:name)}",
      thread_ts: conversation.identifier,
      icon_url: avatar_url(sender)
    )
  end

  def update_reference_id
    return if conversation.identifier

    conversation.identifier = @slack_message['ts']
    conversation.save!
  end

  def slack_client
    Slack.configure do |config|
      config.token = hook.access_token
    end
    Slack::Web::Client.new
  end
end
