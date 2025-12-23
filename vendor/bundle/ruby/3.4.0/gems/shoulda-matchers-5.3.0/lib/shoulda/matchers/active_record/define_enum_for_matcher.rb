module Shoulda
  module Matchers
    module ActiveRecord
      # The `define_enum_for` matcher is used to test that the `enum` macro has
      # been used to decorate an attribute with enum capabilities.
      #
      #     class Process < ActiveRecord::Base
      #       enum status: [:running, :stopped, :suspended]
      #
      #       alias_attribute :kind, :SomeLegacyField
      #
      #       enum kind: [:foo, :bar]
      #     end
      #
      #     # RSpec
      #     RSpec.describe Process, type: :model do
      #       it { should define_enum_for(:status) }
      #       it { should define_enum_for(:kind) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProcessTest < ActiveSupport::TestCase
      #       should define_enum_for(:status)
      #       should define_enum_for(:kind)
      #     end
      #
      # #### Qualifiers
      #
      # ##### with_values
      #
      # Use `with_values` to test that the attribute can only receive a certain
      # set of possible values.
      #
      #     class Process < ActiveRecord::Base
      #       enum status: [:running, :stopped, :suspended]
      #     end
      #
      #     # RSpec
      #     RSpec.describe Process, type: :model do
      #       it do
      #         should define_enum_for(:status).
      #           with_values([:running, :stopped, :suspended])
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProcessTest < ActiveSupport::TestCase
      #       should define_enum_for(:status).
      #         with_values([:running, :stopped, :suspended])
      #     end
      #
      # If the values backing your enum attribute are arbitrary instead of a
      # series of integers starting from 0, pass a hash to `with_values` instead
      # of an array:
      #
      #     class Process < ActiveRecord::Base
      #       enum status: {
      #         running: 0,
      #         stopped: 1,
      #         suspended: 3,
      #         other: 99
      #       }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Process, type: :model do
      #       it do
      #         should define_enum_for(:status).
      #           with_values(running: 0, stopped: 1, suspended: 3, other: 99)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProcessTest < ActiveSupport::TestCase
      #       should define_enum_for(:status).
      #         with_values(running: 0, stopped: 1, suspended: 3, other: 99)
      #     end
      #
      # ##### backed_by_column_of_type
      #
      # Use `backed_by_column_of_type` when the column backing your column type
      # is a string instead of an integer:
      #
      #     class LoanApplication < ActiveRecord::Base
      #       enum status: {
      #         active: "active",
      #         pending: "pending",
      #         rejected: "rejected"
      #       }
      #     end
      #
      #     # RSpec
      #     RSpec.describe LoanApplication, type: :model do
      #       it do
      #         should define_enum_for(:status).
      #           with_values(
      #             active: "active",
      #             pending: "pending",
      #             rejected: "rejected"
      #           ).
      #           backed_by_column_of_type(:string)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class LoanApplicationTest < ActiveSupport::TestCase
      #       should define_enum_for(:status).
      #         with_values(
      #           active: "active",
      #           pending: "pending",
      #           rejected: "rejected"
      #         ).
      #         backed_by_column_of_type(:string)
      #     end
      #
      ## ##### with_prefix
      #
      # Use `with_prefix` to test that the enum is defined with a `_prefix`
      # option (Rails 6+ only). Can take either a boolean or a symbol:
      #
      #     class Issue < ActiveRecord::Base
      #       enum status: [:open, :closed], _prefix: :old
      #     end
      #
      #     # RSpec
      #     RSpec.describe Issue, type: :model do
      #       it do
      #         should define_enum_for(:status).
      #           with_values([:open, :closed]).
      #           with_prefix(:old)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProcessTest < ActiveSupport::TestCase
      #       should define_enum_for(:status).
      #         with_values([:open, :closed]).
      #         with_prefix(:old)
      #     end
      #
      # ##### with_suffix
      #
      # Use `with_suffix` to test that the enum is defined with a `_suffix`
      # option (Rails 5 only). Can take either a boolean or a symbol:
      #
      #     class Issue < ActiveRecord::Base
      #       enum status: [:open, :closed], _suffix: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Issue, type: :model do
      #       it do
      #         should define_enum_for(:status).
      #           with_values([:open, :closed]).
      #           with_suffix
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProcessTest < ActiveSupport::TestCase
      #       should define_enum_for(:status).
      #         with_values([:open, :closed]).
      #         with_suffix
      #     end
      #
      # ##### without_scopes
      #
      # Use `without_scopes` to test that the enum is defined with
      # '_scopes: false' option (Rails 5 only). Can take either a boolean or a
      # symbol:
      #
      #     class Issue < ActiveRecord::Base
      #       enum status: [:open, :closed], _scopes: false
      #     end
      #
      #     # RSpec
      #     RSpec.describe Issue, type: :model do
      #       it do
      #         should define_enum_for(:status).
      #           without_scopes
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProcessTest < ActiveSupport::TestCase
      #       should define_enum_for(:status).
      #         without_scopes
      #     end
      #
      # @return [DefineEnumForMatcher]
      #
      def define_enum_for(attribute_name)
        DefineEnumForMatcher.new(attribute_name)
      end

      # @private
      class DefineEnumForMatcher
        def initialize(attribute_name)
          @attribute_name = attribute_name
          @options = { expected_enum_values: [], scopes: true }
        end

        def description
          description = "#{simple_description} backed by "
          description << Shoulda::Matchers::Util.a_or_an(expected_column_type)

          if expected_enum_values.any?
            description << ' with values '
            description << Shoulda::Matchers::Util.inspect_value(
              expected_enum_values,
            )
          end

          if options[:prefix]
            description << ", prefix: #{options[:prefix].inspect}"
          end

          if options[:suffix]
            description << ", suffix: #{options[:suffix].inspect}"
          end

          description
        end

        def with_values(expected_enum_values)
          options[:expected_enum_values] = expected_enum_values
          self
        end

        def with(expected_enum_values)
          Shoulda::Matchers.warn_about_deprecated_method(
            'The `with` qualifier on `define_enum_for`',
            '`with_values`',
          )
          with_values(expected_enum_values)
        end

        def with_prefix(expected_prefix = true)
          options[:prefix] = expected_prefix
          self
        end

        def with_suffix(expected_suffix = true)
          options[:suffix] = expected_suffix
          self
        end

        def backed_by_column_of_type(expected_column_type)
          options[:expected_column_type] = expected_column_type
          self
        end

        def without_scopes
          options[:scopes] = false
          self
        end

        def matches?(subject)
          @record = subject

          enum_defined? &&
            enum_values_match? &&
            column_type_matches? &&
            enum_value_methods_exist? &&
            scope_presence_matches?
        end

        def failure_message
          message =
            if enum_defined?
              "Expected #{model} to #{expectation}. "
            else
              "Expected #{model} to #{expectation}, but "
            end

          message << "#{failure_message_continuation}."

          Shoulda::Matchers.word_wrap(message)
        end

        def failure_message_when_negated
          message = "Expected #{model} not to #{expectation}, but it did."
          Shoulda::Matchers.word_wrap(message)
        end

        private

        attr_reader :attribute_name, :options, :record,
          :failure_message_continuation

        def expectation # rubocop:disable Metrics/MethodLength
          if enum_defined?
            expectation = "#{simple_description} backed by "
            expectation << Shoulda::Matchers::Util.a_or_an(expected_column_type)

            if expected_enum_values.any?
              expectation << ', mapping '
              expectation << presented_enum_mapping(
                normalized_expected_enum_values,
              )
            end

            if expected_prefix
              expectation <<
                if expected_suffix
                  ', '
                else
                  ' and '
                end

              expectation << 'prefixing accessor methods with '
              expectation << "#{expected_prefix}_".inspect
            end

            if expected_suffix
              expectation <<
                if expected_prefix
                  ', and '
                else
                  ' and '
                end

              expectation << 'suffixing accessor methods with '
              expectation << "_#{expected_suffix}".inspect
            end

            if exclude_scopes?
              expectation << ' with no scopes'
            end

            expectation
          else
            simple_description
          end
        end

        def simple_description
          "define :#{attribute_name} as an enum"
        end

        def presented_enum_mapping(enum_values)
          enum_values.
            map { |output_to_input|
              output_to_input.
                map(&Shoulda::Matchers::Util.method(:inspect_value)).
                join(' to ')
            }.
            to_sentence
        end

        def normalized_expected_enum_values
          to_hash(expected_enum_values)
        end

        def expected_enum_value_names
          to_array(expected_enum_values)
        end

        def expected_enum_values
          options[:expected_enum_values]
        end

        def normalized_actual_enum_values
          to_hash(actual_enum_values)
        end

        def actual_enum_values
          model.send(attribute_name.to_s.pluralize)
        end

        def enum_defined?
          if model.defined_enums.include?(attribute_name.to_s)
            true
          else
            @failure_message_continuation =
              "no such enum exists on #{model}"
            false
          end
        end

        def enum_values_match?
          passed =
            expected_enum_values.empty? ||
            normalized_actual_enum_values == normalized_expected_enum_values

          if passed
            true
          else
            @failure_message_continuation =
              "However, #{attribute_name.inspect} actually maps " +
              presented_enum_mapping(normalized_actual_enum_values)
            false
          end
        end

        def column_type_matches?
          if column.type == expected_column_type.to_sym
            true
          else
            @failure_message_continuation =
              "However, #{attribute_name.inspect} is "\
              "#{Shoulda::Matchers::Util.a_or_an(column.type)}"\
              ' column'
            false
          end
        end

        def expected_column_type
          options[:expected_column_type] || :integer
        end

        def column
          key = attribute_name.to_s
          column_name = model.attribute_alias(key) || key

          model.columns_hash[column_name]
        end

        def model
          record.class
        end

        def enum_value_methods_exist?
          if instance_methods_exist?
            true
          else
            message = missing_methods_message

            message << " (we can't tell which)"

            @failure_message_continuation = message

            false
          end
        end

        def scope_presence_matches?
          if exclude_scopes?
            if singleton_methods_exist?
              message = "#{attribute_name.inspect} does map to these values "
              message << 'but class scope methods were present'

              @failure_message_continuation = message

              false
            else
              true
            end
          elsif singleton_methods_exist?
            true
          else
            if enum_defined?
              message = 'But the class scope methods are not present'
            else
              message = missing_methods_message

              message << 'or the class scope methods are not present'
              message << " (we can't tell which)"
            end

            @failure_message_continuation = message

            false
          end
        end

        def missing_methods_message
          message = "#{attribute_name.inspect} does map to these "
          message << 'values, but the enum is '

          if expected_prefix
            if expected_suffix
              message << 'configured with either a different prefix or '
              message << 'suffix, or no prefix or suffix at all'
            else
              message << 'configured with either a different prefix or no '
              message << 'prefix at all'
            end
          elsif expected_suffix
            message << 'configured with either a different suffix or no '
            message << 'suffix at all'
          else
            ''
          end
        end

        def singleton_methods_exist?
          expected_singleton_methods.all? do |method|
            model.singleton_methods.include?(method)
          end
        end

        def instance_methods_exist?
          expected_instance_methods.all? do |method|
            record.methods.include?(method)
          end
        end

        def expected_singleton_methods
          expected_enum_value_names.map do |name|
            [expected_prefix, name, expected_suffix].
              select(&:present?).
              join('_').
              to_sym
          end
        end

        def expected_instance_methods
          methods = expected_enum_value_names.map do |name|
            [expected_prefix, name, expected_suffix].
              select(&:present?).
              join('_')
          end

          methods.flat_map do |m|
            ["#{m}?".to_sym, "#{m}!".to_sym]
          end
        end

        def expected_prefix
          if options.include?(:prefix)
            if options[:prefix] == true
              attribute_name
            else
              options[:prefix]
            end
          end
        end

        def expected_suffix
          if options.include?(:suffix)
            if options[:suffix] == true
              attribute_name
            else
              options[:suffix]
            end
          end
        end

        def exclude_scopes?
          !options[:scopes]
        end

        def to_hash(value)
          if value.is_a?(Array)
            value.each_with_index.inject({}) do |hash, (item, index)|
              hash.merge(item.to_s => index)
            end
          else
            value.stringify_keys
          end
        end

        def to_array(value)
          if value.is_a?(Array)
            value.map(&:to_s)
          else
            value.keys.map(&:to_s)
          end
        end
      end
    end
  end
end
