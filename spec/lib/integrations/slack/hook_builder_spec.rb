require 'rails_helper'

describe Integrations::Slack::HookBuilder do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex }
  let(:token) { SecureRandom.hex }

  describe '#perform' do
    it 'creates hook' do
      hooks_count = account.hooks.count

      builder = described_class.new(account: account, code: code)
      allow(builder)
        .to receive(:exchange_temporary_code)
              .and_return({ 'access_token' => token })

      builder.perform
      expect(account.hooks.count).to eql(hooks_count + 1)

      hook = account.hooks.last
      expect(hook.access_token).to eql(token)
    end

    it 'creates hook with reference id' do
      hooks_count = account.hooks.count

      builder = described_class.new(account: account, code: code)
      allow(builder)
        .to receive(:exchange_temporary_code).and_return(
          {
            'access_token' => token,
            'incoming_webhook' => {
              'channel' => '#channel',
              'channel_id' => 'channel_id'
            }
          })

      builder.perform
      expect(account.hooks.count).to eql(hooks_count + 1)

      hook = account.hooks.last
      expect(hook.access_token).to eql(token)
      expect(hook.reference_id).to eql('channel_id')
    end
  end
end
