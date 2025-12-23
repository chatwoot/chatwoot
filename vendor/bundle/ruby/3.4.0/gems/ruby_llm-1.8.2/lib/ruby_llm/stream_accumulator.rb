# frozen_string_literal: true

module RubyLLM
  # Assembles streaming responses from LLMs into complete messages.
  class StreamAccumulator
    attr_reader :content, :model_id, :tool_calls

    def initialize
      @content = +''
      @tool_calls = {}
      @input_tokens = 0
      @output_tokens = 0
      @latest_tool_call_id = nil
    end

    def add(chunk)
      RubyLLM.logger.debug chunk.inspect if RubyLLM.config.log_stream_debug
      @model_id ||= chunk.model_id

      if chunk.tool_call?
        accumulate_tool_calls chunk.tool_calls
      else
        @content << (chunk.content || '')
      end

      count_tokens chunk
      RubyLLM.logger.debug inspect if RubyLLM.config.log_stream_debug
    end

    def to_message(response)
      Message.new(
        role: :assistant,
        content: content.empty? ? nil : content,
        model_id: model_id,
        tool_calls: tool_calls_from_stream,
        input_tokens: @input_tokens.positive? ? @input_tokens : nil,
        output_tokens: @output_tokens.positive? ? @output_tokens : nil,
        raw: response
      )
    end

    private

    def tool_calls_from_stream
      tool_calls.transform_values do |tc|
        arguments = if tc.arguments.is_a?(String) && !tc.arguments.empty?
                      JSON.parse(tc.arguments)
                    elsif tc.arguments.is_a?(String)
                      {}
                    else
                      tc.arguments
                    end

        ToolCall.new(
          id: tc.id,
          name: tc.name,
          arguments: arguments
        )
      end
    end

    def accumulate_tool_calls(new_tool_calls)
      RubyLLM.logger.debug "Accumulating tool calls: #{new_tool_calls}" if RubyLLM.config.log_stream_debug
      new_tool_calls.each_value do |tool_call|
        if tool_call.id
          tool_call_id = tool_call.id.empty? ? SecureRandom.uuid : tool_call.id
          tool_call_arguments = tool_call.arguments.empty? ? +'' : tool_call.arguments
          @tool_calls[tool_call.id] = ToolCall.new(
            id: tool_call_id,
            name: tool_call.name,
            arguments: tool_call_arguments
          )
          @latest_tool_call_id = tool_call.id
        else
          existing = @tool_calls[@latest_tool_call_id]
          existing.arguments << tool_call.arguments if existing
        end
      end
    end

    def find_tool_call(tool_call_id)
      if tool_call_id.nil?
        @tool_calls[@latest_tool_call]
      else
        @latest_tool_call_id = tool_call_id
        @tool_calls[tool_call_id]
      end
    end

    def count_tokens(chunk)
      @input_tokens = chunk.input_tokens if chunk.input_tokens
      @output_tokens = chunk.output_tokens if chunk.output_tokens
    end
  end
end
