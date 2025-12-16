class Integrations::Openai::ProcessorService < Integrations::LlmBaseService
  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  def summarize_message
    make_api_call(summarize_body)
  end

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

  private

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

  def prompt_from_file(file_name, enterprise: false)
    path = enterprise ? 'enterprise/lib/enterprise/integrations/openai_prompts' : 'lib/integrations/openai/openai_prompts'
    Rails.root.join(path, "#{file_name}.liquid").read
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

  def conversation_messages(in_array_format: false)
    messages = init_messages_body(in_array_format)

    add_messages_until_token_limit(conversation, messages, in_array_format)
  end

  def add_messages_until_token_limit(conversation, messages, in_array_format, start_from = 0)
    character_count = start_from
    conversation.messages.where(message_type: [:incoming, :outgoing]).where(private: false).reorder('id desc').each do |message|
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

  def init_messages_body(in_array_format)
    in_array_format ? [] : ''
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

  def summarize_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: prompt_from_file('summary', enterprise: false) },
        { role: 'user', content: conversation_messages }
      ]
    }.to_json
  end

  def reply_suggestion_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: prompt_from_file('reply', enterprise: false) }
      ].concat(conversation_messages(in_array_format: true))
    }.to_json
  end
end

Integrations::Openai::ProcessorService.prepend_mod_with('Integrations::OpenaiProcessorService')
