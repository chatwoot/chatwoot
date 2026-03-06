class Captain::FollowUpService < Captain::BaseTaskService
  pattr_initialize [:account!, :follow_up_context!, :user_message!, { conversation_display_id: nil }]

  ALLOWED_EVENT_NAMES = %w[
    professional
    casual
    friendly
    confident
    straightforward
    fix_spelling_grammar
    improve
    summarize
    reply_suggestion
    label_suggestion
  ].freeze

  def perform
    return { error: 'Follow-up context missing', error_code: 400 } unless valid_follow_up_context?

    # Build context-aware system prompt
    system_prompt = build_follow_up_system_prompt(follow_up_context)

    # Build full message array (convert history from string keys to symbol keys)
    history = follow_up_context['conversation_history'].to_a.map do |msg|
      { role: msg['role'], content: msg['content'] }
    end

    messages = [
      { role: 'system', content: system_prompt },
      { role: 'user', content: follow_up_context['original_context'] },
      { role: 'assistant', content: follow_up_context['last_response'] },
      *history,
      { role: 'user', content: user_message }
    ]

    response = make_api_call(model: GPT_MODEL, messages: messages)
    return response if response[:error]

    response.merge(follow_up_context: update_follow_up_context(user_message, response[:message]))
  end

  private

  def build_follow_up_system_prompt(session_data)
    action_context = describe_previous_action(session_data['event_name'])

    <<~PROMPT
      You just performed a #{action_context} action for a customer support agent.
      Your job now is to help them refine the result based on their feedback.
      Be concise and focused on their specific request.
      Output only the reply, no preamble, tags, or explanation.
    PROMPT
  end

  def describe_previous_action(event_name)
    case event_name
    when 'professional', 'casual', 'friendly', 'confident', 'straightforward'
      "tone rewrite (#{event_name})"
    when 'fix_spelling_grammar'
      'spelling and grammar correction'
    when 'improve'
      'message improvement'
    when 'summarize'
      'conversation summary'
    when 'reply_suggestion'
      'reply suggestion'
    when 'label_suggestion'
      'label suggestion'
    else
      event_name
    end
  end

  def valid_follow_up_context?
    return false unless follow_up_context.is_a?(Hash)
    return false unless ALLOWED_EVENT_NAMES.include?(follow_up_context['event_name'])

    required_keys = %w[event_name original_context last_response]
    required_keys.all? { |key| follow_up_context[key].present? }
  end

  def update_follow_up_context(user_msg, assistant_msg)
    updated_history = follow_up_context['conversation_history'].to_a + [
      { 'role' => 'user', 'content' => user_msg },
      { 'role' => 'assistant', 'content' => assistant_msg }
    ]

    {
      'event_name' => follow_up_context['event_name'],
      'original_context' => follow_up_context['original_context'],
      'last_response' => assistant_msg,
      'conversation_history' => updated_history,
      'channel_type' => follow_up_context['channel_type']
    }
  end

  def instrumentation_metadata
    {
      channel_type: conversation&.inbox&.channel_type || follow_up_context['channel_type']
    }.compact
  end

  def event_name
    'follow_up'
  end
end
