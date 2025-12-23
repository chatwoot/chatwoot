module Shoulda
  module Matchers
    module ActiveRecord
      # The `validate_uniqueness_of` matcher tests usage of the
      # `validates_uniqueness_of` validation. It first checks for an existing
      # instance of your model in the database, creating one if necessary. It
      # then takes a new instance of that model and asserts that it fails
      # validation if the attribute or attributes you've specified in the
      # validation are set to values which are the same as those of the
      # pre-existing record (thereby failing the uniqueness check).
      #
      #     class Post < ActiveRecord::Base
      #       validates :permalink, uniqueness: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:permalink) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:permalink)
      #     end
      #
      # #### Caveat
      #
      # This matcher works a bit differently than other matchers. As noted
      # before, it will create an instance of your model if one doesn't already
      # exist. Sometimes this step fails, especially if you have database-level
      # restrictions on any attributes other than the one which is unique. In
      # this case, the solution is to populate these attributes with values
      # before you call `validate_uniqueness_of`.
      #
      # For example, say you have the following migration and model:
      #
      #     class CreatePosts < ActiveRecord::Migration
      #       def change
      #         create_table :posts do |t|
      #           t.string :title
      #           t.text :content, null: false
      #         end
      #       end
      #     end
      #
      #     class Post < ActiveRecord::Base
      #       validates :title, uniqueness: true
      #     end
      #
      # You may be tempted to test the model like this:
      #
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:title) }
      #     end
      #
      # However, running this test will fail with an exception such as:
      #
      #     Shoulda::Matchers::ActiveRecord::ValidateUniquenessOfMatcher::ExistingRecordInvalid:
      #       validate_uniqueness_of works by matching a new record against an
      #       existing record. If there is no existing record, it will create one
      #       using the record you provide.
      #
      #       While doing this, the following error was raised:
      #
      #         PG::NotNullViolation: ERROR:  null value in column "content" violates not-null constraint
      #         DETAIL:  Failing row contains (1, null, null).
      #         : INSERT INTO "posts" DEFAULT VALUES RETURNING "id"
      #
      #       The best way to fix this is to provide the matcher with a record where
      #       any required attributes are filled in with valid values beforehand.
      #
      # (The exact error message will differ depending on which database you're
      # using, but you get the idea.)
      #
      # This happens because `validate_uniqueness_of` tries to create a new post
      # but cannot do so because of the `content` attribute: though unrelated to
      # this test, it nevertheless needs to be filled in. As indicated at the
      # end of the error message, the solution is to build a custom Post object
      # ahead of time with `content` filled in:
      #
      #     RSpec.describe Post, type: :model do
      #       describe "validations" do
      #         subject { Post.new(content: "Here is the content") }
      #         it { should validate_uniqueness_of(:title) }
      #       end
      #     end
      #
      # Or, if you're using
      # [FactoryBot](https://github.com/thoughtbot/factory_bot) and you have a
      # `post` factory defined which automatically fills in `content`, you can
      # say:
      #
      #     RSpec.describe Post, type: :model do
      #       describe "validations" do
      #         subject { FactoryBot.build(:post) }
      #         it { should validate_uniqueness_of(:title) }
      #       end
      #     end
      #
      # #### Qualifiers
      #
      # Use `on` if your validation applies only under a certain context.
      #
      #     class Post < ActiveRecord::Base
      #       validates :title, uniqueness: true, on: :create
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:title).on(:create) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:title).on(:create)
      #     end
      #
      # ##### with_message
      #
      # Use `with_message` if you are using a custom validation message.
      #
      #     class Post < ActiveRecord::Base
      #       validates :title, uniqueness: true, message: 'Please choose another title'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it do
      #         should validate_uniqueness_of(:title).
      #           with_message('Please choose another title')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:title).
      #         with_message('Please choose another title')
      #     end
      #
      # ##### scoped_to
      #
      # Use `scoped_to` to test usage of the `:scope` option. This asserts that
      # a new record fails validation if not only the primary attribute is not
      # unique, but the scoped attributes are not unique either.
      #
      #     class Post < ActiveRecord::Base
      #       validates :slug, uniqueness: { scope: :journal_id }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:slug).scoped_to(:journal_id) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:slug).scoped_to(:journal_id)
      #     end
      #
      # NOTE: Support for testing uniqueness validation scoped to an array of
      # associations is not available.
      #
      # For more information, please refer to
      # https://github.com/thoughtbot/shoulda-matchers/issues/814
      #
      # ##### case_insensitive
      #
      # Use `case_insensitive` to test usage of the `:case_sensitive` option
      # with a false value. This asserts that the uniquable attributes fail
      # validation even if their values are a different case than corresponding
      # attributes in the pre-existing record.
      #
      #     class Post < ActiveRecord::Base
      #       validates :key, uniqueness: { case_sensitive: false }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:key).case_insensitive }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:key).case_insensitive
      #     end
      #
      # ##### ignoring_case_sensitivity
      #
      # By default, `validate_uniqueness_of` will check that the
      # validation is case sensitive: it asserts that uniquable attributes pass
      # validation when their values are in a different case than corresponding
      # attributes in the pre-existing record.
      #
      # Use `ignoring_case_sensitivity` to skip this check. This qualifier is
      # particularly handy if your model has somehow changed the behavior of
      # attribute you're testing so that it modifies the case of incoming values
      # as they are set. For instance, perhaps you've overridden the writer
      # method or added a `before_validation` callback to normalize the
      # attribute.
      #
      #     class User < ActiveRecord::Base
      #       validates :email, uniqueness: true
      #
      #       def email=(value)
      #         super(value.downcase)
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it do
      #         should validate_uniqueness_of(:email).ignoring_case_sensitivity
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:email).ignoring_case_sensitivity
      #     end
      #
      # ##### allow_nil
      #
      # Use `allow_nil` to assert that the attribute allows nil.
      #
      #     class Post < ActiveRecord::Base
      #       validates :author_id, uniqueness: true, allow_nil: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:author_id).allow_nil }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:author_id).allow_nil
      #     end
      #
      # @return [ValidateUniquenessOfMatcher]
      #
      # ##### allow_blank
      #
      # Use `allow_blank` to assert that the attribute allows a blank value.
      #
      #     class Post < ActiveRecord::Base
      #       validates :author_id, uniqueness: true, allow_blank: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Post, type: :model do
      #       it { should validate_uniqueness_of(:author_id).allow_blank }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:author_id).allow_blank
      #     end
      #
      # @return [ValidateUniquenessOfMatcher]
      #
      def validate_uniqueness_of(attr)
        ValidateUniquenessOfMatcher.new(attr)
      end

      # @private
      class ValidateUniquenessOfMatcher < ActiveModel::ValidationMatcher
        include ActiveModel::Helpers

        def initialize(attribute)
          super(attribute)
          @expected_message = :taken
          @options = {
            case_sensitivity_strategy: :sensitive,
          }
          @existing_record_created = false
          @failure_reason = nil
          @failure_reason_when_negated = nil
          @attribute_setters = {
            existing_record: AttributeSetters.new,
            new_record: AttributeSetters.new,
          }
        end

        def scoped_to(*scopes)
          @options[:scopes] = [*scopes].flatten.map(&:to_sym)
          self
        end

        def case_insensitive
          @options[:case_sensitivity_strategy] = :insensitive
          self
        end

        def ignoring_case_sensitivity
          @options[:case_sensitivity_strategy] = :ignore
          self
        end

        def allow_nil
          @options[:allow_nil] = true
          self
        end

        def expects_to_allow_nil?
          @options[:allow_nil] == true
        end

        def allow_blank
          @options[:allow_blank] = true
          self
        end

        def expects_to_allow_blank?
          @options[:allow_blank] == true
        end

        def simple_description
          description = "validate that :#{@attribute} is"
          description << description_for_case_sensitive_qualifier
          description << ' unique'

          if @options[:scopes].present?
            description << " within the scope of #{inspected_expected_scopes}"
          end

          description
        end

        def matches?(given_record)
          @given_record = given_record
          @all_records = model.all

          matches_presence_of_attribute? &&
            matches_presence_of_scopes? &&
            matches_scopes_configuration? &&
            matches_uniqueness_without_scopes? &&
            matches_uniqueness_with_case_sensitivity_strategy? &&
            matches_uniqueness_with_scopes? &&
            matches_allow_nil? &&
            matches_allow_blank?
        ensure
          Uniqueness::TestModels.remove_all
        end

        def does_not_match?(given_record)
          @given_record = given_record
          @all_records = model.all

          does_not_match_presence_of_scopes? ||
            does_not_match_scopes_configuration? ||
            does_not_match_uniqueness_without_scopes? ||
            does_not_match_uniqueness_with_case_sensitivity_strategy? ||
            does_not_match_uniqueness_with_scopes? ||
            does_not_match_allow_nil? ||
            does_not_match_allow_blank?
        ensure
          Uniqueness::TestModels.remove_all
        end

        protected

        def failure_reason
          @failure_reason || super
        end

        def failure_reason_when_negated
          @failure_reason_when_negated || super
        end

        def build_allow_or_disallow_value_matcher(args)
          super.tap do |matcher|
            matcher.failure_message_preface = method(:failure_message_preface)
            matcher.attribute_changed_value_message =
              method(:attribute_changed_value_message)
          end
        end

        private

        def case_sensitivity_strategy
          @options[:case_sensitivity_strategy]
        end

        def new_record
          unless defined?(@new_record)
            build_new_record
          end

          @new_record
        end
        alias_method :subject, :new_record

        def description_for_case_sensitive_qualifier
          case case_sensitivity_strategy
          when :sensitive
            ' case-sensitively'
          when :insensitive
            ' case-insensitively'
          else
            ''
          end
        end

        def validations
          model.validators_on(@attribute).select do |validator|
            validator.is_a?(::ActiveRecord::Validations::UniquenessValidator)
          end
        end

        def matches_scopes_configuration?
          if scopes_match?
            true
          else
            @failure_reason = 'Expected the validation '

            @failure_reason <<
              if expected_scopes.empty?
                'not to be scoped to anything, '
              else
                "to be scoped to #{inspected_expected_scopes}, "
              end

            if actual_sets_of_scopes.any?
              @failure_reason << 'but it was scoped to '
              @failure_reason << "#{inspected_actual_scopes} instead."
            else
              @failure_reason << 'but it was not scoped to anything.'
            end

            false
          end
        end

        def does_not_match_scopes_configuration?
          if scopes_match?
            @failure_reason = 'Expected the validation '

            if expected_scopes.empty?
              @failure_reason << 'to be scoped to nothing, '
              @failure_reason << 'but it was scoped to '
              @failure_reason << "#{inspected_actual_scopes} instead."
            else
              @failure_reason << 'not to be scoped to '
              @failure_reason << inspected_expected_scopes
            end

            false
          else
            true
          end
        end

        def scopes_match?
          actual_sets_of_scopes.empty? && expected_scopes.empty? ||
            actual_sets_of_scopes.any? { |scopes| scopes == expected_scopes }
        end

        def inspected_expected_scopes
          expected_scopes.map(&:inspect).to_sentence
        end

        def inspected_actual_scopes
          inspected_actual_sets_of_scopes.to_sentence(
            words_connector: ' and ',
            last_word_connector: ', and',
          )
        end

        def inspected_actual_sets_of_scopes
          inspected_sets_of_scopes = actual_sets_of_scopes.map do |scopes|
            scopes.map(&:inspect)
          end

          if inspected_sets_of_scopes.many?
            inspected_sets_of_scopes.map { |x| "(#{x.to_sentence})" }
          else
            inspected_sets_of_scopes.map(&:to_sentence)
          end
        end

        def expected_scopes
          Array.wrap(@options[:scopes])
        end

        def actual_sets_of_scopes
          validations.map do |validation|
            Array.wrap(validation.options[:scope]).map(&:to_sym)
          end.reject(&:empty?)
        end

        def matches_allow_nil?
          !expects_to_allow_nil? || (
            update_existing_record!(nil) &&
            allows_value_of(nil, @expected_message)
          )
        end

        def does_not_match_allow_nil?
          expects_to_allow_nil? && (
            update_existing_record!(nil) &&
            (@failure_reason = nil ||
              disallows_value_of(nil, @expected_message)
            )
          )
        end

        def matches_allow_blank?
          !expects_to_allow_blank? || (
            update_existing_record!('') &&
            allows_value_of('', @expected_message)
          )
        end

        def does_not_match_allow_blank?
          expects_to_allow_blank? && (
            update_existing_record!('') &&
            (@failure_reason = nil || disallows_value_of('', @expected_message))
          )
        end

        def existing_record
          unless defined?(@existing_record)
            find_or_create_existing_record
          end

          @existing_record
        end

        def find_or_create_existing_record
          @existing_record = find_existing_record

          unless @existing_record
            @existing_record = create_existing_record
            @existing_record_created = true
          end
        end

        def find_existing_record
          model.first.presence
        end

        def create_existing_record
          @given_record.tap do |existing_record|
            existing_record.save(validate: false)
          end
        rescue ::ActiveRecord::StatementInvalid => e
          raise ExistingRecordInvalid.create(underlying_exception: e)
        end

        def update_existing_record!(value)
          if existing_value_read != value
            set_attribute_on_existing_record!(@attribute, value)
            # It would be nice if we could ensure that the record was valid,
            # but that would break users' existing tests
            existing_record.save(validate: false)
          end

          true
        end

        def arbitrary_non_blank_value
          non_blank_value = dummy_value_for(@attribute)
          limit = column_limit_for(@attribute)

          is_string_value = non_blank_value.is_a?(String)
          if is_string_value && limit && limit < non_blank_value.length
            'x' * limit
          else
            non_blank_value
          end
        end

        def has_secure_password?
          Shoulda::Matchers::RailsShim.has_secure_password?(subject, @attribute)
        end

        def build_new_record
          @new_record = existing_record.dup

          attribute_names_under_test.each do |attribute_name|
            set_attribute_on_new_record!(
              attribute_name,
              existing_record.public_send(attribute_name),
            )
          end

          @new_record
        end

        def matches_presence_of_attribute?
          if attribute_present_on_model?
            true
          else
            @failure_reason =
              ":#{attribute} does not seem to be an attribute on #{model.name}."
            false
          end
        end

        def does_not_match_presence_of_attribute?
          if attribute_present_on_model?
            @failure_reason =
              ":#{attribute} seems to be an attribute on #{model.name}."
            false
          else
            true
          end
        end

        def attribute_present_on_model?
          model.method_defined?("#{attribute}=") ||
            model.columns_hash.key?(attribute.to_s)
        end

        def matches_presence_of_scopes?
          if scopes_missing_on_model.none?
            true
          else
            inspected_scopes = scopes_missing_on_model.map(&:inspect)

            reason = ''

            reason << inspected_scopes.to_sentence

            reason <<
              if inspected_scopes.many?
                ' do not seem to be attributes'
              else
                ' does not seem to be an attribute'
              end

            reason << " on #{model.name}."

            @failure_reason = reason

            false
          end
        end

        def does_not_match_presence_of_scopes?
          if scopes_missing_on_model.any?
            true
          else
            inspected_scopes = scopes_present_on_model.map(&:inspect)

            reason = ''

            reason << inspected_scopes.to_sentence

            reason <<
              if inspected_scopes.many?
                ' seem to be attributes'
              else
                ' seems to be an attribute'
              end

            reason << " on #{model.name}."

            @failure_reason = reason

            false
          end
        end

        def scopes_present_on_model
          @_scopes_present_on_model ||= expected_scopes.select do |scope|
            model.method_defined?("#{scope}=")
          end
        end

        def scopes_missing_on_model
          @_scopes_missing_on_model ||= expected_scopes.reject do |scope|
            model.method_defined?("#{scope}=")
          end
        end

        def matches_uniqueness_without_scopes?
          if existing_value_read.blank?
            update_existing_record!(arbitrary_non_blank_value)
          end

          disallows_value_of(existing_value_read, @expected_message)
        end

        def does_not_match_uniqueness_without_scopes?
          @failure_reason = nil

          if existing_value_read.blank?
            update_existing_record!(arbitrary_non_blank_value)
          end

          allows_value_of(existing_value_read, @expected_message)
        end

        def matches_uniqueness_with_case_sensitivity_strategy?
          if should_test_case_sensitivity?
            value = existing_value_read
            swapcased_value = value.swapcase

            if case_sensitivity_strategy == :sensitive
              if value == swapcased_value
                raise NonCaseSwappableValueError.create(
                  model: model,
                  attribute: @attribute,
                  value: value,
                )
              end

              allows_value_of(swapcased_value, @expected_message)
            else
              disallows_value_of(swapcased_value, @expected_message)
            end
          else
            true
          end
        end

        def does_not_match_uniqueness_with_case_sensitivity_strategy?
          if should_test_case_sensitivity?
            @failure_reason = nil

            value = existing_value_read
            swapcased_value = value.swapcase

            if case_sensitivity_strategy == :sensitive
              disallows_value_of(swapcased_value, @expected_message)
            else
              if value == swapcased_value
                raise NonCaseSwappableValueError.create(
                  model: model,
                  attribute: @attribute,
                  value: value,
                )
              end

              allows_value_of(swapcased_value, @expected_message)
            end
          else
            true
          end
        end

        def should_test_case_sensitivity?
          case_sensitivity_strategy != :ignore &&
            existing_value_read.respond_to?(:swapcase) &&
            !existing_value_read.empty?
        end

        def model_class?(model_name)
          model_name.constantize.ancestors.include?(::ActiveRecord::Base)
        rescue NameError
          false
        end

        def matches_uniqueness_with_scopes?
          expected_scopes.none? ||
            all_scopes_are_booleans? ||
            expected_scopes.all? do |scope|
              setting_next_value_for(scope) do
                allows_value_of(existing_value_read, @expected_message)
              end
            end
        end

        def does_not_match_uniqueness_with_scopes?
          expected_scopes.any? &&
            !all_scopes_are_booleans? &&
            expected_scopes.any? do |scope|
              setting_next_value_for(scope) do
                @failure_reason = nil
                disallows_value_of(existing_value_read, @expected_message)
              end
            end
        end

        def setting_next_value_for(scope)
          previous_value = @all_records.map(&scope).compact.max

          next_value =
            if previous_value.blank?
              dummy_value_for(scope)
            else
              next_value_for(scope, previous_value)
            end

          set_attribute_on_new_record!(scope, next_value)

          yield
        ensure
          set_attribute_on_new_record!(scope, previous_value)
        end

        def dummy_value_for(scope)
          column = column_for(scope)

          if column.respond_to?(:array) && column.array
            [dummy_scalar_value_for(column)]
          else
            dummy_scalar_value_for(column)
          end
        end

        def dummy_scalar_value_for(column)
          Shoulda::Matchers::Util.dummy_value_for(column.type)
        end

        def next_value_for(scope, previous_value)
          if previous_value.is_a?(Array)
            [next_scalar_value_for(scope, previous_value[0])]
          else
            next_scalar_value_for(scope, previous_value)
          end
        end

        def next_scalar_value_for(scope, previous_value)
          column = column_for(scope)

          if column.type == :uuid
            SecureRandom.uuid
          elsif defined_as_enum?(scope)
            available_values = available_enum_values_for(scope, previous_value)
            available_values.keys.last
          elsif polymorphic_type_attribute?(scope, previous_value)
            Uniqueness::TestModels.create(previous_value).to_s
          elsif previous_value.respond_to?(:next)
            previous_value.next
          elsif previous_value.respond_to?(:to_datetime)
            previous_value.to_datetime.in(60).next
          elsif boolean_value?(previous_value)
            !previous_value
          else
            previous_value.to_s.next
          end
        end

        def all_scopes_are_booleans?
          @options[:scopes].all? do |scope|
            @all_records.map(&scope).all? { |s| boolean_value?(s) }
          end
        end

        def boolean_value?(value)
          [true, false].include?(value)
        end

        def defined_as_enum?(scope)
          model.respond_to?(:defined_enums) &&
            new_record.defined_enums[scope.to_s]
        end

        def polymorphic_type_attribute?(scope, previous_value)
          scope.to_s =~ /_type$/ && model_class?(previous_value)
        end

        def available_enum_values_for(scope, previous_value)
          new_record.defined_enums[scope.to_s].reject do |key, _|
            key == previous_value
          end
        end

        def set_attribute_on!(record_type, record, attribute_name, value)
          attribute_setter = build_attribute_setter(
            record,
            attribute_name,
            value,
          )
          attribute_setter.set!

          @attribute_setters[record_type] << attribute_setter
        end

        def set_attribute_on_existing_record!(attribute_name, value)
          set_attribute_on!(
            :existing_record,
            existing_record,
            attribute_name,
            value,
          )
        end

        def set_attribute_on_new_record!(attribute_name, value)
          set_attribute_on!(
            :new_record,
            new_record,
            attribute_name,
            value,
          )
        end

        def attribute_setter_for_existing_record
          @attribute_setters[:existing_record].last
        end

        def attribute_setters_for_new_record
          @attribute_setters[:new_record] +
            [last_attribute_setter_used_on_new_record]
        end

        def attribute_names_under_test
          [@attribute] + expected_scopes
        end

        def build_attribute_setter(record, attribute_name, value)
          Shoulda::Matchers::ActiveModel::AllowValueMatcher::AttributeSetter.
            new(
              matcher_name: :validate_uniqueness_of,
              object: record,
              attribute_name: attribute_name,
              value: value,
              ignore_interference_by_writer: ignore_interference_by_writer,
            )
        end

        def existing_value_read
          existing_record.public_send(@attribute)
        end

        def existing_value_written
          if attribute_setter_for_existing_record
            attribute_setter_for_existing_record.value_written
          else
            existing_value_read
          end
        end

        def column_for(scope)
          model.columns_hash[scope.to_s]
        end

        def column_limit_for(attribute)
          column_for(attribute).try(:limit)
        end

        def model
          @given_record.class
        end

        def failure_message_preface # rubocop:disable Metrics/MethodLength
          prefix = ''

          if @existing_record_created
            prefix << "After taking the given #{model.name}"

            if attribute_setter_for_existing_record
              prefix << ', setting '
              prefix << description_for_attribute_setter(
                attribute_setter_for_existing_record,
              )
            else
              prefix << ", whose :#{attribute} is "
              prefix << "‹#{existing_value_read.inspect}›"
            end

            prefix << ', and saving it as the existing record, then'
          elsif attribute_setter_for_existing_record
            prefix << "Given an existing #{model.name},"
            prefix << ' after setting '
            prefix << description_for_attribute_setter(
              attribute_setter_for_existing_record,
            )
            prefix << ', then'
          else
            prefix << "Given an existing #{model.name} whose :#{attribute}"
            prefix << ' is '
            prefix << Shoulda::Matchers::Util.inspect_value(
              existing_value_read,
            )
            prefix << ', after'
          end

          prefix << " making a new #{model.name} and setting "

          prefix << descriptions_for_attribute_setters_for_new_record

          prefix << ", the matcher expected the new #{model.name} to be"

          prefix
        end

        def attribute_changed_value_message
          <<-MESSAGE.strip
