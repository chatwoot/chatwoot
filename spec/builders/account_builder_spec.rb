# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountBuilder do
  let(:email) { 'user@example.com' }
  let(:user_password) { 'Password123!' }
  let(:account_name) { 'Test Account' }
  let(:user_full_name) { 'Test User' }
  let(:validation_service) { instance_double(Account::SignUpEmailValidationService, perform: true) }
  let(:account_builder) do
    described_class.new(
      account_name: account_name,
      email: email,
      user_full_name: user_full_name,
      user_password: user_password,
      confirmed: true
    )
  end

  # Mock the email validation service
  before do
    allow(Account::SignUpEmailValidationService).to receive(:new).with(email).and_return(validation_service)
  end

  describe '#perform' do
    context 'when valid params are passed' do
      it 'creates a new account with correct name' do
        _user, account = account_builder.perform
        expect(account).to be_an(Account)
        expect(account.name).to eq(account_name)
      end

      it 'creates a new confirmed user with correct details' do
        user, _account = account_builder.perform
        expect(user).to be_a(User)
        expect(user.email).to eq(email)
        expect(user.name).to eq(user_full_name)
        expect(user.confirmed?).to be(true)
      end

      it 'links user to account as administrator' do
        user, account = account_builder.perform
        expect(user.account_users.first.role).to eq('administrator')
        expect(user.accounts.first).to eq(account)
      end

      it 'increments the counts of models' do
        expect do
          account_builder.perform
        end.to change(Account, :count).by(1)
           .and change(User, :count).by(1)
           .and change(AccountUser, :count).by(1)
      end
    end

    context 'when an account is created' do
      it 'adds a correctly formatted store_id to custom_attributes' do
        _user, account = account_builder.perform

        # 1. Check if the store_id exists in custom_attributes
        expect(account.custom_attributes).to have_key('store_id')

        # 2. Check if the store_id is formatted correctly
        # We generate the expected ID based on the new account's ID and compare.
        expected_padded_id = account.id.to_s.rjust(12, '0')
        expected_store_id = "00000000-0000-0000-0000-#{expected_padded_id}"
        expect(account.custom_attributes['store_id']).to eq(expected_store_id)
      end

      it 'sets initial free trial plan with billing status provisioning_pending' do
        _user, account = account_builder.perform

        expect(account.custom_attributes['plan_name']).to eq('free_trial')
        expect(account.custom_attributes['subscription_status']).to eq('active')
        expect(account.custom_attributes['billing_status']).to eq('provisioning_pending')
        expect(account.custom_attributes['subscription_ends_on']).to be_present
      end

      it 'sets trial plan limits correctly' do
        _user, account = account_builder.perform

        expect(account.limits).to include(
          'agents' => 2,
          'inboxes' => be_present,
          'conversations_monthly' => be_present
        )
      end

      it 'sets subscription_ends_on to future date based on trial period' do
        _user, account = account_builder.perform

        ends_on = Time.parse(account.custom_attributes['subscription_ends_on'])
        expected_end_date = 7.days.from_now

        # Allow for small time differences during test execution
        expect(ends_on).to be_within(5.seconds).of(expected_end_date)
      end
    end
  end
end
