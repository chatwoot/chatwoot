class Integrations::Slack::OutgoingMessageBuilder
  attr_reader :hook, :message

  def initialize(hook, message)
    @hook = hook
    @message = message
  end

  def perform
    send_message
  end

  private

  def conversation
    @conversation ||= message.conversation
  end

  def contact
    @contact ||= conversation.contact
  end

  def send_message
    slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: message.content,
      username: contact.try(:name),
      thread_ts: conversation.reference_id
    )
  end

  def slack_client
    Slack.configure do |config|
      config.token = hook.access_token
    end
    Slack::Web::Client.new
  end
end
