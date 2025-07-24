require 'rails_helper'

RSpec.describe ChatscommerceAccountBuilder do
  # Define the parameters that will be passed to the builder
  let(:params) do
    {
      email: 'test@example.com',
      password: 'password123',
      account_name: 'Test Account',
      user_full_name: 'Test User'
    }
  end

  # Create an instance of the builder we are testing
  let(:builder) { described_class.new(params) }

  # Create "doubles" for the two main dependencies of our builder
  let(:account_builder_double) { instance_double(AccountBuilder) }
  let(:setup_service_class_double) { class_double(ChatscommerceService::SetupService) }

  # Create fake user and account objects to be returned on a successful run
  let(:user) { build_stubbed(:user) }
  let(:account) { build_stubbed(:account) }

  before do
    # Before each test, we stub the dependencies to return our doubles/fakes.
    # 1. Stub the AccountBuilder: when it's initialized and `perform` is called,
    #    return our fake user and account.
    allow(AccountBuilder).to receive(:new).and_return(account_builder_double)
    allow(account_builder_double).to receive(:perform).and_return([user, account])

    # 2. Stub the SetupService: ensure no real API calls are made.
    allow(ChatscommerceService::SetupService).to receive(:setup_store)
  end

  describe '#perform' do
    subject(:perform_build) { builder.perform }

    context 'when both account creation and store setup are successful' do
      it 'calls AccountBuilder with the correct parameters' do
        # We check that the original AccountBuilder is called with the exact
        # parameters our builder is supposed to pass along.
        expected_params = {
          account_name: params[:account_name],
          email: params[:email],
          confirmed: true,
          user: nil,
          user_full_name: params[:user_full_name],
          user_password: params[:password],
          super_admin: false,
          locale: I18n.locale
        }
        expect(AccountBuilder).to receive(:new).with(expected_params).and_return(account_builder_double)
        perform_build
      end

      it 'calls SetupService.setup_store with the created account and email' do
        # We check that our setup service is called with the account object
        # that was returned by the AccountBuilder double.
        expect(ChatscommerceService::SetupService).to receive(:setup_store).with(account, params[:email])
        perform_build
      end

      it 'returns a hash with the created user and account' do
        expect(perform_build).to eq({ user: user, account: account })
      end
    end

    context 'when AccountBuilder fails' do
      before do
        # We simulate a failure in the original AccountBuilder.
        allow(account_builder_double).to receive(:perform).and_raise(StandardError, 'Account creation failed internally')
      end

      it 'raises a BuildError and does not attempt to set up the store' do
        # We assert that the setup service is *never* called if account creation fails.
        expect(ChatscommerceService::SetupService).not_to receive(:setup_store)

        # We check that our builder catches the original error and raises its own BuildError.
        expect { perform_build }.to raise_error(
          described_class::BuildError,
          'Account creation failed: Account creation failed internally'
        )
      end
    end

    context 'when ChatscommerceService::SetupService fails' do
      before do
        # We simulate a failure in the setup service.
        allow(ChatscommerceService::SetupService).to receive(:setup_store)
          .and_raise(ChatscommerceService::SetupService::SetupError, 'Store setup failed')
      end

      it 'raises a BuildError' do
        # We check that our builder catches the service's custom error and raises its own.
        expect { perform_build }.to raise_error(
          described_class::BuildError,
          'Store setup failed, Store setup failed'
        )
      end
    end
  end
end