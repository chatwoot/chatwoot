class Conversations::DetectLanguageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    @message = Message.find(message_id)

    return unless @message.account.enable_language_detection?

    return unless @message.content.size < 1500

    response = client.detect_language(
      content: @message.content,
      parent: "projects/#{hook.settings['project_id']}"
    )
    update_conversation(response)
  end

  private

  def update_conversation(response)
    conversation = @message.conversation
    current_language = response.languages.first.language_code
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(status: :resolved) unless current_language == 'en'
    # rubocop:enable Rails/SkipsModelValidations
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
