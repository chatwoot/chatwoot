class Messages::DetectSentimentJob < ApplicationJob
  queue_as :low

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return if message.blank?
    return unless message.account.feature_enabled?('sentiment_analysis')
    return unless message.incoming?
    return if message.content.blank?

    Captain::Llm::SentimentAnalysisService.new(message).perform
  end
end
