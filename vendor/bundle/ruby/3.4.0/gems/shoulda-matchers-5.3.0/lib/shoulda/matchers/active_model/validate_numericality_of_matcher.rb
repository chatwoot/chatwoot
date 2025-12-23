module Shoulda
  module Matchers
    module ActiveModel
      # The `validate_numericality_of` matcher tests usage of the
      # `validates_numericality_of` validation.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :gpa
      #
      #       validates_numericality_of :gpa
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should validate_numericality_of(:gpa) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:gpa)
      #     end
      #
      # #### Qualifiers
      #
      # ##### on
      #
      # Use `on` if your validation applies only under a certain context.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :number_of_dependents
      #
      #       validates_numericality_of :number_of_dependents, on: :create
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:number_of_dependents).
      #           on(:create)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:number_of_dependents).on(:create)
      #     end
      #
      # ##### only_integer
      #
      # Use `only_integer` to test usage of the `:only_integer` option. This
      # asserts that your attribute only allows integer numbers and disallows
      # non-integer ones.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :age
      #
      #       validates_numericality_of :age, only_integer: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should validate_numericality_of(:age).only_integer }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:age).only_integer
      #     end
      #
      # ##### is_less_than
      #
      # Use `is_less_than` to test usage of the the `:less_than` option. This
      # asserts that the attribute can take a number which is less than the
      # given value and cannot take a number which is greater than or equal to
      # it.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :number_of_cars
      #
      #       validates_numericality_of :number_of_cars, less_than: 2
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:number_of_cars).
      #           is_less_than(2)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:number_of_cars).
      #         is_less_than(2)
      #     end
      #
      # ##### is_less_than_or_equal_to
      #
      # Use `is_less_than_or_equal_to` to test usage of the
      # `:less_than_or_equal_to` option. This asserts that the attribute can
      # take a number which is less than or equal to the given value and cannot
      # take a number which is greater than it.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :birth_year
      #
      #       validates_numericality_of :birth_year, less_than_or_equal_to: 1987
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:birth_year).
      #           is_less_than_or_equal_to(1987)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:birth_year).
      #         is_less_than_or_equal_to(1987)
      #     end
      #
      # ##### is_equal_to
      #
      # Use `is_equal_to` to test usage of the `:equal_to` option. This asserts
      # that the attribute can take a number which is equal to the given value
      # and cannot take a number which is not equal.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :weight
      #
      #       validates_numericality_of :weight, equal_to: 150
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should validate_numericality_of(:weight).is_equal_to(150) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:weight).is_equal_to(150)
      #     end
      #
      # ##### is_greater_than_or_equal_to
      #
      # Use `is_greater_than_or_equal_to` to test usage of the
      # `:greater_than_or_equal_to` option. This asserts that the attribute can
      # take a number which is greater than or equal to the given value and
      # cannot take a number which is less than it.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :height
      #
      #       validates_numericality_of :height, greater_than_or_equal_to: 55
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:height).
      #           is_greater_than_or_equal_to(55)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:height).
      #         is_greater_than_or_equal_to(55)
      #     end
      #
      # ##### is_greater_than
      #
      # Use `is_greater_than` to test usage of the `:greater_than` option.
      # This asserts that the attribute can take a number which is greater than
      # the given value and cannot take a number less than or equal to it.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :legal_age
      #
      #       validates_numericality_of :legal_age, greater_than: 21
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:legal_age).
      #           is_greater_than(21)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:legal_age).
      #         is_greater_than(21)
      #     end
      #
      # ##### is_other_than
      #
      # Use `is_other_than` to test usage of the `:other_than` option.
      # This asserts that the attribute can take a number which is not equal to
      # the given value.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :legal_age
      #
      #       validates_numericality_of :legal_age, other_than: 21
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:legal_age).
      #           is_other_than(21)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:legal_age).
      #         is_other_than(21)
      #     end
      #
      # ##### even
      #
      # Use `even` to test usage of the `:even` option. This asserts that the
      # attribute can take odd numbers and cannot take even ones.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :birth_month
      #
      #       validates_numericality_of :birth_month, even: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should validate_numericality_of(:birth_month).even }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:birth_month).even
      #     end
      #
      # ##### odd
      #
      # Use `odd` to test usage of the `:odd` option. This asserts that the
      # attribute can take a number which is odd and cannot take a number which
      # is even.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :birth_day
      #
      #       validates_numericality_of :birth_day, odd: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should validate_numericality_of(:birth_day).odd }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:birth_day).odd
      #     end
      #
      # ##### is_in
      #
      # Use `is_in` to test usage of the `:in` option.
      # This asserts that the attribute can take a number which is contained
      # in the given range.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :legal_age
      #
      #       validates_numericality_of :birth_month, in: 1..12
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:birth_month).
      #           is_in(1..12)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:birth_month).
      #         is_in(1..12)
      #     end
      #
      # ##### with_message
      #
      # Use `with_message` if you are using a custom validation message.
      #
      #     class Person
      #       include ActiveModel::Model
      #       attr_accessor :number_of_dependents
      #
      #       validates_numericality_of :number_of_dependents,
      #         message: 'Number of dependents must be a number'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should validate_numericality_of(:number_of_dependents).
      #           with_message('Number of dependents must be a number')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:number_of_dependents).
      #         with_message('Number of dependents must be a number')
      #     end
      #
      # ##### allow_nil
      #
      # Use `allow_nil` to assert that the attribute allows nil.
      #
      #     class Post
      #       include ActiveModel::Model
      #       attr_accessor :age
      #
      #       validates_numericality_of :age, allow_nil: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_numericality_of(:age).allow_nil }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_numericality_of(:age).allow_nil
      #     end
      #
      # @return [ValidateNumericalityOfMatcher]
      #
      def validate_numericality_of(attr)
        ValidateNumericalityOfMatcher.new(attr)
      end

      # @private
      class ValidateNumericalityOfMatcher
        NUMERIC_NAME = 'number'.freeze
        DEFAULT_DIFF_TO_COMPARE = 1

        include Qualifiers::IgnoringInterferenceByWriter

        attr_reader :diff_to_compare

        def initialize(attribute)
          super
          @attribute = attribute
          @submatchers = []
          @diff_to_compare = DEFAULT_DIFF_TO_COMPARE
          @expects_custom_validation_message = false
          @expects_to_allow_nil = false
          @expects_strict = false
          @allowed_type_adjective = nil
          @allowed_type_name = 'number'
          @context = nil
          @expected_message = nil
        end

        def strict
          @expects_strict = true
          self
        end

        def expects_strict?
          @expects_strict
        end

        def only_integer
          prepare_submatcher(
            NumericalityMatchers::OnlyIntegerMatcher.new(self, @attribute),
          )
          self
        end

        def allow_nil
          @expects_to_allow_nil = true
          prepare_submatcher(
            AllowValueMatcher.new(nil).
              for(@attribute).
              with_message(:not_a_number),
          )
          self
        end

        def expects_to_allow_nil?
          @expects_to_allow_nil
        end

        def odd
          prepare_submatcher(
            NumericalityMatchers::OddNumberMatcher.new(self, @attribute),
          )
          self
        end

        def even
          prepare_submatcher(
            NumericalityMatchers::EvenNumberMatcher.new(self, @attribute),
          )
          self
        end

        def is_greater_than(value)
          prepare_submatcher(comparison_matcher_for(value, :>).for(@attribute))
          self
        end

        def is_greater_than_or_equal_to(value)
          prepare_submatcher(comparison_matcher_for(value, :>=).for(@attribute))
          self
        end

        def is_equal_to(value)
          prepare_submatcher(comparison_matcher_for(value, :==).for(@attribute))
          self
        end

        def is_less_than(value)
          prepare_submatcher(comparison_matcher_for(value, :<).for(@attribute))
          self
        end

        def is_less_than_or_equal_to(value)
          prepare_submatcher(comparison_matcher_for(value, :<=).for(@attribute))
          self
        end

        def is_other_than(value)
          prepare_submatcher(comparison_matcher_for(value, :!=).for(@attribute))
          self
        end

        def is_in(range)
          prepare_submatcher(
            NumericalityMatchers::RangeMatcher.new(self, @attribute, range),
          )
          self
        end

        def with_message(message)
          @expects_custom_validation_message = true
          @expected_message = message
          self
        end

        def expects_custom_validation_message?
          @expects_custom_validation_message
        end

        def on(context)
          @context = context
          self
        end

        def matches?(subject)
          matches_or_does_not_match?(subject)
          first_submatcher_that_fails_to_match.nil?
        end

        def does_not_match?(subject)
          matches_or_does_not_match?(subject)
          first_submatcher_that_fails_to_not_match.nil?
        end

        def simple_description
          description = ''

          description << "validate that :#{@attribute} looks like "
          description << Shoulda::Matchers::Util.a_or_an(full_allowed_type)

          if range_description.present?
            description << " #{range_description}"
          end

          if comparison_descriptions.present?
            description << " #{comparison_descriptions}"
          end

          description
        end

        def description
          ValidationMatcher::BuildDescription.call(self, simple_description)
        end

        def failure_message
          overall_failure_message.dup.tap do |message|
            message << "\n"
            message << failure_message_for_first_submatcher_that_fails_to_match
          end
        end

        def failure_message_when_negated
          overall_failure_message_when_negated.dup.tap do |message|
            message << "\n"
            message <<
              failure_message_for_first_submatcher_that_fails_to_not_match
          end
        end

        def given_numeric_column?
          attribute_is_active_record_column? &&
            [:integer, :float, :decimal].include?(column_type)
        end

        private

        def matches_or_does_not_match?(subject)
          @subject = subject
          @number_of_submatchers = @submatchers.size

          add_disallow_value_matcher
          qualify_submatchers
        end

        def overall_failure_message
          Shoulda::Matchers.word_wrap(
            "Expected #{model.name} to #{description}, but this could not "\
            'be proved.',
          )
        end

        def overall_failure_message_when_negated
          Shoulda::Matchers.word_wrap(
            "Expected #{model.name} not to #{description}, but this could not "\
            'be proved.',
          )
        end

        def attribute_is_active_record_column?
          columns_hash.key?(@attribute.to_s)
        end

        def column_type
          columns_hash[@attribute.to_s].type
        end

        def columns_hash
          if @subject.class.respond_to?(:columns_hash)
            @subject.class.columns_hash
          else
            {}
          end
        end

        def add_disallow_value_matcher
          disallow_value_matcher = DisallowValueMatcher.
            new(non_numeric_value).
            for(@attribute).
            with_message(:not_a_number)

          add_submatcher(disallow_value_matcher)
        end

        def prepare_submatcher(submatcher)
          add_submatcher(submatcher)
          submatcher
        end

        def comparison_matcher_for(value, operator)
          NumericalityMatchers::ComparisonMatcher.
            new(self, value, operator).
            for(@attribute)
        end

        def add_submatcher(submatcher)
          if submatcher.respond_to?(:allowed_type_name)
            @allowed_type_name = submatcher.allowed_type_name
          end

          if submatcher.respond_to?(:allowed_type_adjective)
            @allowed_type_adjective = submatcher.allowed_type_adjective
          end

          if submatcher.respond_to?(:diff_to_compare)
            @diff_to_compare = [
              @diff_to_compare,
              submatcher.diff_to_compare,
            ].max
          end

          @submatchers << submatcher
        end

        def qualify_submatchers
          @submatchers.each do |submatcher|
            if @expects_strict
              submatcher.strict(@expects_strict)
            end

            if @expected_message.present?
              submatcher.with_message(@expected_message)
            end

            if @context
              submatcher.on(@context)
            end

            submatcher.ignoring_interference_by_writer(
              ignore_interference_by_writer,
            )
          end
        end

        def number_of_submatchers_for_failure_message
          if has_been_qualified?
            @submatchers.size - 1
          else
            @submatchers.size
          end
        end

        def has_been_qualified?
          @submatchers.any? do |submatcher|
            Shoulda::Matchers::RailsShim.parent_of(submatcher.class) ==
              NumericalityMatchers
          end
        end

        def first_submatcher_that_fails_to_match
          @_first_submatcher_that_fails_to_match ||=
            @submatchers.detect do |submatcher|
              !submatcher.matches?(@subject)
            end
        end

        def first_submatcher_that_fails_to_not_match
          @_first_submatcher_that_fails_to_not_match ||=
            @submatchers.detect do |submatcher|
              !submatcher.does_not_match?(@subject)
            end
        end

        def failure_message_for_first_submatcher_that_fails_to_match
          build_submatcher_failure_message_for(
            first_submatcher_that_fails_to_match,
            :failure_message,
          )
        end

        def failure_message_for_first_submatcher_that_fails_to_not_match
          build_submatcher_failure_message_for(
            first_submatcher_that_fails_to_not_match,
            :failure_message_when_negated,
          )
        end

        def build_submatcher_failure_message_for(
          submatcher,
          failure_message_method
        )
          failure_message = submatcher.public_send(failure_message_method)
          submatcher_description = submatcher.simple_description.
            sub(/\bvalidate that\b/, 'validates').
            sub(/\bdisallow\b/, 'disallows').
            sub(/\ballow\b/, 'allows')
          submatcher_message =
            if number_of_submatchers_for_failure_message > 1
              "In checking that #{model.name} #{submatcher_description}, " +
                failure_message[0].downcase +
                failure_message[1..]
            else
              failure_message
            end

          Shoulda::Matchers.word_wrap(submatcher_message, indent: 2)
        end

        def full_allowed_type
          "#{@allowed_type_adjective} #{@allowed_type_name}".strip
        end

        def comparison_descriptions
          description_array = submatcher_comparison_descriptions
          if description_array.empty?
            ''
          else
            submatcher_comparison_descriptions.join(' and ')
          end
        end

        def submatcher_comparison_descriptions
          @submatchers.inject([]) do |arr, submatcher|
            if submatcher.respond_to? :comparison_description
              arr << submatcher.comparison_description
            end
            arr
          end
        end

        def range_description
          range_submatcher = @submatchers.detect do |submatcher|
            submatcher.respond_to? :range_description
          end

          range_submatcher&.range_description
        end

        def model
          @subject.class
        end

        def non_numeric_value
          'abcd'
        end
      end
    end
  end
end
