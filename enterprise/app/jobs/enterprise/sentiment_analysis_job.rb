class Enterprise::SentimentAnalysisJob < ApplicationJob
  queue_as :low

  def perform(message)
    return if message.account.locale != 'en' || !valid_incoming_message?(message)

    save_message_sentiment(message)
  rescue StandardError => e
    Rails.logger.error("Sentiment Analysis Error for message #{message.id}: #{e}")
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
  end

  def save_message_sentiment(message)
    # We are truncating the data here to avoind the OnnxRuntime::Error
    # Indices element out of data bounds, idx=512 must be within the inclusive range [-512,511]
    # While gathering the maningfull node the Array/tensor index is going out of bound

    text = message.content&.truncate(2900)
    return if model.blank?

    sentiment = model.predict(text)
    message.sentiment = sentiment.merge(value: label_val(sentiment))

    message.save!
  end

  # Model initializes OnnxRuntime::Model, with given file for inference session and to create the tensor
  def model
    model_file = save_and_open_sentiment_file

    return if File.empty?(model_file)

    Informers::SentimentAnalysis.new(model_file)
  end

  def label_val(sentiment)
    sentiment[:label] == 'positive' ? 1 : -1
  end

  def valid_incoming_message?(message)
    message.incoming? && message.content.present? && !message.private?
  end

  # returns the sentiment file from vendor folder else download it to the path from AWS-S3
  def save_and_open_sentiment_file
    model_path = ENV.fetch('SENTIMENT_FILE_PATH', nil)

    sentiment_file = Rails.root.join('vendor/db/sentiment-analysis.onnx')

    return sentiment_file if File.exist?(sentiment_file)

    source_file = Down.download(model_path) # Download file from AWS-S3
    File.rename(source_file, sentiment_file) # Change the file path

    sentiment_file
  end
end
