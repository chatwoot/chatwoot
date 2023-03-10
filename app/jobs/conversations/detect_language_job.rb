class Conversations::DetectLanguageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    binding.pry
    message = Message.find(message_id)
    conversation = message.conversation

    if message.content.size < 500 && message.account_id == 1
      result = DetectLanguage.simple_detect(message.content)
      conversation.update_columns(status: :resolved) unless result == 'en'
    end
  end
end
