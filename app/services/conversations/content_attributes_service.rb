class Conversations::ContentAttributesService
  pattr_initialize [:conversation!]

  def analyze_and_update
    return unless conversation.messages.present?

    attributes = generate_content_attributes
    conversation.update_content_attributes(attributes)
  end

  private

  def generate_content_attributes
    {
      message_count: calculate_message_count,
      response_times: calculate_response_times,
      sentiment: analyze_sentiment,
      topics: extract_topics,
      language: detect_language,
      complexity: calculate_complexity,
      engagement_metrics: calculate_engagement_metrics,
      conversation_summary: generate_conversation_summary,
      key_phrases: extract_key_phrases,
      resolution_status: determine_resolution_status
    }
  end

  def calculate_message_count
    {
      total: conversation.messages.count,
      user: conversation.messages.incoming.count,
      agent: conversation.messages.outgoing.count
    }
  end

  def calculate_response_times
    response_times = []
    
    incoming_messages = conversation.messages.incoming.order(created_at: :asc)
    outgoing_messages = conversation.messages.outgoing.order(created_at: :asc)
    
    incoming_messages.each do |incoming|
      # Find the next outgoing message after this incoming message
      next_response = outgoing_messages.where('created_at > ?', incoming.created_at).first
      
      if next_response
        response_time = (next_response.created_at - incoming.created_at).to_i
        response_times << response_time
      end
    end
    
    return {
      average: response_times.empty? ? nil : (response_times.sum / response_times.size),
      min: response_times.min,
      max: response_times.max,
      total: response_times.sum
    }
  end

  def analyze_sentiment
    # This is a simple placeholder sentiment analysis
    # In a real implementation, you would use a proper NLP service
    
    positive_words = %w[good great excellent amazing awesome thank thanks happy appreciate resolved solved fixed]
    negative_words = %w[bad poor terrible awful unhappy angry issue problem bug wrong broken]
    
    content = conversation.messages.pluck(:content).join(' ').downcase
    
    positive_count = 0
    negative_count = 0
    
    positive_words.each do |word|
      positive_count += content.scan(/\b#{word}\b/).size
    end
    
    negative_words.each do |word|
      negative_count += content.scan(/\b#{word}\b/).size
    end
    
    sentiment_score = positive_count - negative_count
    
    if sentiment_score > 2
      'very_positive'
    elsif sentiment_score > 0
      'positive'
    elsif sentiment_score < -2
      'very_negative'
    elsif sentiment_score < 0
      'negative'
    else
      'neutral'
    end
  end

  def extract_topics
    # This is a simple placeholder topic extraction
    # In a real implementation, you would use a proper NLP service
    
    topic_keywords = {
      'billing': %w[bill payment invoice charge subscription cost price refund],
      'technical_support': %w[error bug issue problem broken fix crash not_working],
      'product_question': %w[how work feature functionality use using guide],
      'feedback': %w[suggest suggestion recommend improvement better],
      'account': %w[login password sign_in account profile register],
      'shipping': %w[delivery ship shipping track package order arrival]
    }
    
    content = conversation.messages.pluck(:content).join(' ').downcase
    detected_topics = []
    
    topic_keywords.each do |topic, keywords|
      keywords.each do |keyword|
        if content.include?(keyword)
          detected_topics << topic.to_s
          break
        end
      end
    end
    
    detected_topics.uniq
  end

  def detect_language
    # Simple language detection based on the first message
    # In a real implementation, you would use a proper language detection service
    
    first_message = conversation.messages.first&.content
    return 'unknown' unless first_message
    
    case first_message
    when /[áéíóúñ¿¡]/
      'spanish'
    when /[àâçéèêëîïôùûü]/
      'french'
    when /[äöüß]/
      'german'
    when /[你好谢谢再见]/
      'chinese'
    when /[こんにちはありがとうさようなら]/
      'japanese'
    else
      'english'
    end
  end

  def calculate_complexity
    # Enhanced complexity calculation based on message length, vocabulary, and conversation flow
    message_texts = conversation.messages.pluck(:content)
    return 0 if message_texts.empty?
    
    # Calculate average message length
    avg_length = message_texts.sum(&:length) / message_texts.size
    
    # Calculate unique vocabulary size
    unique_words = message_texts.join(' ').downcase.scan(/\b[a-z]+\b/).uniq.size
    
    # Calculate conversation back-and-forth complexity
    conversation_turns = [conversation.messages.incoming.count, conversation.messages.outgoing.count].min
    
    # Normalize to a 0-1 scale for each metric
    length_score = [avg_length / 150.0, 1.0].min
    vocab_score = [unique_words / 150.0, 1.0].min
    turns_score = [conversation_turns / 10.0, 1.0].min
    
    # Combine scores with weights
    complexity_score = (length_score * 0.3) + (vocab_score * 0.4) + (turns_score * 0.3)
    
    # Return a value between 0-1
    complexity_score.round(2)
  end

  def calculate_engagement_metrics
    # Calculate engagement metrics based on conversation patterns
    messages = conversation.messages
    
    # Time from first to last message
    first_message = messages.order(created_at: :asc).first
    last_message = messages.order(created_at: :asc).last
    
    duration = last_message.created_at - first_message.created_at
    
    # Calculate average time between messages
    message_times = messages.order(created_at: :asc).pluck(:created_at)
    time_between_messages = []
    
    (1...message_times.size).each do |i|
      time_between_messages << (message_times[i] - message_times[i-1]).to_i
    end
    
    avg_time_between = time_between_messages.empty? ? 0 : time_between_messages.sum / time_between_messages.size
    
    # Calculate user engagement score based on response patterns
    user_messages = messages.incoming.count
    agent_messages = messages.outgoing.count
    
    engagement_score = if user_messages > 0 && agent_messages > 0
                         [user_messages.to_f / agent_messages, 1.0].min * 0.5 + 0.5
                       else
                         0.0
                       end
    
    {
      duration_seconds: duration.to_i,
      avg_time_between_messages: avg_time_between,
      user_messages: user_messages,
      agent_messages: agent_messages,
      engagement_score: engagement_score.round(2)
    }
  end

  def generate_conversation_summary
    # Generate a simple summary based on first and last messages
    first_message = conversation.messages.order(created_at: :asc).first&.content
    last_message = conversation.messages.order(created_at: :asc).last&.content
    
    return "No messages" unless first_message
    
    topics = extract_topics
    topic_text = topics.any? ? "about #{topics.join(', ')}" : ""
    
    "Conversation #{topic_text} starting with '#{first_message.to_s.truncate(50)}'"
  end

  def extract_key_phrases
    # Simple key phrase extraction
    # In a real implementation, you would use a proper NLP service
    
    all_content = conversation.messages.pluck(:content).join(' ')
    words = all_content.downcase.scan(/\b[a-z]{4,}\b/).tally
    
    # Filter out common words
    common_words = %w[this that with have from what when where there their they your would about should could which]
    
    words.delete_if { |word, _| common_words.include?(word) }
    
    # Return top 5 most frequent words as key phrases
    words.sort_by { |_, count| -count }.first(5).map { |word, _| word }
  end

  def determine_resolution_status
    # Determine if the conversation appears resolved based on content
    last_messages = conversation.messages.order(created_at: :desc).limit(3)
    
    # Check if conversation is formally resolved
    return 'resolved' if conversation.resolved?
    
    # Check for resolution indicators in the last few messages
    resolution_phrases = ['thank you', 'thanks', 'resolved', 'fixed', 'solved', 'works now', 'working now', 'great']
    
    last_messages.each do |message|
      content = message.content.to_s.downcase
      if message.incoming? && resolution_phrases.any? { |phrase| content.include?(phrase) }
        return 'likely_resolved'
      end
    end
    
    # Check for unresolved indicators
    unresolved_phrases = ['still not working', 'still broken', 'not fixed', 'same issue', 'same problem']
    
    last_messages.each do |message|
      content = message.content.to_s.downcase
      if message.incoming? && unresolved_phrases.any? { |phrase| content.include?(phrase) }
        return 'likely_unresolved'
      end
    end
    
    'unknown'
  end
end 