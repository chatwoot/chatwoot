require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  # A tool class built at runtime needs a constant, or Class#name is nil and the LLM request gets an empty function name.
  # Registering a name again replaces the class an earlier build left there.
  def self.register_generated(namespace, class_name, tool_class)
    namespace.send(:remove_const, class_name) if namespace.const_defined?(class_name, false)
    namespace.const_set(class_name, tool_class)
  end

  def initialize(assistant)
    @assistant = assistant
    super()
  end

  def execute(tool_context, **params)
    return super if read_only?
    if newer_customer_message_arrived?(tool_context.state)
      return failure_result('Tool skipped because a newer customer message arrived', tool_context.state)
    end

    super
  end

  # A tool that changes nothing can still run after a newer customer message, and can run for a reply suggestion
  def read_only?
    false
  end

  # The tool to use when an admin or an agent is the user. A tool that fills verified values builds its Copilot version.
  def for_copilot
    self
  end

  private

  def account_scoped(model_class)
    model_class.where(account_id: @assistant.account_id)
  end

  def failure_result(message, state)
    state&.dig(:source) == 'playground' ? "ERROR: #{message}" : message
  end

  def find_conversation(state)
    conversation_id = state&.dig(:conversation, :id)
    return nil unless conversation_id

    account_scoped(::Conversation).find_by(id: conversation_id)
  end

  def find_contact(state)
    contact_id = state&.dig(:contact, :id)
    return nil unless contact_id

    account_scoped(::Contact).find_by(id: contact_id)
  end

  def newer_customer_message_arrived?(state)
    responding_to_message_id = state&.dig(:responding_to_message_id)
    return false if responding_to_message_id.blank?

    conversation_id = state&.dig(:conversation, :id)

    ::Message.uncached do
      account_scoped(::Message)
        .where(conversation_id: conversation_id)
        .captain_response_triggering
        .exists?(['messages.id > ?', responding_to_message_id])
    end
  end

  def log_tool_usage(action, details = {})
    Rails.logger.info do
      "#{self.class.name}: #{action} for assistant #{@assistant&.id} - #{details.inspect}"
    end
  end
end
