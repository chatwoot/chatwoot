# frozen_string_literal: true

# Base class for Aloo AI agent tools
# Tools are capabilities that can be called by the AI agent during conversation
#
# Usage:
#   class MyTool < BaseTool
#     description "Does something useful"
#     param :query, type: :string, desc: "The search query", required: true
#
#     def execute(query:)
#       # Tool implementation
#     end
#   end
#
class BaseTool < RubyLLM::Tool
  class << self
    # Access the current context set before tool execution
    def current_context
      Aloo::Current
    end

    # Set context before executing tools
    def with_context(account:, assistant:, conversation:, contact: nil)
      Aloo::Current.account = account
      Aloo::Current.assistant = assistant
      Aloo::Current.conversation = conversation
      Aloo::Current.contact = contact
      Aloo::Current.request_id ||= SecureRandom.uuid
      yield
    ensure
      Aloo::Current.reset
    end
  end

  protected

  # Access current account from context
  def current_account
    Aloo::Current.account
  end

  # Access current assistant from context
  def current_assistant
    Aloo::Current.assistant
  end

  # Access current conversation from context
  def current_conversation
    Aloo::Current.conversation
  end

  # Access current contact from context
  def current_contact
    Aloo::Current.contact
  end

  # Log tool execution for observability
  def log_execution(input_data, output_data, success: true, error_message: nil)
    return unless current_account

    Aloo::Trace.record(
      trace_type: 'tool_execution',
      account: current_account,
      assistant: current_assistant,
      conversation: current_conversation,
      input_data: {
        tool: self.class.name,
        input: input_data
      },
      output_data: output_data,
      success: success,
      error_message: error_message
    )
  end

  # Format a successful response
  def success_response(data)
    { success: true, data: data }
  end

  # Format an error response
  def error_response(message)
    { success: false, error: message }
  end

  # Validate that required context is available
  def validate_context!
    raise 'Account context required' unless current_account
    raise 'Assistant context required' unless current_assistant
    raise 'Conversation context required' unless current_conversation || playground_mode?
  end

  # Check if running in playground mode (no real conversation)
  def playground_mode?
    Aloo::Current.playground_mode == true
  end
end
