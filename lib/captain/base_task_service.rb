class Captain::BaseTaskService
  include Integrations::LlmInstrumentation
  include Captain::ToolInstrumentation

  # gpt-4o-mini supports 128,000 tokens
  # 1 token is approx 4 characters
  # sticking with 120000 to be safe
  # 120000 * 4 = 480,000 characters (rounding off downwards to 400,000 to be safe)
  TOKEN_LIMIT = 400_000
  GPT_MODEL = Llm::Config::DEFAULT_MODEL

  # Prepend enterprise module to subclasses when they're defined.
  # This ensures the enterprise perform wrapper is applied even when
  # subclasses define their own perform method, since prepend puts
  # the module before the class in the ancestor chain.
  def self.inherited(subclass)
    super
    subclass.prepend_mod_with('Captain::BaseTaskService')
  end

  pattr_initialize [:account!, { conversation_display_id: nil }]

  private

  def event_name
    raise NotImplementedError, "#{self.class} must implement #event_name"
  end

  def conversation
    @conversation ||= account.conversations.find_by(display_id: conversation_display_id)
  end

  def api_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence || 'https://api.openai.com/'
    endpoint = endpoint.chomp('/')
    "#{endpoint}/v1"
  end

  def make_api_call(model:, messages:, tools: [])
    # Community edition prerequisite checks
    # Enterprise module handles these with more specific error messages (cloud vs self-hosted)
    return { error: I18n.t('captain.disabled'), error_code: 403 } unless captain_tasks_enabled?
    return { error: I18n.t('captain.api_key_missing'), error_code: 401 } unless api_key_configured?

    instrumentation_params = build_instrumentation_params(model, messages)
    instrumentation_method = tools.any? ? :instrument_tool_session : :instrument_llm_call

    response = send(instrumentation_method, instrumentation_params) do
      execute_ruby_llm_request(model: model, messages: messages, tools: tools)
    end

    return response unless build_follow_up_context? && response[:message].present?

    response.merge(follow_up_context: build_follow_up_context(messages, response))
  end

  def execute_ruby_llm_request(model:, messages:, tools: [])
    Llm::Config.with_api_key(api_key, api_base: api_base) do |context|
      chat = build_chat(context, model: model, messages: messages, tools: tools)

      conversation_messages = messages.reject { |m| m[:role] == 'system' }
      return { error: 'No conversation messages provided', error_code: 400, request_messages: messages } if conversation_messages.empty?

      add_messages_if_needed(chat, conversation_messages)
      build_ruby_llm_response(chat.ask(conversation_messages.last[:content]), messages)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    { error: e.message, request_messages: messages }
  end

  def build_chat(context, model:, messages:, tools: [])
    chat = context.chat(model: model)
    system_msg = messages.find { |m| m[:role] == 'system' }
    chat.with_instructions(system_msg[:content]) if system_msg

    if tools.any?
      tools.each { |tool| chat = chat.with_tool(tool) }
      chat.on_end_message { |message| record_generation(chat, message, model) }
    end

    chat
  end

  def add_messages_if_needed(chat, conversation_messages)
    return if conversation_messages.length == 1

    conversation_messages[0...-1].each do |msg|
      chat.add_message(role: msg[:role].to_sym, content: msg[:content])
    end
  end

  def build_ruby_llm_response(response, messages)
    {
      message: response.content,
      usage: {
        'prompt_tokens' => response.input_tokens,
        'completion_tokens' => response.output_tokens,
        'total_tokens' => (response.input_tokens || 0) + (response.output_tokens || 0)
      },
      request_messages: messages
    }
  end

  def build_instrumentation_params(model, messages)
    {
      span_name: "llm.#{event_name}",
      account_id: account.id,
      conversation_id: conversation&.display_id,
      feature_name: event_name,
      model: model,
      messages: messages,
      temperature: nil,
      metadata: instrumentation_metadata
    }
  end

  def instrumentation_metadata
    {
      channel_type: conversation&.inbox&.channel_type
    }.compact
  end

  def conversation_messages(start_from: 0)
    messages = []
    character_count = start_from

    conversation.messages
                .where(message_type: [:incoming, :outgoing])
                .where(private: false)
                .reorder('id desc')
                .each do |message|
      content = message.content_for_llm
      break unless content.present? && character_count + content.length <= TOKEN_LIMIT

      messages.prepend({ role: (message.incoming? ? 'user' : 'assistant'), content: content })
      character_count += content.length
    end

    messages
  end

  def captain_tasks_enabled?
    account.feature_enabled?('captain_tasks')
  end

  def api_key_configured?
    api_key.present?
  end

  def api_key
    @api_key ||= openai_hook&.settings&.dig('api_key') || system_api_key
  end

  def openai_hook
    @openai_hook ||= account.hooks.find_by(app_id: 'openai', status: 'enabled')
  end

  def system_api_key
    @system_api_key ||= InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  def prompt_from_file(file_name)
    Rails.root.join('lib/integrations/openai/openai_prompts', "#{file_name}.liquid").read
  end

  # Follow-up context for client-side refinement
  def build_follow_up_context?
    # FollowUpService should return its own updated context
    !is_a?(Captain::FollowUpService)
  end

  def build_follow_up_context(messages, response)
    {
      event_name: event_name,
      original_context: extract_original_context(messages),
      last_response: response[:message],
      conversation_history: [],
      channel_type: conversation&.inbox&.channel_type
    }
  end

  def extract_original_context(messages)
    # Get the most recent user message for follow-up context
    user_msg = messages.reverse.find { |m| m[:role] == 'user' }
    user_msg ? user_msg[:content] : nil
  end
end
Captain::BaseTaskService.prepend_mod_with('Captain::BaseTaskService')
