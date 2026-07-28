require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  def initialize(assistant)
    @assistant = assistant
    super()
  end

  def execute(tool_context, **params)
    return super if safe_to_run_after_new_customer_message?
    return 'Tool skipped because a newer customer message arrived' if newer_customer_message_arrived?(tool_context.state)

    super
  end

  def active?
    # Public tools are always active
    true
  end

  def permissions
    # Override in subclasses to specify required permissions
    # Returns empty array for public tools (no permissions required)
    []
  end

  private

  def account_scoped(model_class)
    model_class.where(account_id: @assistant.account_id)
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

  def safe_to_run_after_new_customer_message?
    false
  end

  def newer_customer_message_arrived?(state)
    trigger_message_id = state&.dig(:trigger_message_id)
    return false if trigger_message_id.blank?

    conversation_id = state&.dig(:conversation, :id)
    latest_incoming_message_id = ::Message.uncached do
      account_scoped(::Message).where(conversation_id: conversation_id).incoming.maximum(:id)
    end

    latest_incoming_message_id != trigger_message_id
  end

  def log_tool_usage(action, details = {})
    Rails.logger.info do
      "#{self.class.name}: #{action} for assistant #{@assistant&.id} - #{details.inspect}"
    end
  end
end
