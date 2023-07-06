module SentimentAnalysisHelper
  extend ActiveSupport::Concern

  def opening_sentiments
    records = incoming_messages.first(average_message_count)
    average_sentiment(records)
  end

  def closing_sentiments
    records = incoming_messages.last(average_message_count)
    average_sentiment(records)
  end

  def average_sentiment(records)
    {
      label: average_sentiment_label(records),
      score: average_sentiment_score(records)
    }
  end

  private

  def average_sentiment_label(records)
    value = records.pluck(:sentiment).sum { |a| a['value'].to_i }
    value.negative? ? 'negative' : 'positive'
  end

  def average_sentiment_score(records)
    total = records.pluck(:sentiment).sum { |a| a['score'].to_f }
    total / average_message_count
  end

  def average_message_count
    incoming_messages.count >= 10 ? 5 : ((incoming_messages.count / 2) - 1)
  end

  def incoming_messages
    messages.incoming.where(private: false)
  end
end
