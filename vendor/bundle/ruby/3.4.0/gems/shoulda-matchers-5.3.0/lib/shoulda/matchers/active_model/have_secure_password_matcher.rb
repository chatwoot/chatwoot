module Shoulda
  module Matchers
    module ActiveModel
      # The `have_secure_password` matcher tests usage of the
      # `has_secure_password` macro.
      #
      # #### Example
      #
      #     class User
      #       include ActiveModel::Model
      #       include ActiveModel::SecurePassword
      #       attr_accessor :password
      #       attr_accessor :reset_password
      #
      #       has_secure_password
      #       has_secure_password :reset_password
      #     end
      #
      #     # RSpec
      #     RSpec.describe User, type: :model do
      #       it { should have_secure_password }
      #       it { should have_secure_password(:reset_password) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UserTest < ActiveSupport::TestCase
      #       should have_secure_password
      #       should have_secure_password(:reset_password)
      #     end
      #
      # @return [HaveSecurePasswordMatcher]
      #
      def have_secure_password(attr = :password)
        HaveSecurePasswordMatcher.new(attr)
      end

      # @private
      class HaveSecurePasswordMatcher
        attr_reader :failure_message

        CORRECT_PASSWORD = 'aBcDe12345'.freeze
        INCORRECT_PASSWORD = 'password'.freeze

        MESSAGES = {
          authenticated_incorrect_password: 'expected %{subject} to not'\
            ' authenticate an incorrect %{attribute}',
          did_not_authenticate_correct_password: 'expected %{subject} to'\
            ' authenticate the correct %{attribute}',
          method_not_found: 'expected %{subject} to respond to %{methods}',
        }.freeze

        def initialize(attribute)
          @attribute = attribute.to_sym
        end

        def description
          "have a secure password, defined on #{@attribute} attribute"
        end

        def matches?(subject)
          @subject = subject

          if failure = validate
            key, params = failure
            @failure_message =
              MESSAGES[key] % { subject: subject.class }.merge(params)
          end

          failure.nil?
        end

        protected

        attr_reader :subject

        def validate
          missing_methods = expected_methods.reject do |m|
            subject.respond_to?(m)
          end

          if missing_methods.present?
            [:method_not_found, { methods: missing_methods.to_sentence }]
          else
            subject.send("#{@attribute}=", CORRECT_PASSWORD)
            subject.send("#{@attribute}_confirmation=", CORRECT_PASSWORD)

            if not subject.send(authenticate_method, CORRECT_PASSWORD)
              [:did_not_authenticate_correct_password,
               { attribute: @attribute },]
            elsif subject.send(authenticate_method, INCORRECT_PASSWORD)
              [:authenticated_incorrect_password, { attribute: @attribute }]
            end
          end
        end

        private

        def expected_methods
          @_expected_methods ||= %I[
            #{authenticate_method}
            #{@attribute}=
            #{@attribute}_confirmation=
            #{@attribute}_digest
            #{@attribute}_digest=
          ]
        end

        def authenticate_method
          if @attribute == :password
            :authenticate
          else
            "authenticate_#{@attribute}".to_sym
          end
        end
      end
    end
  end
end
