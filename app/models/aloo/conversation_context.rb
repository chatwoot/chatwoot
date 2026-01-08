# frozen_string_literal: true

module Aloo
  class ConversationContext < ApplicationRecord
    self.table_name = 'aloo_conversation_contexts'

    belongs_to :conversation
    belongs_to :assistant,
               class_name: 'Aloo::Assistant',
               foreign_key: 'aloo_assistant_id',
               inverse_of: :conversation_contexts

    # Delegate account to assistant
    delegate :account, :account_id, to: :assistant

    # Track a new message
    def track_message!(input_tokens: 0, output_tokens: 0, cost: 0)
      self.message_count += 1
      self.input_tokens += input_tokens
      self.output_tokens += output_tokens
      self.total_cost += cost
      save!
    end

    # Add tool execution to history
    def record_tool_call!(tool_name:, input:, output:, success: true)
      tool_history << {
        tool: tool_name,
        input: input,
        output: output,
        success: success,
        timestamp: Time.current.iso8601
      }
      save!
    end

    # Get or set context data
    def get_context(key)
      context_data[key.to_s]
    end

    def set_context(key, value)
      context_data[key.to_s] = value
      save!
    end

    # Total tokens used
    def total_tokens
      input_tokens + output_tokens
    end

    # Check if conversation is getting long
    def context_overflow?(max_messages: 50)
      message_count > max_messages
    end

    # Get recent tool history
    def recent_tools(limit: 5)
      tool_history.last(limit)
    end

    # Reset context for new session
    def reset!
      update!(
        context_data: {},
        tool_history: [],
        message_count: 0,
        input_tokens: 0,
        output_tokens: 0,
        total_cost: 0
      )
    end
  end
end
