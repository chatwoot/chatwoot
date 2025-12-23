module Shoulda
  module Matchers
    module ActiveRecord
      # The `have_secure_token` matcher tests usage of the
      # `has_secure_token` macro.
      #
      #     class User < ActiveRecord
      #       has_secure_token
      #       has_secure_token :auth_token
      #     end
      #
      #     # RSpec
      #     RSpec.describe User, type: :model do
      #       it { should have_secure_token }
      #       it { should have_secure_token(:auth_token) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UserTest < ActiveSupport::TestCase
      #       should have_secure_token
      #       should have_secure_token(:auth_token)
      #     end
      #
      # #### Qualifiers
      #
      # ##### ignoring_check_for_db_index
      #
      # By default, this matcher tests that an index is defined on your token
      # column. Use `ignoring_check_for_db_index` if this is not the case.
      #
      #     class User < ActiveRecord
      #       has_secure_token :auth_token
      #     end
      #
      #     # RSpec
      #     RSpec.describe User, type: :model do
      #       it { should have_secure_token(:auth_token).ignoring_check_for_db_index }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UserTest < ActiveSupport::TestCase
      #       should have_secure_token(:auth_token).ignoring_check_for_db_index
      #     end
      #
      # @return [HaveSecureToken]
      #
      def have_secure_token(token_attribute = :token)
        HaveSecureTokenMatcher.new(token_attribute)
      end

      # @private
      class HaveSecureTokenMatcher
        attr_reader :token_attribute

        def initialize(token_attribute)
          @token_attribute = token_attribute
          @options = { ignore_check_for_db_index: false }
        end

        def description
          "have :#{token_attribute} as a secure token"
        end

        def failure_message
          return if !@errors

          "Expected #{@subject.class} to #{description} but the following " \
          "errors were found: #{@errors.join(', ')}"
        end

        def failure_message_when_negated
          return if !@errors

          "Did not expect #{@subject.class} to have secure token " \
          ":#{token_attribute}"
        end

        def matches?(subject)
          @subject = subject
          @errors = run_checks
          @errors.empty?
        end

        def ignoring_check_for_db_index
          @options[:ignore_check_for_db_index] = true
          self
        end

        private

        def run_checks
          @errors = []
          if !has_expected_instance_methods?
            @errors << 'missing expected class and instance methods'
          end
          if !has_expected_db_column?
            @errors << "missing correct column #{token_attribute}:string"
          end
          if !@options[:ignore_check_for_db_index] && !has_expected_db_index?
            @errors << "missing unique index for #{table_and_column}"
          end
          @errors
        end

        def has_expected_instance_methods?
          @subject.respond_to?(token_attribute.to_s) &&
            @subject.respond_to?("#{token_attribute}=") &&
            @subject.respond_to?("regenerate_#{token_attribute}") &&
            @subject.class.respond_to?(:generate_unique_secure_token)
        end

        def has_expected_db_column?
          matcher = HaveDbColumnMatcher.new(token_attribute).of_type(:string)
          matcher.matches?(@subject)
        end

        def has_expected_db_index?
          matcher = HaveDbIndexMatcher.new(token_attribute).unique(true)
          matcher.matches?(@subject)
        end

        def table_and_column
          "#{table_name}.#{token_attribute}"
        end

        def table_name
          @subject.class.table_name
        end
      end
    end
  end
end
