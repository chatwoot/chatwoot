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
end
