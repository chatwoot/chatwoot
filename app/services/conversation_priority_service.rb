# Service to calculate and update conversation priority scores
# Priority is calculated based on multiple factors:
# - Sentiment analysis from messages
# - SLA breach risk
# - Customer value/tier
# - Urgency keywords
# - Time since last response
# - CSAT history

class ConversationPriorityService
  URGENCY_KEYWORDS = [
    'urgent', 'emergency', 'critical', 'asap', 'immediately', 'broken', 'down', 'not working', 'error', 'failed', 'angry', 'frustrated', 'disappointed', 'terrible', 'refund', 'cancel', 'unsubscribe', 'complaint'
  ].freeze

  SENTIMENT_WEIGHT = 0.25
  SLA_WEIGHT = 0.30
  URGENCY_WEIGHT = 0.20
  TIME_WEIGHT = 0.15
  CUSTOMER_VALUE_WEIGHT = 0.10

  def initialize(conversation)
    @conversation = conversation
    @factors = {}
  end

  def calculate_and_update!
    score = calculate_priority_score
    level = determine_priority_level(score)

    @conversation.update!(
      priority_score: score,
      priority_level: level,
      priority_factors: @factors
    )

    score
  end

  def self.recalculate_all_open_conversations(account)
    account.conversations.open.find_each do |conversation|
      new(conversation).calculate_and_update!
    rescue StandardError => e
      Rails.logger.error("Failed to calculate priority for conversation #{conversation.id}: #{e.message}")
    end
  end

  private

  def calculate_priority_score
    score = 0.0

    score += sentiment_score * SENTIMENT_WEIGHT
    score += sla_score * SLA_WEIGHT
    score += urgency_score * URGENCY_WEIGHT
    score += time_score * TIME_WEIGHT
    score += customer_value_score * CUSTOMER_VALUE_WEIGHT

    # Normalize to 0-100 scale
    (score * 100).round(2)
  end

  def sentiment_score
    # Analyze sentiment from recent messages
    recent_messages = @conversation.messages.incoming.last(5)
    return 0.5 if recent_messages.empty?

    sentiments = recent_messages.map do |msg|
      sentiment_data = msg.sentiment || {}
      # If sentiment is negative, increase priority
      case sentiment_data['label']
      when 'negative'
        1.0
      when 'neutral'
        0.5
      when 'positive'
        0.2
      else
        0.5
      end
    end

    avg_sentiment = sentiments.sum / sentiments.size.to_f
    @factors[:sentiment] = { score: avg_sentiment, label: 'Sentiment Analysis' }
    avg_sentiment
  end

  def sla_score
    # Check if conversation is at risk of SLA breach
    return 0.3 unless @conversation.sla_policy_id

    applied_sla = @conversation.applied_sla
    return 0.3 unless applied_sla

    # If SLA is already missed, high priority
    if applied_sla.sla_status == 'missed'
      @factors[:sla] = { score: 1.0, label: 'SLA Missed' }
      return 1.0
    end

    # Calculate time until SLA breach
    if @conversation.waiting_since.present?
      time_elapsed = Time.current - @conversation.waiting_since
      sla_threshold = @conversation.sla_policy&.first_response_time_threshold || 3600

      ratio = time_elapsed / sla_threshold.to_f
      score = [ratio, 1.0].min

      @factors[:sla] = { score: score, label: 'SLA Risk', ratio: ratio.round(2) }
      return score
    end

    @factors[:sla] = { score: 0.3, label: 'No SLA Risk' }
    0.3
  end

  def urgency_score
    # Check for urgency keywords in recent messages
    recent_messages = @conversation.messages.incoming.last(3)
    return 0.3 if recent_messages.empty?

    content = recent_messages.map(&:content).join(' ').downcase

    urgency_count = URGENCY_KEYWORDS.count { |keyword| content.include?(keyword) }
    score = [urgency_count * 0.3, 1.0].min

    @factors[:urgency] = { score: score, keywords_found: urgency_count }
    score
  end

  def time_score
    # Priority increases with time since last activity
    return 0.5 unless @conversation.last_activity_at

    hours_since_activity = (Time.current - @conversation.last_activity_at) / 1.hour

    # Score increases logarithmically with time
    score = if hours_since_activity < 1
              0.2
            elsif hours_since_activity < 4
              0.4
            elsif hours_since_activity < 12
              0.6
            elsif hours_since_activity < 24
              0.8
            else
              1.0
            end

    @factors[:time] = { score: score, hours: hours_since_activity.round(1) }
    score
  end

  def customer_value_score
    # Check customer attributes for VIP status or high value indicators
    contact = @conversation.contact
    return 0.3 unless contact

    score = 0.3

    # Check custom attributes for VIP or tier indicators
    custom_attrs = contact.custom_attributes || {}

    if custom_attrs['vip'] == true || custom_attrs['tier']&.downcase == 'premium'
      score = 1.0
    elsif custom_attrs['tier']&.downcase == 'gold'
      score = 0.8
    elsif custom_attrs['tier']&.downcase == 'silver'
      score = 0.6
    end

    # Check CSAT history - customers with low satisfaction get higher priority
    if contact.csat_survey_responses.exists?
      avg_rating = contact.csat_survey_responses.average(:rating).to_f
      score = [score + 0.3, 1.0].min if avg_rating < 3
    end

    @factors[:customer_value] = { score: score, label: 'Customer Value' }
    score
  end

  def determine_priority_level(score)
    case score
    when 0...25
      :normal
    when 25...50
      :elevated
    when 50...75
      :high_priority
    else
      :critical
    end
  end
end
