require 'rails_helper'

RSpec.describe Webhooks::PrivateNetworkPolicy do
  describe '#safe_fetch_options' do
    it 'returns an empty hash by default' do
      expect(described_class.new(:api_inbox_webhook).safe_fetch_options).to eq({})
    end

    it 'returns configured allowlists for enabled webhook types' do
      with_modified_env(
        'WEBHOOK_PRIVATE_NETWORK_ALLOWED_TYPES' => 'api_inbox_webhook',
        'WEBHOOK_ALLOWED_PRIVATE_HOSTS' => 'internal-webhook-service',
        'WEBHOOK_ALLOWED_PRIVATE_CIDRS' => '192.168.0.0/16'
      ) do
        expect(described_class.new(:api_inbox_webhook).safe_fetch_options).to eq(
          allowed_private_hosts: ['internal-webhook-service'],
          allowed_private_cidrs: ['192.168.0.0/16']
        )
      end
    end

    it 'does not return allowlists for disabled webhook types' do
      with_modified_env(
        'WEBHOOK_PRIVATE_NETWORK_ALLOWED_TYPES' => 'api_inbox_webhook',
        'WEBHOOK_ALLOWED_PRIVATE_CIDRS' => '192.168.0.0/16'
      ) do
        expect(described_class.new(:account_webhook).safe_fetch_options).to eq({})
      end
    end
  end
end
