# frozen_string_literal: true

module HTTParty
  class HeadersProcessor
    attr_reader :headers, :options

    def initialize(headers, options)
      @headers = headers
      @options = options
    end

    def call
      return unless options[:headers]

      options[:headers] = headers.merge(options[:headers]) if headers.any?
      options[:headers] = Utils.stringify_keys(process_dynamic_headers)
    end

    private

    def process_dynamic_headers
      options[:headers].each_with_object({}) do |header, processed_headers|
        key, value = header
        processed_headers[key] = if value.respond_to?(:call)
                                   value.arity == 0 ? value.call : value.call(options)
                                 else
                                   value
                                 end
      end
    end
  end
end
