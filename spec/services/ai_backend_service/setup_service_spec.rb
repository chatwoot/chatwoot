require 'rails_helper'

RSpec.describe AiBackendService::SetupService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:setup_service) { described_class.new }

  # Create "doubles" for the services that SetupService depends on.
  # These are like stand-in objects that we can control in our test.
  let(:store_service_double) { instance_double(AiBackendService::StoreService) }
  let(:configuration_service_double) { instance_double(AiBackendService::ConfigurationService) }

  # A fake successful response from the store service.
  let(:store_id) { SecureRandom.uuid }
  let(:store_response) { { 'store' => { 'id' => store_id } } }

  before do
    # Intercept the .new method on our real services and make them
    # return our fake "doubles" instead.
    allow(AiBackendService::StoreService).to receive(:new).and_return(store_service_double)
    allow(AiBackendService::ConfigurationService).to receive(:new).and_return(configuration_service_double)
  end

  describe '.setup_store' do
    # We are testing the class method, which is the public API of the service.
    subject { described_class.setup_store(account, user.email) }

    context 'when all services are successful' do
      it 'calls store and configuration services in order and returns the store response' do
        # 1. We expect the `create_store` method on our store_service_double
        #    to be called with the correct account and email.
        #    We tell it to return our fake successful response. `.ordered` ensures it runs first.
        expect(store_service_double).to receive(:create_store)
          .with(account, user.email)
          .and_return(store_response)
          .ordered

        # 2. We expect the `create_default_store_configs` method on our configuration_service_double
        #    to be called with the store_id we got from the previous step.
        #    `.ordered` ensures it runs second.
        expect(configuration_service_double).to receive(:create_default_store_configs)
          .with(store_id)
          .ordered

        # Finally, we assert that the return value of the whole service call
        # is the response from the store service.
        expect(subject).to eq(store_response)
      end
    end

    context 'when StoreService fails' do
      it 'raises a SetupError and does not call ConfigurationService' do
        # We tell our store_service_double to raise a StoreError when called.
        allow(store_service_double).to receive(:create_store)
          .and_raise(AiBackendService::StoreService::StoreError, 'Store API failed')

        # We assert that the configuration_service_double is *never* called.
        # If the first step fails, the second should not be attempted.
        expect(configuration_service_double).not_to receive(:create_default_store_configs)

        # We expect our SetupService to catch the original error and raise its own
        # specific SetupError with a descriptive message.
        expect { subject }.to raise_error(
          AiBackendService::SetupService::SetupError,
          /AI Backend setup failed: Store API failed/
        )
      end
    end

    context 'when ConfigurationService fails' do
      it 'raises a SetupError' do
        # We let the store_service succeed and return the fake response.
        allow(store_service_double).to receive(:create_store).and_return(store_response)

        # We tell our configuration_service_double to raise an error when called.
        allow(configuration_service_double).to receive(:create_default_store_configs)
          .and_raise(AiBackendService::ConfigurationService::ConfigurationError, 'Config API failed')

        # We expect our SetupService to catch this error and raise its SetupError.
        expect { subject }.to raise_error(
          AiBackendService::SetupService::SetupError,
          /AI Backend setup failed: Config API failed/
        )
      end
    end
  end
end