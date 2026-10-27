require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  UNTRUSTED_RESULT_START = '<tool_result trust="untrusted">'.freeze
  UNTRUSTED_RESULT_END = '</tool_result>'.freeze

  def initialize(assistant)
    @assistant = assistant
    super()
  end

  def execute(tool_context, **params)
    return super if safe_to_run_after_new_customer_message?
    if newer_customer_message_arrived?(tool_context.state)
      return failure_result('Tool skipped because a newer customer message arrived', tool_context.state)
    end

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

  def safe_to_run_after_new_customer_message?
    false
  end

  # Read from stored data on every call, never from the run state the model can influence
  def stored_verified_email(state)
    conversation = find_conversation(state)
    conversation && Captain::EmailVerification.new(conversation).verified_email
  end

  # Text from an outside system goes to the model inside markers. The prompt tells the model to treat it as data only.
  # The closing marker is removed from the text, so the text cannot end the block early.
  def untrusted_result(text)
    "#{UNTRUSTED_RESULT_START}\n#{text.to_s.gsub(UNTRUSTED_RESULT_END, '')}\n#{UNTRUSTED_RESULT_END}"
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
