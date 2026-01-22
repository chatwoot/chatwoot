class Captain::BaseTaskService
  include Integrations::LlmInstrumentation

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

  def make_api_call(model:, messages:)
    # Community edition prerequisite checks
    # Enterprise module handles these with more specific error messages (cloud vs self-hosted)
    return { error: I18n.t('captain.disabled'), error_code: 403 } unless captain_tasks_enabled?
    return { error: I18n.t('captain.api_key_missing'), error_code: 401 } unless api_key_configured?

    instrumentation_params = build_instrumentation_params(model, messages)

    response = instrument_llm_call(instrumentation_params) do
      execute_ruby_llm_request(model: model, messages: messages)
    end

    # Build follow-up context for client-side refinement, when applicable
    if build_follow_up_context? && response[:message].present?
      response.merge(follow_up_context: build_follow_up_context(messages, response))
    else
      response
    end
  end

  def make_api_call_with_tools(model:, messages:, tools:)
    return { error: I18n.t('captain.disabled'), error_code: 403 } unless captain_tasks_enabled?
    return { error: I18n.t('captain.api_key_missing'), error_code: 401 } unless api_key_configured?

    instrumentation_params = build_instrumentation_params(model, messages)

    response = instrument_tool_session(instrumentation_params) do
      execute_ruby_llm_request_with_tools(model: model, messages: messages, tools: tools)
    end

    if build_follow_up_context? && response[:message].present?
      response.merge(follow_up_context: build_follow_up_context(messages, response))
    else
      response
    end
  end

  # Custom instrumentation for tool flows - outputs just the message (not full hash)
  def instrument_tool_session(params)
    return yield unless ChatwootApp.otel_enabled?

    response = nil
    tracer.in_span(params[:span_name]) do |span|
      span.set_attribute('langfuse.user.id', params[:account_id].to_s) if params[:account_id]
      span.set_attribute('langfuse.tags', [params[:feature_name]].to_json)
      span.set_attribute('langfuse.observation.input', params[:messages].to_json)

      response = yield

      # Output just the message for cleaner Langfuse display
      span.set_attribute('langfuse.observation.output', response[:message] || response.to_json)
    end
    response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    response || yield
  end

  def execute_ruby_llm_request(model:, messages:)
    Llm::Config.with_api_key(api_key, api_base: api_base) do |context|
      chat = context.chat(model: model)
      system_msg = messages.find { |m| m[:role] == 'system' }
      chat.with_instructions(system_msg[:content]) if system_msg

      conversation_messages = messages.reject { |m| m[:role] == 'system' }
      return { error: 'No conversation messages provided', error_code: 400, request_messages: messages } if conversation_messages.empty?

      add_messages_if_needed(chat, conversation_messages)
      response = chat.ask(conversation_messages.last[:content])
      build_ruby_llm_response(response, messages)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    { error: e.message, request_messages: messages }
  end

  def execute_ruby_llm_request_with_tools(model:, messages:, tools:)
    Llm::Config.with_api_key(api_key, api_base: api_base) do |context|
      chat = context.chat(model: 'gpt-4.1')
      tools.each { |tool| chat = chat.with_tool(tool) }

      system_msg = messages.find { |m| m[:role] == 'system' }
      chat.with_instructions(system_msg[:content]) if system_msg

      # Record generation span with tool context
      chat.on_end_message { |message| record_generation(chat, message, model) }

      conversation_messages = messages.reject { |m| m[:role] == 'system' }
      return { error: 'No conversation messages provided', error_code: 400, request_messages: messages } if conversation_messages.empty?

      add_messages_if_needed(chat, conversation_messages)
      response = chat.ask(conversation_messages.last[:content])
      build_ruby_llm_response(response, messages)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    { error: e.message, request_messages: messages }
  end

  def record_generation(chat, message, model)
    return unless ChatwootApp.otel_enabled?
    return unless message.respond_to?(:role) && message.role.to_s == 'assistant'

    tracer.in_span("llm.#{event_name}.generation") do |span|
      span.set_attribute('gen_ai.system', 'openai')
      span.set_attribute('gen_ai.request.model', model)
      span.set_attribute('gen_ai.usage.input_tokens', message.input_tokens)
      span.set_attribute('gen_ai.usage.output_tokens', message.output_tokens) if message.respond_to?(:output_tokens)
      span.set_attribute('langfuse.observation.input', format_chat_messages(chat))
      span.set_attribute('langfuse.observation.output', message.content.to_s) if message.respond_to?(:content)
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to record generation: #{e.message}"
  end

  def format_chat_messages(chat)
    chat.messages[0...-1].map { |m| { role: m.role.to_s, content: m.content.to_s } }.to_json
  end

  def tracer
    OpenTelemetry.tracer_provider.tracer('chatwoot')
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
