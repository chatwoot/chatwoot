# frozen_string_literal: true

module RubyLLM
  # A single message in a chat conversation.
  class Message
    ROLES = %i[system user assistant tool].freeze

    attr_reader :role, :tool_calls, :tool_call_id, :input_tokens, :output_tokens, :model_id, :raw
    attr_writer :content

    def initialize(options = {})
      @role = options.fetch(:role).to_sym
      @content = normalize_content(options.fetch(:content))
      @tool_calls = options[:tool_calls]
      @input_tokens = options[:input_tokens]
      @output_tokens = options[:output_tokens]
      @model_id = options[:model_id]
      @tool_call_id = options[:tool_call_id]
      @raw = options[:raw]

      ensure_valid_role
    end

    def content
      if @content.is_a?(Content) && @content.text && @content.attachments.empty?
        @content.text
      else
        @content
      end
    end

    def tool_call?
      !tool_calls.nil? && !tool_calls.empty?
    end

    def tool_result?
      !tool_call_id.nil? && !tool_call_id.empty?
    end

    def tool_results
      content if tool_result?
    end

    def to_h
      {
        role: role,
        content: content,
        tool_calls: tool_calls,
        tool_call_id: tool_call_id,
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        model_id: model_id
      }.compact
    end

    def instance_variables
      super - [:@raw]
    end

    private

    def normalize_content(content)
      case content
      when String then Content.new(content)
      when Hash then Content.new(content[:text], content)
      else content
      end
    end

    def ensure_valid_role
      raise InvalidRoleError, "Expected role to be one of: #{ROLES.join(', ')}" unless ROLES.include?(role)
    end
  end
end
