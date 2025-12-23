require 'shoulda/matchers/doublespeak'
require 'shoulda/matchers/matcher_context'

module Shoulda
  module Matchers
    module Independent
      # The `delegate_method` matcher tests that an object forwards messages
      # to other, internal objects by way of delegation.
      #
      # In this example, we test that Courier forwards a call to #deliver onto
      # its PostOffice instance:
      #
      #     require 'forwardable'
      #
      #     class Courier
      #       extend Forwardable
      #
      #       attr_reader :post_office
      #
      #       def_delegators :post_office, :deliver
      #
      #       def initialize
      #         @post_office = PostOffice.new
      #       end
      #     end
      #
      #     # RSpec
      #     describe Courier do
      #       it { should delegate_method(:deliver).to(:post_office) }
      #     end
      #
      #     # Minitest
      #     class CourierTest < Minitest::Test
      #       should delegate_method(:deliver).to(:post_office)
      #     end
      #
      # You can also use `delegate_method` with Rails's `delegate` macro:
      #
      #     class Courier
      #       attr_reader :post_office
      #       delegate :deliver, to: :post_office
      #
      #       def initialize
      #         @post_office = PostOffice.new
      #       end
      #     end
      #
      #     describe Courier do
      #       it { should delegate_method(:deliver).to(:post_office) }
      #     end
      #
      # To employ some terminology, we would say that Courier's #deliver method
      # is the *delegating method*, PostOffice is the *delegate object*, and
      # PostOffice#deliver is the *delegate method*.
      #
      # #### Qualifiers
      #
      # ##### as
      #
      # Use `as` if the name of the delegate method is different from the name
      # of the delegating method.
      #
      # Here, Courier has a #deliver method, but instead of calling #deliver on
      # the PostOffice, it calls #ship:
      #
      #     class Courier
      #       attr_reader :post_office
      #
      #       def initialize
      #         @post_office = PostOffice.new
      #       end
      #
      #       def deliver(package)
      #         post_office.ship(package)
      #       end
      #     end
      #
      #     # RSpec
      #     describe Courier do
      #       it { should delegate_method(:deliver).to(:post_office).as(:ship) }
      #     end
      #
      #     # Minitest
      #     class CourierTest < Minitest::Test
      #       should delegate_method(:deliver).to(:post_office).as(:ship)
      #     end
      #
      # ##### with_prefix
      #
      # Use `with_prefix` when using Rails's `delegate` helper along with the
      # `:prefix` option.
      #
      #     class Page < ActiveRecord::Base
      #       belongs_to :site
      #       delegate :name, to: :site, prefix: true
      #       delegate :title, to: :site, prefix: :root
      #     end
      #
      #     # RSpec
      #     describe Page do
      #       it { should delegate_method(:name).to(:site).with_prefix }
      #       it { should delegate_method(:name).to(:site).with_prefix(true) }
      #       it { should delegate_method(:title).to(:site).with_prefix(:root) }
      #     end
      #
      #     # Minitest
      #     class PageTest < Minitest::Test
      #       should delegate_method(:name).to(:site).with_prefix
      #       should delegate_method(:name).to(:site).with_prefix(true)
      #       should delegate_method(:title).to(:site).with_prefix(:root)
      #     end
      #
      # ##### with_arguments
      #
      # Use `with_arguments` to assert that the delegate method is called with
      # certain arguments. Note that this qualifier can only be used when the
      # delegating method takes no arguments; it does not support delegating
      # or delegate methods that take arbitrary arguments.
      #
      # Here, when Courier#deliver_package calls PostOffice#deliver_package, it
      # adds an options hash:
      #
      #     class Courier
      #       attr_reader :post_office
      #
      #       def initialize
      #         @post_office = PostOffice.new
      #       end
      #
      #       def deliver_package
      #         post_office.deliver_package(expedited: true)
      #       end
      #     end
      #
      #     # RSpec
      #     describe Courier do
      #       it do
      #         should delegate_method(:deliver_package).
      #           to(:post_office).
      #           with_arguments(expedited: true)
      #       end
      #     end
      #
      #     # Minitest
      #     class CourierTest < Minitest::Test
      #       should delegate_method(:deliver_package).
      #         to(:post_office).
      #         with_arguments(expedited: true)
      #     end
      #
      # ##### allow_nil
      #
      # Use `allow_nil` if the delegation accounts for the fact that your
      # delegate object could be nil. (This is mostly intended as an analogue to
      # the `allow_nil` option that Rails' `delegate` helper takes.)
      #
      #     class Account
      #       delegate :plan, to: :subscription, allow_nil: true
      #     end
      #
      #     # RSpec
      #     describe Account do
      #       it { should delegate_method(:plan).to(:subscription).allow_nil }
      #     end
      #
      #     # Minitest
      #     class PageTest < Minitest::Test
      #       should delegate_method(:plan).to(:subscription).allow_nil
      #     end
      #
      # @return [DelegateMethodMatcher]
      #
      def delegate_method(delegating_method)
        DelegateMethodMatcher.new(delegating_method).in_context(self)
      end

      # @private
      class DelegateMethodMatcher
        def initialize(delegating_method)
          @delegating_method = delegating_method

          @delegate_method = @delegating_method
          @delegate_object = Doublespeak::ObjectDouble.new

          @context = nil
          @subject = nil
          @delegate_object_reader_method = nil
          @delegated_arguments = []
          @expects_to_allow_nil_delegate_object = false
        end

        def in_context(context)
          @context = MatcherContext.new(context)
          self
        end

        def matches?(subject)
          @subject = subject

          ensure_delegate_object_has_been_specified!

          subject_has_delegating_method? &&
            subject_has_delegate_object_reader_method? &&
            subject_delegates_to_delegate_object_correctly? &&
            subject_handles_nil_delegate_object?
        end

        def description
          string =
            "delegate #{formatted_delegating_method_name} to the " +
            "#{formatted_delegate_object_reader_method_name} object"

          if delegated_arguments.any?
            string << " passing arguments #{delegated_arguments.inspect}"
          end

          if delegate_method != delegating_method
            string << " as #{formatted_delegate_method}"
          end

          if expects_to_allow_nil_delegate_object?
            string << ', allowing '
            string << formatted_delegate_object_reader_method_name
            string << ' to return nil'
          end

          string
        end

        def to(delegate_object_reader_method)
          @delegate_object_reader_method = delegate_object_reader_method
          self
        end

        def as(delegate_method)
          @delegate_method = delegate_method
          self
        end

        def with_arguments(*arguments)
          @delegated_arguments = arguments
          self
        end

        def with_prefix(prefix = nil)
          @delegating_method =
            :"#{build_delegating_method_prefix(prefix)}_#{delegate_method}"
          delegate_method
          self
        end

        def allow_nil
          @expects_to_allow_nil_delegate_object = true
          self
        end

        def build_delegating_method_prefix(prefix)
          case prefix
          when true, nil then delegate_object_reader_method
          else prefix
          end
        end

        def failure_message
          message = "Expected #{class_under_test} to #{description}.\n\n"

          if failed_to_allow_nil_delegate_object?
            message << formatted_delegating_method_name(include_module: true)
            message << ' did delegate to '
            message << formatted_delegate_object_reader_method_name
            message << ' when it was non-nil, but it failed to account '
            message << 'for when '
            message << formatted_delegate_object_reader_method_name
            message << ' *was* nil.'
          else
            message << 'Method calls sent to '
            message << formatted_delegate_object_reader_method_name(
              include_module: true,
            )
            message << ": #{formatted_calls_on_delegate_object}"
          end

          Shoulda::Matchers.word_wrap(message)
        end

        def failure_message_when_negated
          "Expected #{class_under_test} not to #{description}, but it did."
        end

        protected

        attr_reader \
          :context,
          :delegated_arguments,
          :delegating_method,
          :method,
          :delegate_method,
          :delegate_object,
          :delegate_object_reader_method

        def subject
          @subject
        end

        def subject_is_a_class?
          if @subject
            @subject.is_a?(Class)
          else
            context.subject_is_a_class?
          end
        end

        def class_under_test
          if subject_is_a_class?
            subject
          else
            subject.class
          end
        end

        def expects_to_allow_nil_delegate_object?
          @expects_to_allow_nil_delegate_object
        end

        def formatted_delegate_method(options = {})
          formatted_method_name_for(delegate_method, options)
        end

        def formatted_delegating_method_name(options = {})
          formatted_method_name_for(delegating_method, options)
        end

        def formatted_delegate_object_reader_method_name(options = {})
          formatted_method_name_for(delegate_object_reader_method, options)
        end

        def formatted_method_name_for(method_name, options)
          possible_class_under_test(options) +
            class_or_instance_method_indicator +
            method_name.to_s
        end

        def possible_class_under_test(options)
          if options[:include_module]
            class_under_test.to_s
          else
            ''
          end
        end

        def class_or_instance_method_indicator
          if subject_is_a_class?
            '.'
          else
            '#'
          end
        end

        def delegate_object_received_call?
          calls_to_delegate_method.any?
        end

        def delegate_object_received_call_with_delegated_arguments?
          calls_to_delegate_method.any? do |call|
            call.args == delegated_arguments
          end
        end

        def subject_has_delegating_method?
          subject.respond_to?(delegating_method)
        end

        def subject_has_delegate_object_reader_method?
          subject.respond_to?(delegate_object_reader_method, true)
        end

        def ensure_delegate_object_has_been_specified!
          if delegate_object_reader_method.to_s.empty?
            raise DelegateObjectNotSpecified
          end
        end

        def subject_delegates_to_delegate_object_correctly?
          call_delegating_method_with_delegate_method_returning(delegate_object)

          if delegated_arguments.any?
            delegate_object_received_call_with_delegated_arguments?
          else
            delegate_object_received_call?
          end
        end

        def subject_handles_nil_delegate_object?
          @subject_handled_nil_delegate_object =
            if expects_to_allow_nil_delegate_object?
              begin
                call_delegating_method_with_delegate_method_returning(nil)
                true
              rescue Module::DelegationError
                false
              rescue NoMethodError => e
                if e.message =~
                   /undefined method `#{delegate_method}' for nil:NilClass/
                  false
                else
                  raise e
                end
              end
            else
              true
            end
        end

        def failed_to_allow_nil_delegate_object?
          expects_to_allow_nil_delegate_object? &&
            !@subject_handled_nil_delegate_object
        end

        def call_delegating_method_with_delegate_method_returning(value)
          register_subject_double_collection_to(value)

          Doublespeak.with_doubles_activated do
            subject.public_send(delegating_method, *delegated_arguments)
          end
        end

        def register_subject_double_collection_to(returned_value)
          double_collection =
            Doublespeak.double_collection_for(subject.singleton_class)
          double_collection.register_stub(delegate_object_reader_method).
            to_return(returned_value)
        end

        def calls_to_delegate_method
          delegate_object.calls_to(delegate_method)
        end

        def calls_on_delegate_object
          delegate_object.calls
        end

        def formatted_calls_on_delegate_object
          string = ''

          if calls_on_delegate_object.any?
            string << "\n\n"
            calls_on_delegate_object.each_with_index do |call, i|
              name = call.method_name
              args = call.args.map(&:inspect).join(', ')
              string << "#{i + 1}) #{name}(#{args})\n"
            end
          else
            string << ' (none)'
          end

          string.rstrip!

          string
        end
      end
    end
  end
end
