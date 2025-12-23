# frozen_string_literal: true

require 'test_helper'

class OnlyEmailUserTest < ActiveSupport::TestCase
  describe OnlyEmailUser do
    test 'confirmable is disabled' do
      refute OnlyEmailUser.method_defined?(:confirmation_token)
      refute OnlyEmailUser.method_defined?(:confirmed_at)
      refute OnlyEmailUser.method_defined?(:confirmation_sent_at)
      refute OnlyEmailUser.method_defined?(:unconfirmed_email)
    end

    test 'lockable is disabled' do
      refute OnlyEmailUser.method_defined?(:failed_attempts)
      refute OnlyEmailUser.method_defined?(:unlock_token)
      refute OnlyEmailUser.method_defined?(:locked_at)
    end

    test 'recoverable is disabled' do
      refute OnlyEmailUser.method_defined?(:reset_password_token)
      refute OnlyEmailUser.method_defined?(:reset_password_sent_at)
    end

    test 'rememberable is disabled' do
      refute OnlyEmailUser.method_defined?(:remember_created_at)
    end
  end
end
