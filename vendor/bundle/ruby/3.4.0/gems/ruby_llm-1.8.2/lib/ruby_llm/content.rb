# frozen_string_literal: true

module RubyLLM
  # Represents the content sent to or received from an LLM.
  class Content
    attr_reader :text, :attachments

    def initialize(text = nil, attachments = nil)
      @text = text
      @attachments = []

      process_attachments(attachments)
      raise ArgumentError, 'Text and attachments cannot be both nil' if @text.nil? && @attachments.empty?
    end

    def add_attachment(source, filename: nil)
      @attachments << Attachment.new(source, filename:)
      self
    end

    def format
      if @text && @attachments.empty?
        @text
      else
        self
      end
    end

    # For Rails serialization
    def to_h
      { text: @text, attachments: @attachments.map(&:to_h) }
    end

    private

    def process_attachments_array_or_string(attachments)
      Utils.to_safe_array(attachments).each do |file|
        add_attachment(file)
      end
    end

    def process_attachments(attachments)
      if attachments.is_a?(Hash)
        attachments.each_value { |attachment| process_attachments_array_or_string(attachment) }
      else
        process_attachments_array_or_string attachments
      end
    end
  end
end
