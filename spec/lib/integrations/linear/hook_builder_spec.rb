require 'rails_helper'

describe Integrations::Linear::HookBuilder do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex }
  let(:token) { SecureRandom.hex }
  let(:inbox) { create(:inbox, account: account) }

  describe '#perform' do
    it 'creates hook with valid token' do
      hooks_count = account.hooks.count

      builder = described_class.new(account: account, code: code, inbox_id: inbox.id)
      allow(builder).to receive(:fetch_access_token).and_return(token)

      hook = builder.perform
      expect(account.hooks.count).to eql(hooks_count + 1)

      expect(hook.access_token).to eql(token)
      expect(hook.status).to eql('enabled')
      expect(hook.app_id).to eql('linear')
      expect(hook.inbox_id).to eql(inbox.id)
    end
  end

  context 'when authentication fails' do
    it 'raises error when Linear returns error description' do
      builder = described_class.new(account: account, code: code, inbox_id: inbox.id)
      error_response = instance_double(
        HTTParty::Response,
        success?: false,
        body: {},
        parsed_response: { 'error_description' => 'Invalid code' }
      )

      allow(HTTParty).to receive(:post).and_return(error_response)

      expect { builder.perform }.to raise_error(StandardError, 'Invalid code')
    end

    it 'raises default error when Linear returns no error description' do
      builder = described_class.new(account: account, code: code, inbox_id: inbox.id)
      error_response = instance_double(
        HTTParty::Response,
        success?: false,
        body: {},
        parsed_response: {}
      )

      allow(HTTParty).to receive(:post).and_return(error_response)

      expect { builder.perform }.to raise_error(StandardError, 'Failed to authenticate with Linear')
    end
  end
end