As indicated in the message above,
:#{last_attribute_setter_used_on_new_record.attribute_name} seems to be
changing certain values as they are set, and this could have something
to do with why this test is failing. If you or something else has
overridden the writer method for this attribute to normalize values by
changing their case in any way (for instance, ensuring that the
attribute is always downcased), then try adding
`ignoring_case_sensitivity` onto the end of the uniqueness matcher.
Otherwise, you may need to write the test yourself, or do something
different altogether.
          MESSAGE
        end

        def description_for_attribute_setter(
          attribute_setter,
          same_as_existing: nil
        )
          description = "its :#{attribute_setter.attribute_name} to "

          if same_as_existing == false
            description << 'a different value, '
          end

          description << Shoulda::Matchers::Util.inspect_value(
            attribute_setter.value_written,
          )

          if attribute_setter.attribute_changed_value?
            description << ' (read back as '
            description << Shoulda::Matchers::Util.inspect_value(
              attribute_setter.value_read,
            )
            description << ')'
          end

          if same_as_existing == true
            description << ' as well'
          end

          description
        end

        def descriptions_for_attribute_setters_for_new_record
          attribute_setter_descriptions_for_new_record.to_sentence
        end

        def attribute_setter_descriptions_for_new_record
          attribute_setters_for_new_record.map do |attribute_setter|
            same_as_existing = (
              attribute_setter.value_written ==
              existing_value_written
            )
            description_for_attribute_setter(
              attribute_setter,
              same_as_existing: same_as_existing,
            )
          end
        end

        def existing_and_new_values_are_same?
          last_value_set_on_new_record == existing_value_written
        end

        def last_attribute_setter_used_on_new_record
          last_submatcher_run.last_attribute_setter_used
        end

        def last_value_set_on_new_record
          last_submatcher_run.last_value_set
        end

        # @private
        class AttributeSetters
          include Enumerable

          def initialize
            @attribute_setters = []
          end

          def <<(given_attribute_setter)
            index = find_index_of(given_attribute_setter)

            if index
              @attribute_setters[index] = given_attribute_setter
            else
              @attribute_setters << given_attribute_setter
            end
          end

          def +(other_attribute_setters)
            dup.tap do |attribute_setters|
              other_attribute_setters.each do |attribute_setter|
                attribute_setters << attribute_setter
              end
            end
          end

          def each(&block)
            @attribute_setters.each(&block)
          end

          def last
            @attribute_setters.last
          end

          private

          def find_index_of(given_attribute_setter)
            @attribute_setters.find_index do |attribute_setter|
              attribute_setter.attribute_name ==
                given_attribute_setter.attribute_name
            end
          end
        end

        # @private
        class NonCaseSwappableValueError < Shoulda::Matchers::Error
          attr_accessor :model, :attribute, :value

          def message
            Shoulda::Matchers.word_wrap <<-MESSAGE
