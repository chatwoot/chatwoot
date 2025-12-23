module Shoulda
  module Matchers
    module ActionController
      # The `rescue_from` matcher tests usage of the `rescue_from` macro. It
      # asserts that an exception and method are present in the list of
      # exception handlers, and that the handler method exists.
      #
      #     class ApplicationController < ActionController::Base
      #       rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      #
      #       private
      #
      #       def handle_not_found
      #         # ...
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe ApplicationController, type: :controller do
      #       it do
      #         should rescue_from(ActiveRecord::RecordNotFound).
      #           with(:handle_not_found)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ApplicationControllerTest < ActionController::TestCase
      #       should rescue_from(ActiveRecord::RecordNotFound).
      #         with(:handle_not_found)
      #     end
      #
      # @return [RescueFromMatcher]
      #
      def rescue_from(exception)
        RescueFromMatcher.new exception
      end

      # @private
      class RescueFromMatcher
        def initialize(exception)
          @exception = exception
          @expected_method = nil
          @controller = nil
        end

        def with(method)
          @expected_method = method
          self
        end

        def matches?(controller)
          @controller = controller
          rescues_from_exception? && method_name_matches? && handler_exists?
        end

        def description
          description = "rescue from #{exception}"
          description << " with ##{expected_method}" if expected_method
          description
        end

        def failure_message
          "Expected #{expectation}"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        protected

        attr_reader :controller, :exception, :expected_method, :handlers

        def expectation
          expectation = "#{controller} to rescue from #{exception}"

          if expected_method && !method_name_matches?
            expectation << " with ##{expected_method}"
          end

          unless handler_exists?
            expectation << " but #{controller} does not respond to"\
              " #{expected_method}"
          end
          expectation
        end

        def rescues_from_exception?
          @handlers = controller.rescue_handlers.select do |handler|
            handler.first == exception.to_s
          end
          handlers.any?
        end

        def method_name_matches?
          if expected_method.present?
            handlers.any? do |handler|
              handler.last == expected_method
            end
          else
            true
          end
        end

        def handler_exists?
          if expected_method.present?
            controller.respond_to? expected_method, true
          else
            true
          end
        end
      end
    end
  end
end
