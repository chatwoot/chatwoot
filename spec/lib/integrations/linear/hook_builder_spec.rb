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
end
