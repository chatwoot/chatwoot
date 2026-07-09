require 'rails_helper'

RSpec.describe Waha::InboxProvisioner do
  describe '#perform' do
    let(:account) { create(:account) }
    let(:client) { instance_double(Waha::Client) }
    let(:config) do
      class_double(
        Waha::Config,
        enabled?: true,
        callback_url: 'https://waha.example/webhooks/chatwoot/5511999999999/app_id',
        session_ignore: { status: true, broadcast: true, channels: true, groups: true },
        chatwoot_base_url: 'https://chatwoot.example',
        conversation_sort: 'created_newest'
      )
    end

    before do
      allow(client).to receive(:create_session)
      allow(client).to receive(:create_app)
      allow(client).to receive(:delete_app)
      allow(client).to receive(:delete_session)
    end

    it 'creates the WAHA Chatwoot app with groups disabled' do
      described_class.new(
        account: account,
        phone: '5511999999999',
        api_access_token: 'account-token',
        client: client,
        config: config
      ).perform

      expect(client).to have_received(:create_session).with(
        '5511999999999',
        start: true,
        config: { ignore: hash_including(groups: true) }
      )
      expect(client).to have_received(:create_app).with(
        session: '5511999999999',
        app_id: a_string_matching(/\Aapp_/),
        config: hash_including(groups: 'OFF')
      )
    end
  end
end
