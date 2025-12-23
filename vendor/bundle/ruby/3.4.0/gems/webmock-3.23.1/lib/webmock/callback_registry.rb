# frozen_string_literal: true

module WebMock
  class CallbackRegistry
    @@callbacks = []

    def self.add_callback(options, block)
      @@callbacks << {options: options, block: block}
    end

    def self.callbacks
      @@callbacks
    end

    def self.invoke_callbacks(options, request_signature, response)
      return if @@callbacks.empty?
      CallbackRegistry.callbacks.each do |callback|
        except = callback[:options][:except]
        real_only = callback[:options][:real_requests_only]
        unless except && except.include?(options[:lib])
          if !real_only || options[:real_request]
            callback[:block].call(request_signature, response)
          end
        end
      end
    end

    def self.reset
      @@callbacks = []
    end

    def self.any_callbacks?
      !@@callbacks.empty?
    end

  end
end
