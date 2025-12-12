class Integrations::Openai::ProcessorService < Integrations::LlmBaseService
  LANGUAGE_INSTRUCTION = 'Ensure that the reply should be in user language.'.freeze
  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  def summarize_message
    make_api_call(summarize_body)
  end

  def confident_message
    tone_instruction = determine_tone_instruction('confident')
    make_api_call(build_api_call_body(tone_rewrite_prompt(tone_instruction)))
  end

  def fix_spelling_grammar_message
    make_api_call(build_api_call_body('Please fix the spelling and grammar of the following response. ' \
                                      "#{LANGUAGE_INSTRUCTION}"))
  end

  def straightforward_message
    tone_instruction = determine_tone_instruction('straightforward')
    make_api_call(build_api_call_body(tone_rewrite_prompt(tone_instruction)))
  end

  def casual_message
    tone_instruction = determine_tone_instruction('casual')
    make_api_call(build_api_call_body(tone_rewrite_prompt(tone_instruction)))
  end

  def make_friendly_message
    tone_instruction = determine_tone_instruction('friendly')
    make_api_call(build_api_call_body(tone_rewrite_prompt(tone_instruction)))
  end

  def make_formal_message
    tone_instruction = determine_tone_instruction('formal')
    make_api_call(build_api_call_body(tone_rewrite_prompt(tone_instruction)))
  end

  def professional_message
    tone_instruction = determine_tone_instruction('professional')
    make_api_call(build_api_call_body(tone_rewrite_prompt(tone_instruction)))
  end

  def improve_message
    content = event['data']['content']
    selection = event['data']['selection'].presence
    tone = event['data']['tone'].presence

    system_prompt = improve_prompt(selection, tone)
    user_content = selection.present? ? improve_user_content(content, selection) : content

    make_api_call(build_api_call_body(system_prompt, user_content))
  end

  private

  def prompt_from_file(file_name, enterprise: false)
    path = enterprise ? 'enterprise/lib/enterprise/integrations/openai_prompts' : 'lib/integrations/openai/openai_prompts'
    Rails.root.join(path, "#{file_name}.txt").read
  end

  def tone_rewrite_prompt(tone_instruction)
    format(prompt_from_file('tone_rewrite'), tone_instruction)
  end

  def improve_prompt(selection, tone)
    render_liquid_prompt('improve', { selection: selection, tone: tone })
  end

  def improve_user_content(content, selection)
    "Full message:\n#{content}\n\nSelected portion to improve:\n#{selection}"
  end

  def render_liquid_prompt(template_name, context = {})
    template_path = Rails.root.join('lib/integrations/openai/openai_prompts', "#{template_name}.liquid")
    template = Liquid::Template.parse(template_path.read)
    template.render(context.deep_stringify_keys)
  end

  def build_api_call_body(system_content, user_content = event['data']['content'])
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_content },
        { role: 'user', content: user_content }
      ]
    }.to_json
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

  def determine_tone_instruction(tone)
    case tone
    when 'friendly'
      'Warm, approachable, and personable. Use conversational language, positive words, and show empathy. ' \
      'May include phrases like \"Happy to help!\" or \"I\'d be glad to...\"'
    when 'confident'
      'Assertive and assured. Use definitive language, avoid hedging words like \"maybe\" or \"I think\". ' \
      'Be direct and authoritative while remaining helpful.'
    when 'straightforward'
      'Clear, direct, and to-the-point. Remove unnecessary words, get straight to the information or solution. No fluff or extra pleasantries.'
    when 'casual'
      'Relaxed and informal. Use contractions, simpler words, and a conversational style. Friendly but less formal than professional tone.'
    when 'professional'
      'Formal, polished, and business-appropriate. Use complete sentences, proper grammar, ' \
      'and maintain respectful distance. Avoid slang or overly casual language.'
    else
      determine_tone_instruction('friendly')
    end
  end
end

Integrations::Openai::ProcessorService.prepend_mod_with('Integrations::OpenaiProcessorService')
