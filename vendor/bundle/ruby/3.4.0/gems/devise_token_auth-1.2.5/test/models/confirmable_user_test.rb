# frozen_string_literal: true

require 'test_helper'

class ConfirmableUserTest < ActiveSupport::TestCase
  describe ConfirmableUser do
    describe 'creation' do
      test 'email should be saved' do
        @resource = create(:confirmable_user)
        assert @resource.email.present?
      end
    end

    describe 'updating email' do
      test 'new email should be saved to unconfirmed_email' do
        @resource = create(:confirmable_user, email: 'old_address@example.com')
        @resource.update(email: 'new_address@example.com')
        assert @resource.unconfirmed_email == 'new_address@example.com'
      end

      test 'old email should be kept in email' do
        @resource = create(:confirmable_user, email: 'old_address@example.com')
        @resource.update(email: 'new_address@example.com')
        assert @resource.email == 'old_address@example.com'
      end

      test 'confirmation_token should be changed' do
        @resource = create(:confirmable_user, email: 'old_address@example.com')
        old_token = @resource.confirmation_token
        @resource.update(email: 'new_address@example.com')
        assert @resource.confirmation_token != old_token
      end
    end
  end
end
