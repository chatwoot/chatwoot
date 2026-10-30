require 'rails_helper'

describe Integrations::Slack::ChannelBuilder do
  let(:hook) { create(:integrations_hook) }
  let(:slack_client) { instance_double(Slack::Web::Client, conversations_join: true) }
  let(:builder) { described_class.new(hook: hook) }

  before { allow(Slack::Web::Client).to receive(:new).with(token: hook.access_token).and_return(slack_client) }

  describe '#join' do
    def stub_channel(attributes)
      allow(slack_client).to receive(:conversations_info).with(channel: 'C0ALERTS')
                                                         .and_return(Slack::Messages::Message.new(channel: attributes))
    end

    it 'joins a public channel the app is not a member of' do
      stub_channel(is_private: false, is_member: false)

      expect(builder.join('C0ALERTS')).to be(true)
      expect(slack_client).to have_received(:conversations_join).with(channel: 'C0ALERTS')
    end

    it 'does not join private channels or channels it is already in' do
      stub_channel(is_private: true, is_member: true)
      expect(builder.join('C0ALERTS')).to be(true)

      stub_channel(is_private: false, is_member: true)
      expect(builder.join('C0ALERTS')).to be(true)

      expect(slack_client).not_to have_received(:conversations_join)
    end

    it 'returns false when the channel is not in the workspace' do
      allow(slack_client).to receive(:conversations_info).and_raise(Slack::Web::Api::Errors::ChannelNotFound.new('channel_not_found'))

      expect(builder.join('C0ALERTS')).to be(false)
    end
  end
end
