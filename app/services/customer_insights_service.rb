# Service to generate comprehensive customer insights
# Provides sentiment trends, CSAT history, engagement patterns, and conversation metrics

class CustomerInsightsService
  def initialize(contact)
    @contact = contact
    @account = contact.account
  end

  def generate_insights
    {
      sentiment_analysis: sentiment_trends,
      csat_metrics: csat_history,
      engagement_metrics: engagement_patterns,
      conversation_stats: conversation_statistics,
      response_time_metrics: response_time_analysis,
      activity_timeline: recent_activity_timeline
    }
  end

  private

  def sentiment_trends
    # Analyze sentiment from messages over time
    messages = @contact.messages.incoming.where.not(sentiment: nil).order(created_at: :desc).limit(50)

    return { available: false } if messages.empty?

    sentiments_by_date = messages.group_by { |m| m.created_at.to_date }
                                 .transform_values do |msgs|
      sentiment_counts = msgs.group_by { |m| m.sentiment['label'] }.transform_values(&:count)
      {
        positive: sentiment_counts['positive'] || 0,
        neutral: sentiment_counts['neutral'] || 0,
        negative: sentiment_counts['negative'] || 0,
        total: msgs.count
      }
    end

    # Calculate overall sentiment distribution
    all_sentiments = messages.map { |m| m.sentiment['label'] }.compact
    sentiment_distribution = all_sentiments.tally

    {
      available: true,
      trends: sentiments_by_date.sort.last(30).reverse.to_h,
      overall_distribution: {
        positive: sentiment_distribution['positive'] || 0,
        neutral: sentiment_distribution['neutral'] || 0,
        negative: sentiment_distribution['negative'] || 0
      },
      recent_sentiment: messages.first&.sentiment&.dig('label') || 'unknown'
    }
  end

  def csat_history
    # Get CSAT survey responses for this contact
    responses = @contact.csat_survey_responses.order(created_at: :desc).limit(20)

    return { available: false } if responses.empty?

    ratings_over_time = responses.map do |response|
      {
        date: response.created_at.to_date,
        rating: response.rating,
        feedback: response.feedback_message
      }
    end

    avg_rating = responses.average(:rating).to_f.round(2)

    {
      available: true,
      average_rating: avg_rating,
      total_responses: responses.count,
      ratings_over_time: ratings_over_time,
      trend: calculate_csat_trend(responses)
    }
  end

  def engagement_patterns
    conversations = @contact.conversations.order(created_at: :desc).limit(100)

    return { available: false } if conversations.empty?

    # Calculate engagement metrics
    total_conversations = conversations.count
    open_conversations = conversations.open.count
    resolved_conversations = conversations.resolved.count

    # Average messages per conversation
    avg_messages = conversations.joins(:messages)
                                .group('conversations.id')
                                .count
                                .values
                                .sum.to_f / total_conversations

    # Response rate (conversations where contact replied)
    conversations_with_replies = conversations.joins(:messages)
                                              .where(messages: { message_type: 0 })
                                              .distinct
                                              .count

    response_rate = (conversations_with_replies.to_f / total_conversations * 100).round(2)

    # Activity by day of week
    activity_by_day = conversations.group_by { |c| c.created_at.strftime('%A') }
                                   .transform_values(&:count)

    {
      available: true,
      total_conversations: total_conversations,
      open_conversations: open_conversations,
      resolved_conversations: resolved_conversations,
      avg_messages_per_conversation: avg_messages.round(2),
      response_rate: response_rate,
      activity_by_day: activity_by_day,
      most_active_day: activity_by_day.max_by { |_k, v| v }&.first
    }
  end

  def conversation_statistics
    conversations = @contact.conversations

    {
      total: conversations.count,
      by_status: {
        open: conversations.open.count,
        resolved: conversations.resolved.count,
        pending: conversations.pending.count,
        snoozed: conversations.snoozed.count
      },
      by_priority: {
        low: conversations.low.count,
        medium: conversations.medium.count,
        high: conversations.high.count,
        urgent: conversations.urgent.count
      },
      first_conversation_date: conversations.minimum(:created_at),
      last_conversation_date: conversations.maximum(:created_at)
    }
  end

  def response_time_analysis
    # Analyze how quickly agents respond to this contact
    conversations = @contact.conversations.where.not(first_reply_created_at: nil).limit(50)

    return { available: false } if conversations.empty?

    response_times = conversations.map do |conv|
      next unless conv.first_reply_created_at && conv.created_at

      (conv.first_reply_created_at - conv.created_at) / 60.0 # in minutes
    end.compact

    return { available: false } if response_times.empty?

    avg_response_time = response_times.sum / response_times.size

    {
      available: true,
      average_first_response_time_minutes: avg_response_time.round(2),
      fastest_response_minutes: response_times.min.round(2),
      slowest_response_minutes: response_times.max.round(2),
      total_analyzed: response_times.size
    }
  end

  def recent_activity_timeline
    # Get recent activities for this contact
    conversations = @contact.conversations.order(last_activity_at: :desc).limit(10)

    timeline = conversations.map do |conv|
      {
        id: conv.display_id,
        type: 'conversation',
        status: conv.status,
        created_at: conv.created_at,
        last_activity_at: conv.last_activity_at,
        message_count: conv.messages.count,
        inbox_name: conv.inbox.name,
        assignee_name: conv.assignee&.name
      }
    end

    {
      available: timeline.any?,
      activities: timeline
    }
  end

  def calculate_csat_trend(responses)
    return 'stable' if responses.count < 2

    recent_avg = responses.limit(5).average(:rating).to_f
    older_avg = responses.offset(5).limit(5).average(:rating).to_f

    return 'stable' if older_avg.zero?

    diff = recent_avg - older_avg

    if diff > 0.5
      'improving'
    elsif diff < -0.5
      'declining'
    else
      'stable'
    end
  end
end
