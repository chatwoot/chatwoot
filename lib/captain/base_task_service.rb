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

  def feature_key
    raise NotImplementedError, "#{self.class} must implement #feature_key"
  end

  def configured_model
    account.public_send("captain_#{feature_key}_model")
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

  def execute_ruby_llm_request(model:, messages:)
    Llm::Config.with_api_key(account.captain_api_key, api_base: api_base) do |context|
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
    # TODO: RubyLLM throws the RubyLLM::Error when any API based error occurs
    # Just like inboxes have a reauthroizable error handling mechanism,
    # we should handle the errors if the account is using their own key.
    # If more than 5 errors occur, we disable the hook and notify the admins
    # see: https://rubyllm.com/error-handling/#rubyllm-error-hierarchy
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    { error: e.message, request_messages: messages }
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
      temperature: nil
    }
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
      conversation_history: []
    }
  end

  def extract_original_context(messages)
    # Get the most recent user message for follow-up context
    user_msg = messages.reverse.find { |m| m[:role] == 'user' }
    user_msg ? user_msg[:content] : nil
  end
end

Captain::BaseTaskService.prepend_mod_with('Captain::BaseTaskService')
