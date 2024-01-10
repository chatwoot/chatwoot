module Enterprise::Message
  def update_message_sentiments
    ::Enterprise::SentimentAnalysisJob.perform_later(self) if ENV.fetch('SENTIMENT_FILE_PATH', nil).present?
  end
end
