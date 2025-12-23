# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module HTTPClients
      MUST_IMPLEMENT_ERROR = 'Subclasses of %s must implement a :%s method'
      WHINY_NIL_ERROR = '%s cannot initialize with a nil wrapped_response object.'

      # This class provides a public interface for wrapping HTTP requests. This
      # may be used to create wrappers that are compatible with New Relic's
      # external request API.
      #
      # @api public
      class AbstractRequest
        %i[[] []= type host_from_header host method headers uri].each do |name|
          define_method(name) do
            not_implemented(name)
          end
        end

        private

        def not_implemented(method_name)
          raise NotImplementedError, MUST_IMPLEMENT_ERROR % [self.class, method_name]
        end
      end

      # This class implements the adaptor pattern and is used internally provide
      # uniform access to the underlying HTTP Client's response object
      # NOTE: response_object should be non-nil!
      class AbstractResponse # :nodoc:
        def initialize(wrapped_response)
          if wrapped_response.nil?
            raise ArgumentError, WHINY_NIL_ERROR % self.class
          end

          @wrapped_response = wrapped_response
        end

        def has_status_code?
          !!status_code
        end

        # most HTTP client libraries report the HTTP status code as an integer, so
        # we expect status_code to be set only if a non-zero value is present
        def status_code
          @status_code ||= get_status_code
        end

        private

        def get_status_code_using(method_name)
          return unless @wrapped_response.respond_to?(method_name)

          code = @wrapped_response.send(method_name).to_i
          code == 0 ? nil : code
        end

        # Override this method to memoize a non-zero Integer representation
        # of HTTP status code from the response object
        def get_status_code
          get_status_code_using(:code)
        end
      end
    end
  end
end
