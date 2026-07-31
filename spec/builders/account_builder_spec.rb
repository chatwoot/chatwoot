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

      it 'initializes the onboarding step to account_details' do
        _user, account = account_builder.perform
        expect(account.custom_attributes['onboarding_step']).to eq('account_details')
      end
    end

    context 'with a Shopify pending installation' do
      let(:pending_install_token) { SecureRandom.hex(16) }
      let(:pending_installation) do
        instance_double(
          Shopify::PendingInstallation,
          data: {
            'access_token' => 'shopify-access-token',
            'shop' => 'my-store.myshopify.com',
            'scope' => 'read_customers,read_orders'
          }
        )
      end
      let(:shopify_account_builder) do
        described_class.new(
          account_name: account_name,
          email: email,
          user_full_name: user_full_name,
          user_password: user_password,
          confirmed: true,
          shopify_pending_install_token: pending_install_token
        )
      end
      let(:unconfirmed_shopify_account_builder) do
        described_class.new(
          account_name: account_name,
          email: email,
          user_full_name: user_full_name,
          user_password: user_password,
          shopify_pending_install_token: pending_install_token
        )
      end

      before do
        allow(Shopify::FeatureGate).to receive(:enabled?).and_return(true)
        allow(Shopify::FeatureGate).to receive(:globally_enabled?).and_return(true)
        allow(Shopify::PendingInstallation).to receive(:claim)
          .with(token: pending_install_token)
          .and_return(pending_installation)
        allow(pending_installation).to receive(:consume!)
        allow(pending_installation).to receive(:release!)
      end

      it 'creates the account, administrator, billing identity, feature flag, and Shopify hook atomically' do
        user, account = shopify_account_builder.perform

        expect(user.accounts).to contain_exactly(account)
        expect(account).to have_attributes(
          billing_provider: 'shopify',
          signup_source: 'shopify'
        )
        expect(account.custom_attributes['subscription_status']).to eq('pending')
        expect(account).to be_feature_enabled('shopify_integration')
        expect(account.hooks.find_by!(app_id: 'shopify')).to have_attributes(
          access_token: 'shopify-access-token',
          reference_id: 'my-store.myshopify.com',
          status: 'enabled',
          settings: include(
            'scope' => 'read_customers,read_orders',
            'connected_at' => match(/\.\d{6}Z\z/),
            'installation_id' => match(/\A[0-9a-f-]{36}\z/)
          )
        )
        expect(pending_installation).to have_received(:consume!)
        expect(pending_installation).not_to have_received(:release!)
      end

      it 'fails before claiming when the installation feature is disabled' do
        allow(Shopify::FeatureGate).to receive(:enabled?).and_return(false)
        expect(Shopify::PendingInstallation).not_to receive(:claim)

        expect do
          shopify_account_builder.perform
        end.to raise_error(Shopify::PendingInstallation::FeatureDisabled, 'Shopify signup is unavailable')
          .and not_change(Account, :count)
          .and not_change(User, :count)
      end

      it 'rolls back and releases the claim if the feature is disabled before account binding' do
        allow(Shopify::FeatureGate).to receive(:globally_enabled?).and_return(false)

        expect do
          shopify_account_builder.perform
        end.to raise_error(Shopify::PendingInstallation::FeatureDisabled, 'Shopify signup is unavailable')
          .and not_change(Account, :count)
          .and not_change(User, :count)
          .and not_change(Integrations::Hook, :count)

        expect(pending_installation).to have_received(:release!)
        expect(pending_installation).not_to have_received(:consume!)
      end

      it 'rejects an email that already belongs to a Chatwoot user before claiming the install' do
        create(:user, email: email)
        expect(Shopify::PendingInstallation).not_to receive(:claim)

        expect do
          shopify_account_builder.perform
        end.to raise_error(CustomExceptions::Account::UserExists)
          .and not_change(Account, :count)
          .and not_change(Integrations::Hook, :count)
      end

      it 'rolls back and releases the claim when the Shopify shop is already connected' do
        existing_account = create(:account)
        existing_account.enable_features!('shopify_integration')
        create(:integrations_hook, :shopify, account: existing_account, reference_id: 'my-store.myshopify.com')

        expect do
          shopify_account_builder.perform
        end.to raise_error(Shopify::PendingInstallation::DuplicateShop, 'This Shopify store is already connected')
          .and not_change(Account, :count)
          .and not_change(User, :count)
          .and not_change(Integrations::Hook, :count)

        expect(pending_installation).to have_received(:release!)
        expect(pending_installation).not_to have_received(:consume!)
      end

      it 'releases the claim without consuming it when the transaction rolls back' do
        allow(shopify_account_builder).to receive(:create_shopify_hook).and_raise(ActiveRecord::Rollback)

        expect do
          shopify_account_builder.perform
        end.to raise_error(ActiveRecord::Rollback)
          .and not_change(Account, :count)
          .and not_change(User, :count)
          .and not_change(Integrations::Hook, :count)

        expect(pending_installation).to have_received(:release!)
        expect(pending_installation).not_to have_received(:consume!)
      end

      it 'returns the committed signup when pending installation cleanup fails' do
        cleanup_error = StandardError.new('Redis unavailable')
        exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
        allow(pending_installation).to receive(:consume!).and_raise(cleanup_error)
        allow(ChatwootExceptionTracker).to receive(:new)
          .with(cleanup_error, account: instance_of(Account))
          .and_return(exception_tracker)

        user, account = shopify_account_builder.perform

        expect(user).to be_persisted
        expect(account).to be_persisted
        expect(account.hooks.find_by(app_id: 'shopify')).to be_present
        expect(exception_tracker).to have_received(:capture_exception)
        expect(pending_installation).not_to have_received(:release!)
      end

      it 'returns and finalizes a signup when a commit callback raises', :aggregate_failures do
        callback_error = StandardError.new('Commit callback failed')
        exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
          .with(Events::Types::ACCOUNT_CREATED, anything, account: instance_of(Account))
          .and_raise(callback_error)
        allow(ChatwootExceptionTracker).to receive(:new)
          .with(callback_error, account: instance_of(Account))
          .and_return(exception_tracker)

        result = nil
        expect do
          result = unconfirmed_shopify_account_builder.perform
        end.to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)
        user, account = result

        expect([user, account]).to all(be_persisted)
        expect(user).not_to be_confirmed
        expect(account.account_users.find_by(user: user)).to be_present
        expect(user.notification_settings.find_by(account: account)).to be_present
        expect(account.hooks.find_by(app_id: 'shopify')).to be_present
        expect(exception_tracker).to have_received(:capture_exception)
        expect(pending_installation).to have_received(:consume!)
        expect(pending_installation).not_to have_received(:release!)
      end

      it 'returns the committed signup when confirmation delivery fails', :aggregate_failures do
        delivery_error = StandardError.new('Mail delivery unavailable')
        exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
        allow(User).to receive(:new).and_wrap_original do |method, *args|
          method.call(*args).tap do |user|
            allow(user).to receive(:send_confirmation_instructions).and_raise(delivery_error)
          end
        end
        allow(ChatwootExceptionTracker).to receive(:new)
          .with(delivery_error, account: instance_of(Account))
          .and_return(exception_tracker)

        user, account = unconfirmed_shopify_account_builder.perform

        expect([user, account]).to all(be_persisted)
        expect(account.hooks.find_by(app_id: 'shopify')).to be_present
        expect(exception_tracker).to have_received(:capture_exception)
        expect(pending_installation).to have_received(:consume!)
        expect(pending_installation).not_to have_received(:release!)
      end

      it 'rejects an existing authenticated user before claiming the install' do
        existing_user = create(:user)
        builder = described_class.new(
          account_name: account_name,
          email: 'new-user@example.com',
          user: existing_user,
          shopify_pending_install_token: pending_install_token
        )
        expect(Shopify::PendingInstallation).not_to receive(:claim)

        expect do
          builder.perform
        end.to raise_error(CustomExceptions::Account::UserExists)
          .and not_change(Account, :count)
          .and not_change(Integrations::Hook, :count)
      end

      it 'rolls back the account, user, and hook when administrator linking fails' do
        allow(AccountUser).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(AccountUser.new))

        expect do
          shopify_account_builder.perform
        end.to raise_error(ActiveRecord::RecordInvalid)
          .and not_change(Account, :count)
          .and not_change(User, :count)
          .and not_change(Integrations::Hook, :count)

        expect(pending_installation).to have_received(:release!)
        expect(pending_installation).not_to have_received(:consume!)
      end
    end
  end
end
