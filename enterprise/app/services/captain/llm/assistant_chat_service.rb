class Captain::Llm::AssistantChatService < Llm::BaseAiService
  include Captain::ChatHelper

  def initialize(assistant: nil, conversation: nil, source: nil)
    super()

    @assistant = assistant
    @conversation = conversation
    @conversation_id = conversation&.display_id
    @source = source

    @messages = [system_message]
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

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(
        @assistant.name, @assistant.config['product_name'], @assistant.config,
        contact: contact_attributes,
        custom_tools: custom_tools_metadata
      )
    }
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

  def persist_message(message, message_type = 'assistant')
    # No need to implement
  end

  def feature_name
    'assistant'
  end
end
