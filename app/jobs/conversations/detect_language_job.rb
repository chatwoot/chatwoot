class Conversations::DetectLanguageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    @message = Message.find(message_id)

    return if hook.blank?

    text = @message.content[0...1500]

    response = client.detect_language(
      content: text,
      parent: "projects/#{hook.settings['project_id']}"
    )

    update_conversation(response)
  end

  private

  def update_conversation(response)
    conversation = @message.conversation
    conversation_language = response.languages.first.language_code
    additional_attributes = conversation.additional_attributes.merge({ conversation_language: conversation_language })

    conversation.update!(additional_attributes: additional_attributes)

    event = Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation })

    AutomationRuleListener.instance.conversation_updated(event)
  end

  def hook
    @hook ||= @message.account.hooks.find_by(app_id: 'google_translate')
  end

  def client
    @client ||= Google::Cloud::Translate.translation_service do |config|
      config.credentials = hook.settings['credentials']
    end
  end
end
