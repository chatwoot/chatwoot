require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  NEWER_MESSAGE_ARRIVED = 'Tool skipped because a newer customer message arrived'.freeze

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
    guard = Captain::Tools::RunGuard.new(tool_context.state)
    return halt_stale_run(guard, tool_context) if stale_run?(tool_context)

    case guard.register_call(name, params)
    when :exhausted
      halt_exhausted_budget(guard, tool_context)
    when :repeated
      log_run_guard('repeated_tool_call_skipped', tool_context, guard)
      Captain::Tools::RunGuard::REPEATED_CALL_MESSAGE
    else
      super
    end
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

  def stale_run?(tool_context)
    return false if read_only?

    newer_customer_message_arrived?(tool_context.state)
  end

  # The run is answering a message the customer already replaced, so the reply is
  # discarded either way. Halting keeps the model from spending more tool calls on it.
  def halt_stale_run(guard, tool_context)
    log_run_guard('stale_run_halted', tool_context, guard)
    guard.halt(Captain::Tools::RunGuard::STALE_RUN, failure_result(NEWER_MESSAGE_ARRIVED, tool_context.state))
  end

  def halt_exhausted_budget(guard, tool_context)
    log_run_guard('tool_call_budget_exceeded', tool_context, guard)
    guard.halt(Captain::Tools::RunGuard::TOOL_CALL_BUDGET_EXCEEDED, Captain::Tools::RunGuard::BUDGET_EXCEEDED_MESSAGE)
  end

  def log_run_guard(event, tool_context, guard)
    Rails.logger.warn do
      "[Captain V2][RunGuard] #{event} assistant=#{@assistant&.id} " \
        "conversation=#{tool_context.state&.dig(:conversation, :id)} tool=#{name} tool_calls=#{guard.total_calls}"
    end
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
