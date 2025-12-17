class Captain::EditorService < Captain::BaseEditorService
  def fix_spelling_grammar_message
    call_llm_with_prompt(fix_spelling_grammar_prompt)
  end

  def confident_message
    call_llm_with_prompt(tone_rewrite_prompt('confident'))
  end

  def straightforward_message
    call_llm_with_prompt(tone_rewrite_prompt('straightforward'))
  end

  def casual_message
    call_llm_with_prompt(tone_rewrite_prompt('casual'))
  end

  def friendly_message
    call_llm_with_prompt(tone_rewrite_prompt('friendly'))
  end

  def professional_message
    call_llm_with_prompt(tone_rewrite_prompt('professional'))
  end

  def improve_message
    template = prompt_from_file('improve')

    system_prompt = render_liquid_template(template, {
                                             'conversation_context' => conversation.to_llm_text(include_contact_details: true),
                                             'draft_message' => event['data']['content']
                                           })

    call_llm_with_prompt(system_prompt, event['data']['content'])
  end

  def summarize_message
    make_api_call(summarize_body)
  end

  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  def label_suggestion_message
    payload = label_suggestion_body
    return nil if payload.blank?

    response = make_api_call(label_suggestion_body)
    return response if response[:error].present?

    # LLMs are not deterministic - sometimes response includes "Labels:" prefix
    # TODO: Fix with better prompt
    { message: response[:message] ? response[:message].gsub(/^(label|labels):/i, '') : '' }
  end

  private

  def api_key
    @api_key ||= openai_hook&.settings&.dig('api_key') || system_api_key
  end

  def openai_hook
    @openai_hook ||= account.hooks.find_by(app_id: 'openai', status: 'enabled')
  end

  def system_api_key
    @system_api_key ||= InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  def call_llm_with_prompt(system_content, user_content = event['data']['content'])
    body = {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_content },
        { role: 'user', content: user_content }
      ]
    }.to_json
    make_api_call(body)
  end

  def prompt_from_file(file_name)
    Rails.root.join('lib/integrations/openai/openai_prompts', "#{file_name}.liquid").read
  end

  def render_liquid_template(template_content, variables = {})
    Liquid::Template.parse(template_content).render(variables)
  end

  def tone_rewrite_prompt(tone)
    template = prompt_from_file('tone_rewrite')
    render_liquid_template(template, 'tone' => tone)
  end

  def fix_spelling_grammar_prompt
    prompt_from_file('fix_spelling_grammar')
  end

  def summarize_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('summary') },
        { role: 'user', content: conversation_messages }
      ]
    }.to_json
  end

  def reply_suggestion_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('reply') }
      ].concat(conversation_messages(in_array_format: true))
    }.to_json
  end

  def label_suggestion_body
    # TODO: Enable based on separate model and settings source
    # Future: Different model for label suggestion
    # Future: Settings-based feature gating
    # For now: Enabled by default when API key available

    content = labels_with_messages
    return value_from_cache if content.blank?

    {
      model: GPT_MODEL, # TODO: Use separate model for label suggestion
      messages: [
        {
          role: 'system',
          content: prompt_from_file('label_suggestion')
        },
        { role: 'user', content: content }
      ]
    }.to_json
  end

  def labels_with_messages
    return nil unless valid_conversation?(conversation)

    labels = account.labels.pluck(:title).join(', ')
    character_count = labels.length

    messages = init_messages_body(false)
    add_messages_until_token_limit(conversation, messages, false, character_count)

    return nil if messages.blank? || labels.blank?

    "Messages:\n#{messages}\nLabels:\n#{labels}"
  end

  def valid_conversation?(conversation)
    return false if conversation.nil?
    return false if conversation.messages.incoming.count < 3
    return false if conversation.messages.count > 100
    return false if conversation.messages.count > 20 && !conversation.messages.last.incoming?

    true
  end

  def conversation_messages(in_array_format: false)
    messages = init_messages_body(in_array_format)
    add_messages_until_token_limit(conversation, messages, in_array_format)
  end

  def init_messages_body(in_array_format)
    in_array_format ? [] : ''
  end

  def add_messages_until_token_limit(conversation, messages, in_array_format, start_from = 0)
    character_count = start_from
    conversation.messages
                .where(message_type: [:incoming, :outgoing])
                .where(private: false)
                .reorder('id desc')
                .each do |message|
      character_count, message_added = add_message_if_within_limit(character_count, message, messages, in_array_format)
      break unless message_added
    end
    messages
  end

  def add_message_if_within_limit(character_count, message, messages, in_array_format)
    content = message.content_for_llm
    if valid_message?(content, character_count)
      add_message_to_list(message, messages, in_array_format, content)
      character_count += content.length
      [character_count, true]
    else
      [character_count, false]
    end
  end

  def valid_message?(content, character_count)
    content.present? && character_count + content.length <= TOKEN_LIMIT
  end

  def add_message_to_list(message, messages, in_array_format, content)
    formatted_message = format_message(message, in_array_format, content)
    messages.prepend(formatted_message)
  end

  def format_message(message, in_array_format, content)
    in_array_format ? format_message_in_array(message, content) : format_message_in_string(message, content)
  end

  def format_message_in_array(message, content)
    { role: (message.incoming? ? 'user' : 'assistant'), content: content }
  end

  def format_message_in_string(message, content)
    sender_type = message.incoming? ? 'Customer' : 'Agent'
    "#{sender_type} #{message.sender&.name} : #{content}\n"
  end
end
