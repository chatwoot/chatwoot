require 'rails_helper'

describe Integrations::Slack::HookBuilder do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex }
  let(:token) { SecureRandom.hex }

  describe '#perform' do
    it 'creates hook' do
      hooks_count = account.hooks.count

      builder = described_class.new(account: account, code: code)
      allow(builder).to receive(:fetch_access_token).and_return(token)

      builder.perform
      expect(account.hooks.count).to eql(hooks_count + 1)

      hook = account.hooks.last
      expect(hook.access_token).to eql(token)
    end
  end
end
