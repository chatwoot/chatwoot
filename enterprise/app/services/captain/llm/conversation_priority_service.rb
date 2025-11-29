class Captain::Llm::ConversationPriorityService < Llm::BaseOpenAiService
  PRIORITY_MAPPING = {
    'urgent' => 3,
    'high' => 2,
    'medium' => 1,
    'low' => 0
  }.freeze

  def initialize(conversation)
    super()
    @conversation = conversation
    @content = build_conversation_content
  end

  def analyze_and_update
    return if @content.blank?

    result = analyze_priority
    update_conversation(result) if result.present?
    result
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API Error in ConversationPriorityService: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "ConversationPriorityService Error: #{e.message}"
    nil
  end

  private

  attr_reader :conversation, :content

  def analyze_priority
    response = @client.chat(parameters: chat_parameters)
    parse_response(response)
  end

  def chat_parameters
    {
      model: @model,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: content }
      ]
    }
  end

  def system_prompt
    <<~PROMPT
      You are a customer support priority analyzer. Your task is to analyze customer conversations and determine their priority level based on urgency, sentiment, and business impact.

      ## Priority Levels
      - **urgent**: Customer is extremely frustrated, threatening to leave, has a critical blocking issue, or mentions legal/safety concerns
      - **high**: Customer is frustrated, has a significant issue affecting their work, or has been waiting a long time
      - **medium**: Customer has a standard support request with moderate urgency
      - **low**: General inquiry, feature request, or non-urgent question

      ## Analysis Factors
      Consider these factors when determining priority:
      1. **Sentiment**: Is the customer angry, frustrated, neutral, or happy?
      2. **Urgency Keywords**: Look for words like "urgent", "asap", "immediately", "critical", "broken", "not working", "can't access"
      3. **Business Impact**: Is this blocking their work? Are they losing money?
      4. **Wait Time**: Has the customer been waiting long for a response?
      5. **Customer Tone**: Aggressive, impatient, polite, understanding?
      6. **Issue Severity**: Is it a bug, outage, or minor inconvenience?

      ## Response Format
      Always respond with valid JSON in this exact format:
      ```json
      {
        "priority": "urgent|high|medium|low",
        "priority_score": 0-100,
        "factors": {
          "sentiment": "description of customer sentiment",
          "urgency_keywords": ["list", "of", "detected", "keywords"],
          "business_impact": "description of business impact",
          "issue_type": "bug|outage|question|feature_request|complaint|other",
          "reasoning": "brief explanation of why this priority was assigned"
        }
      }
      ```

      Priority score guidelines:
      - urgent: 75-100
      - high: 50-74
      - medium: 25-49
      - low: 0-24
    PROMPT
  end

  def build_conversation_content
    messages = conversation.messages
                           .where(message_type: [:incoming, :outgoing])
                           .where(private: false)
                           .order(created_at: :asc)
                           .limit(20)

    return '' if messages.empty?

    text = "Conversation ID: ##{conversation.display_id}\n"
    text += "Channel: #{conversation.inbox.channel_type}\n"
    text += "Status: #{conversation.status}\n"
    text += "Waiting Since: #{conversation.waiting_since&.iso8601 || 'N/A'}\n"
    text += "Created At: #{conversation.created_at.iso8601}\n\n"
    text += "Messages:\n"

    messages.each do |message|
      sender = message.message_type == 'incoming' ? 'Customer' : 'Agent'
      text += "#{sender}: #{message.content}\n"
    end

    text
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return nil if content.blank?

    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse priority response: #{e.message}"
    nil
  end

  def update_conversation(result)
    priority = result['priority']
    priority_score = result['priority_score'].to_f
    factors = result['factors'] || {}

    # Map priority string to enum value
    priority_level = PRIORITY_MAPPING[priority] || 0

    conversation.update!(
      priority: priority,
      priority_score: priority_score,
      priority_level: priority_level,
      priority_factors: factors
    )

    Rails.logger.info(
      "[ConversationPriorityService] Updated conversation ##{conversation.display_id} " \
      "priority to #{priority} (score: #{priority_score})"
    )
  end
end

