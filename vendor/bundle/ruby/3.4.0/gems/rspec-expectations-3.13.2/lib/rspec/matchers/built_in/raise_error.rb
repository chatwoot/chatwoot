module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Provides the implementation for `raise_error`.
      # Not intended to be instantiated directly.
      # rubocop:disable Metrics/ClassLength
      # rubocop:disable Lint/RescueException
      class RaiseError
        include Composable

        # Used as a sentinel value to be able to tell when the user did not pass an
        # argument. We can't use `nil` for that because we need to warn when `nil` is
        # passed in a different way. It's an Object, not a Module, since Module's `===`
        # does not evaluate to true when compared to itself.
        #
        # Note; this _is_ the default value supplied for expected_error_or_message, but
        # because there are two method-calls involved, that default is actually supplied
        # in the definition of the _matcher_ method, `RSpec::Matchers#raise_error`
        UndefinedValue = Object.new.freeze

        def initialize(expected_error_or_message, expected_message, &block)
          @block = block
          @actual_error = nil
          @warn_about_bare_error = UndefinedValue === expected_error_or_message
          @warn_about_nil_error = expected_error_or_message.nil?

          case expected_error_or_message
          when nil, UndefinedValue
            @expected_error = Exception
            @expected_message = expected_message
          when String, Regexp
            @expected_error = Exception
            @expected_message = expected_error_or_message
          else
            @expected_error = expected_error_or_message
            @expected_message = expected_message
          end
        end

        # @api public
        # Specifies the expected error message.
        def with_message(expected_message)
          raise_message_already_set if @expected_message
          @warn_about_bare_error = false
          @expected_message = expected_message
          self
        end

        # rubocop:disable Metrics/MethodLength
        # @private
        def matches?(given_proc, negative_expectation=false, &block)
          @given_proc = given_proc
          @block ||= block
          @raised_expected_error = false
          @with_expected_message = false
          @eval_block = false
          @eval_block_passed = false

          return false unless Proc === given_proc

          begin
            given_proc.call
          rescue Exception => @actual_error
            if values_match?(@expected_error, @actual_error) ||
               values_match?(@expected_error, actual_error_message)
              @raised_expected_error = true
              @with_expected_message = verify_message
            end
          end

          unless negative_expectation
            warn_about_bare_error! if warn_about_bare_error?
            warn_about_nil_error! if warn_about_nil_error?
            eval_block if ready_to_eval_block?
          end

          expectation_matched?
        end
        # rubocop:enable Metrics/MethodLength

        # @private
        def does_not_match?(given_proc)
          warn_for_negative_false_positives!
          !matches?(given_proc, :negative_expectation) && Proc === given_proc
        end

        # @private
        def supports_block_expectations?
          true
        end

        # @private
        def supports_value_expectations?
          false
        end

        # @private
        def expects_call_stack_jump?
          true
        end

        # @api private
        # @return [String]
        def failure_message
          @eval_block ? actual_error_message : "expected #{expected_error}#{given_error}"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "expected no #{expected_error}#{given_error}"
        end

        # @api private
        # @return [String]
        def description
          "raise #{expected_error}"
        end

      private

        def actual_error_message
          return nil unless @actual_error

          @actual_error.respond_to?(:original_message) ? @actual_error.original_message : @actual_error.message
        end

        def expectation_matched?
          error_and_message_match? && block_matches?
        end

        def error_and_message_match?
          @raised_expected_error && @with_expected_message
        end

        def block_matches?
          @eval_block ? @eval_block_passed : true
        end

        def ready_to_eval_block?
          @raised_expected_error && @with_expected_message && @block
        end

        def eval_block
          @eval_block = true
          begin
            @block[@actual_error]
            @eval_block_passed = true
          rescue Exception => err
            @actual_error = err
          end
        end

        def verify_message
          return true if @expected_message.nil?
          values_match?(@expected_message, actual_error_message.to_s)
        end

        def warn_for_negative_false_positives!
          expression = if expecting_specific_exception? && @expected_message
                         "`expect { }.not_to raise_error(SpecificErrorClass, message)`"
                       elsif expecting_specific_exception?
                         "`expect { }.not_to raise_error(SpecificErrorClass)`"
                       elsif @expected_message
                         "`expect { }.not_to raise_error(message)`"
                       elsif @warn_about_nil_error
                         "`expect { }.not_to raise_error(nil)`"
                       end

          return unless expression

          warn_about_negative_false_positive! expression
        end

        def handle_warning(message)
          RSpec::Expectations.configuration.false_positives_handler.call(message)
        end

        def warn_about_bare_error?
          @warn_about_bare_error && @block.nil?
        end

        def warn_about_nil_error?
          @warn_about_nil_error
        end

        def warn_about_bare_error!
          handle_warning("Using the `raise_error` matcher without providing a specific " \
                         "error or message risks false positives, since `raise_error` " \
                         "will match when Ruby raises a `NoMethodError`, `NameError` or " \
                         "`ArgumentError`, potentially allowing the expectation to pass " \
                         "without even executing the method you are intending to call. " \
                         "#{warning}"\
                         "Instead consider providing a specific error class or message. " \
                         "This message can be suppressed by setting: " \
                         "`RSpec::Expectations.configuration.on_potential_false" \
                         "_positives = :nothing`")
        end

        def warn_about_nil_error!
          handle_warning("Using the `raise_error` matcher with a `nil` error is probably " \
                         "unintentional, it risks false positives, since `raise_error` " \
                         "will match when Ruby raises a `NoMethodError`, `NameError` or " \
                         "`ArgumentError`, potentially allowing the expectation to pass " \
                         "without even executing the method you are intending to call. " \
                         "#{warning}"\
                         "Instead consider providing a specific error class or message. " \
                         "This message can be suppressed by setting: " \
                         "`RSpec::Expectations.configuration.on_potential_false" \
                         "_positives = :nothing`")
        end

        def warn_about_negative_false_positive!(expression)
          handle_warning("Using #{expression} risks false positives, since literally " \
                         "any other error would cause the expectation to pass, " \
                         "including those raised by Ruby (e.g. `NoMethodError`, `NameError` " \
                         "and `ArgumentError`), meaning the code you are intending to test " \
                         "may not even get reached. Instead consider using " \
                         "`expect { }.not_to raise_error` or `expect { }.to raise_error" \
                         "(DifferentSpecificErrorClass)`. This message can be suppressed by " \
                         "setting: `RSpec::Expectations.configuration.on_potential_false" \
                         "_positives = :nothing`")
        end

        def expected_error
          case @expected_message
          when nil
            if RSpec::Support.is_a_matcher?(@expected_error)
              "Exception with #{description_of(@expected_error)}"
            else
              description_of(@expected_error)
            end
          when Regexp
            "#{@expected_error} with message matching #{description_of(@expected_message)}"
          else
            "#{@expected_error} with #{description_of(@expected_message)}"
          end
        end

        def format_backtrace(backtrace)
          formatter = Matchers.configuration.backtrace_formatter
          formatter.format_backtrace(backtrace)
        end

        def given_error
          return " but was not given a block" unless Proc === @given_proc
          return " but nothing was raised" unless @actual_error

          backtrace = format_backtrace(@actual_error.backtrace)
          [
            ", got #{description_of(@actual_error)} with backtrace:",
            *backtrace
          ].join("\n  # ")
        end

        def expecting_specific_exception?
          @expected_error != Exception
        end

        def raise_message_already_set
          raise "`expect { }.to raise_error(message).with_message(message)` is not valid. " \
                'The matcher only allows the expected message to be specified once'
        end

        def warning
          warning = "Actual error raised was #{description_of(@actual_error)}. "
          warning if @actual_error
        end
      end
      # rubocop:enable Lint/RescueException
      # rubocop:enable Metrics/ClassLength
    end
  end
end