Your #{model.name} model has a uniqueness validation on :#{attribute} which is
declared to be case-sensitive, but the value the uniqueness matcher used,
#{value.inspect}, doesn't contain any alpha characters, so using it to
test the case-sensitivity part of the validation is ineffective. There are
two possible solutions for this depending on what you're trying to do here:

a) If you meant for the validation to be case-sensitive, then you need to give
   the uniqueness matcher a saved instance of #{model.name} with a value for
   :#{attribute} that contains alpha characters.

b) If you meant for the validation to be case-insensitive, then you need to
   add `case_sensitive: false` to the validation and add `case_insensitive` to
   the matcher.

For more information, please see:

https://matchers.shoulda.io/docs/v#{Shoulda::Matchers::VERSION}/file.NonCaseSwappableValueError.html
            MESSAGE
          end
        end

        # @private
        class ExistingRecordInvalid < Shoulda::Matchers::Error
          include Shoulda::Matchers::ActiveModel::Helpers

          attr_accessor :underlying_exception

          def message
            <<-MESSAGE.strip
validate_uniqueness_of works by matching a new record against an
existing record. If there is no existing record, it will create one
using the record you provide.

While doing this, the following error was raised:

#{Shoulda::Matchers::Util.indent(underlying_exception.message, 2)}

The best way to fix this is to provide the matcher with a record where
any required attributes are filled in with valid values beforehand.
            MESSAGE
          end
        end
      end
    end
  end
end
