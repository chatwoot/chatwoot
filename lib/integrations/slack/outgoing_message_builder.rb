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

  def send_message
    @slack_message = slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: message.content,
      username: contact.try(:name),
      thread_ts: conversation.identifier
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
