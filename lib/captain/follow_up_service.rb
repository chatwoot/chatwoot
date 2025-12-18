class Captain::FollowUpService < Captain::BaseTaskService
  pattr_initialize [:account!, :session_id!, :user_message!]

  def perform
    session_data = load_session
    return { error: 'Session expired or not found', error_code: 404 } unless session_data

    # Build context-aware system prompt
    system_prompt = build_follow_up_system_prompt(session_data)

    # Build full message array (convert history from string keys to symbol keys)
    history = session_data['conversation_history'].map do |msg|
      { role: msg['role'], content: msg['content'] }
    end

    messages = [
      { role: 'system', content: system_prompt },
      { role: 'user', content: session_data['original_context'] },
      { role: 'assistant', content: session_data['last_response'] },
      *history,
      { role: 'user', content: user_message }
    ]

    response = make_api_call(model: GPT_MODEL, messages: messages)
    return response if response[:error]

    # Update session with new exchange
    update_session(session_data, user_message, response[:message])

    response.merge(session_id: session_id)
  end

  private

  def build_follow_up_system_prompt(session_data)
    action_context = describe_previous_action(session_data['event_name'])

    <<~PROMPT
      You just performed a #{action_context} action for a customer support agent.
      Your job now is to help them refine the result based on their feedback.
      Be concise and focused on their specific request.
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

  def load_session
    cached = Redis::Alfred.get(session_key(session_id))
    return nil unless cached.present?

    JSON.parse(cached)
  rescue JSON::ParserError
    nil
  end

  def update_session(session_data, user_msg, assistant_msg)
    session_data['conversation_history'] << { role: 'user', content: user_msg }
    session_data['conversation_history'] << { role: 'assistant', content: assistant_msg }
    session_data['last_response'] = assistant_msg

    Redis::Alfred.setex(
      session_key(session_id),
      session_data.to_json,
      1.hour.to_i
    )
  end

  def event_name
    'follow_up'
  end
end
