# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::Providers::Base do
  let(:provider) { described_class.new }
  let(:account) { create(:account) }

  describe 'interface methods' do
    it 'raises NotImplementedError for create_customer' do
      expect { provider.create_customer(account, 'starter') }
        .to raise_error(NotImplementedError, /must implement #create_customer/)
    end

    it 'raises NotImplementedError for create_subscription' do
      expect { provider.create_subscription('cus_123', 'price_123', 1) }
        .to raise_error(NotImplementedError, /must implement #create_subscription/)
    end

    it 'raises NotImplementedError for create_portal_session' do
      expect { provider.create_portal_session('cus_123', 'https://example.com') }
        .to raise_error(NotImplementedError, /must implement #create_portal_session/)
    end

    it 'raises NotImplementedError for handle_webhook' do
      expect { provider.handle_webhook({}) }
        .to raise_error(NotImplementedError, /must implement #handle_webhook/)
    end

    it 'raises NotImplementedError for verify_webhook_signature' do
      expect { provider.verify_webhook_signature('payload', 'signature', 'secret') }
        .to raise_error(NotImplementedError, /must implement #verify_webhook_signature/)
    end

    it 'raises NotImplementedError for get_customer' do
      expect { provider.get_customer('cus_123') }
        .to raise_error(NotImplementedError, /must implement #get_customer/)
    end

    it 'raises NotImplementedError for get_subscription' do
      expect { provider.get_subscription('sub_123') }
        .to raise_error(NotImplementedError, /must implement #get_subscription/)
    end

    it 'raises NotImplementedError for provider_name' do
      expect { provider.provider_name }
        .to raise_error(NotImplementedError, /must implement #provider_name/)
    end

    it 'raises NotImplementedError for cancel_subscription' do
      expect { provider.cancel_subscription('sub_123') }
        .to raise_error(NotImplementedError, /must implement #cancel_subscription/)
    end

    it 'raises NotImplementedError for update_subscription' do
      expect { provider.update_subscription('sub_123', {}) }
        .to raise_error(NotImplementedError, /must implement #update_subscription/)
    end
  end

  describe 'error messages' do
    it 'includes the class name in error messages' do
      expect { provider.create_customer(account, 'starter') }
        .to raise_error(NotImplementedError, /Billing::Providers::Base/)
    end
  end
end