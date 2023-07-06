class Messages::SentimentAnalysisJob < ApplicationJob
  queue_as :default

  def perform(message)
    return if message.account.locale != 'en'
    return if !message.incoming? || message.private?

    # We are truncating the data here to avoind the OnnxRuntime::Error
    # Indices element out of data bounds, idx=512 must be within the inclusive range [-512,511]
    # While gathering the maningfull node the Array/tensor index is going out of bound
    text = message.content&.truncate(2900)
    sentiment = model.predict(text)
    save_message_sentiment(message, sentiment)
  rescue StandardError => e
    Rails.logger.error("Sentiment Analysis Error for message #{message.id}: #{e}")
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
  end

  def save_message_sentiment(message, sentiment)
    message.sentiment = sentiment
    message.save!
  end

  # Model initializes OnnxRuntime::Model, with given file for inference session and to create the tensor
  def model
    model_path = ENV.fetch('SENTIMENT_FILE_PATH', nil)
    Informers::SentimentAnalysis.new(model_path)
  end
end
