# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  describe User do
    describe 'serialization' do
      test 'hash should not include sensitive info' do
        @resource = build(:user)
        refute @resource.as_json[:tokens]
      end
    end

    describe 'creation' do
      test 'save fails if uid is missing' do
        @resource = User.new
        @resource.uid = nil
        @resource.save

        assert @resource.errors.messages[:uid]
      end
    end

    describe 'email registration' do
      test 'model should not save if email is blank' do
        @resource = build(:user, email: nil)

        refute @resource.save
        assert @resource.errors.messages[:email] == [I18n.t('errors.messages.blank')]
      end

      test 'model should not save if email is not an email' do
        @resource = build(:user, email: '@example.com')

        refute @resource.save
        assert @resource.errors.messages[:email] == [I18n.t('errors.messages.not_email')]
      end
    end

    describe 'email uniqueness' do
      test 'model should not save if email is taken' do
        user_attributes = attributes_for(:user)
        create(:user, user_attributes)
        @resource = build(:user, user_attributes)

        refute @resource.save
        assert @resource.errors.messages[:email].first.include? 'taken'
        assert @resource.errors.messages[:email].none? { |e| e =~ /translation missing/ }
      end
    end

    describe 'oauth2 authentication' do
      test 'model should save even if email is blank' do
        @resource = build(:user, :facebook, email: nil)

        assert @resource.save
        assert @resource.errors.messages[:email].blank?
      end
    end

    describe 'token expiry' do
      before do
        @resource = create(:user, :confirmed)

        @auth_headers = @resource.create_new_auth_token

        @token     = @auth_headers['access-token']
        @client_id = @auth_headers['client']
      end

      test 'should properly indicate whether token is current' do
        assert @resource.token_is_current?(@token, @client_id)
        # we want to update the expiry without forcing a cleanup (see below)
        @resource.tokens[@client_id]['expiry'] = Time.zone.now.to_i - 10.seconds
        refute @resource.token_is_current?(@token, @client_id)
      end
    end

    describe 'previous token' do
      before do
        @resource = create(:user, :confirmed)

        @auth_headers1 = @resource.create_new_auth_token
      end

      test 'should properly indicate whether previous token is current' do
        assert @resource.token_is_current?(@auth_headers1['access-token'], @auth_headers1['client'])
        # create another token, emulating a new request
        @auth_headers2 = @resource.create_new_auth_token

        # should work for previous token
        assert @resource.token_is_current?(@auth_headers1['access-token'], @auth_headers1['client'])
        # should work for latest token as well
        assert @resource.token_is_current?(@auth_headers2['access-token'], @auth_headers2['client'])

        # after using latest token, previous token should not work
        assert @resource.token_is_current?(@auth_headers1['access-token'], @auth_headers1['client'])
      end
    end

    describe 'expired tokens are destroyed on save' do
      before do
        @resource = create(:user, :confirmed)

        @old_auth_headers = @resource.create_new_auth_token
        @new_auth_headers = @resource.create_new_auth_token
        expire_token(@resource, @old_auth_headers['client'])
      end

      test 'expired token was removed' do
        refute @resource.tokens[@old_auth_headers[:client]]
      end

      test 'current token was not removed' do
        assert @resource.tokens[@new_auth_headers['client']]
      end
    end

    describe 'nil tokens are handled properly' do
      before do
        @resource = create(:user, :confirmed)
      end

      test 'tokens can be set to nil' do
        @resource.tokens = nil
        assert @resource.save
      end
    end
  end
end
