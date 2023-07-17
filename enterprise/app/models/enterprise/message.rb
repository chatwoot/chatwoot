module Enterprise::Message
  def update_message_sentiments
    ::Enterprise::SentimentAnalysisJob.perform_later(self)
  end
end
