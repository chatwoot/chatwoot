class Captain::Llm::AssistantChatService < Llm::BaseAiService
  include Captain::ChatHelper

  def initialize(assistant: nil, conversation: nil, source: nil)
    super(feature: 'assistant', account: assistant&.account || conversation&.account)

    @assistant = assistant
    @conversation = conversation
    @conversation_id = conversation&.display_id
    @source = source

    @messages = []
    @response = ''
    @tools = build_tools
  end

  # additional_message: A single message (String) from the user that should be appended to the chat.
  #                    It can be an empty String or nil when you only want to supply historical messages.
  # message_history:   An Array of already formatted messages that provide the previous context.
  # role:              The role for the additional_message (defaults to `user`).
  #
  # NOTE: Parameters are provided as keyword arguments to improve clarity and avoid relying on
  # positional ordering.
  def generate_response(additional_message: nil, message_history: [], role: 'user')
    current_query, previous_user_message = knowledge_map_messages(
      additional_message: additional_message,
      message_history: message_history
    )
    @messages = [system_message(query: current_query, previous_user_message: previous_user_message)]
    @messages += message_history
    @messages << { role: role, content: additional_message } if additional_message.present?
    request_chat_completion
  end

  private

  def build_tools
    tools = [Captain::Tools::SearchDocumentationService.new(@assistant, user: nil)]
    return tools unless custom_tools_enabled?

    tools + @assistant.account.captain_custom_tools.enabled.map do |ct|
      ct.tool(@assistant, base_class: Captain::Tools::CustomHttpTool, conversation: @conversation)
    end
  end

  def system_message(query:, previous_user_message:)
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(
        @assistant.name,
        @assistant.config['product_name'],
        @assistant.config.merge(
          'timezone' => inbox_timezone,
          'knowledge_map' => @assistant.knowledge_map_for_prompt(query: query, previous_user_message: previous_user_message)
        ),
        contact: contact_attributes,
        custom_tools: custom_tools_metadata
      )
    }
  end

  def knowledge_map_messages(additional_message:, message_history:)
    user_messages = message_history.select { |message| message[:role].to_s == 'user' }
    return [message_text(content: additional_message), message_text(user_messages.last)] if @source == 'playground'

    return [message_text(user_messages.last), message_text(user_messages[-2])] if user_messages.any?

    [message_text(content: additional_message), '']
  end

  def message_text(message = nil, content: nil)
    content ||= message&.[](:content)
    Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content).first.to_s
  end

  def custom_tools_metadata
    return [] unless custom_tools_enabled?

    @assistant.account.captain_custom_tools.enabled.map do |ct|
      { name: ct.slug, description: ct.description }
    end
  end

  def custom_tools_enabled?
    @assistant.account.feature_enabled?('custom_tools')
  end

  def contact_attributes
    return nil unless @conversation&.contact
    return nil unless @assistant&.feature_contact_attributes

    @conversation.contact.attributes.symbolize_keys.slice(
      :id, :name, :email, :phone_number, :identifier, :custom_attributes
    )
  end

  def inbox_timezone
    @conversation&.inbox&.timezone.presence || 'UTC'
  end

  def persist_message(message, message_type = 'assistant')
    # No need to implement
  end

  def feature_name
    'assistant'
  end
end
