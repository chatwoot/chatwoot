# frozen_string_literal: true

require 'active_support'
require 'active_support/cache'
require 'active_support/json'
require 'active_support/core_ext'

module MetaRequest
  # Subclass of ActiveSupport Event that is JSON encodable
  #
  class Event < ActiveSupport::Notifications::Event
    NOT_JSON_ENCODABLE = 'Not JSON Encodable'

    attr_reader :duration

    def initialize(name, start, ending, transaction_id, payload)
      @name = name
      super(name, start, ending, transaction_id, json_encodable(payload))
      @duration = 1000.0 * (ending - start)
    end

    def self.events_for_exception(exception_wrapper)
      if defined?(ActionDispatch::ExceptionWrapper)
        exception = exception_wrapper.exception
        trace = exception_wrapper.application_trace
        trace = exception_wrapper.framework_trace if trace.empty?
      else
        exception = exception_wrapper
        trace = exception.backtrace
      end
      trace.unshift "#{exception.class} (#{exception.message})"
      trace.map do |call|
        Event.new('process_action.action_controller.exception', 0, 0, nil, call: call)
      end
    end

    private

    def json_encodable(payload)
      return {} unless payload.is_a?(Hash)

      transform_hash(sanitize_hash(payload), deep: true) do |hash, key, value|
        if value.class.to_s == 'ActionDispatch::Http::Headers'
          value = value.to_h.select { |k, _| k.upcase == k }
        elsif not_encodable?(value)
          value = NOT_JSON_ENCODABLE
        end

        begin
          value.to_json(methods: [:duration])
          new_value = value
        rescue StandardError
          new_value = NOT_JSON_ENCODABLE
        end
        hash[key] = new_value
      end.with_indifferent_access
    end

    def sanitize_hash(payload)
      if @name =~ /\Acache_\w+\.active_support\z/
        payload[:key] = ActiveSupport::Cache::Store.new.send(:normalize_key, payload[:key])
      end

      payload.except(:locals)
    end

    def not_encodable?(value)
      return true if defined?(ActiveRecord) && value.is_a?(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      return true if defined?(ActionDispatch) && (value.is_a?(ActionDispatch::Request) || value.is_a?(ActionDispatch::Response))
      return true if defined?(ActionView) && value.is_a?(ActionView::Helpers::FormBuilder)

      false
    end

    # https://gist.github.com/dbenhur/1070399
    def transform_hash(original, options = {}, &block)
      options[:safe_descent] ||= {}
      new_hash = {}
      options[:safe_descent][original.object_id] = new_hash
      original.each_with_object(new_hash) do |(key, value), result|
        if options[:deep] && Hash === value
          value = options[:safe_descent].fetch(value.object_id) do
            transform_hash(value, options, &block)
          end
        end
        block.call(result, key, value)
      end
    end
  end
end
