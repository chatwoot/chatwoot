require 'rails_helper'

describe Integrations::Slack::ChannelBuilder do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account, settings: { channel_name: 'old-name', unfurl_links: true }) }
  let(:slack_client) { instance_double(Slack::Web::Client) }

  let(:channel) { { 'id' => 'C123', 'name' => 'support', 'is_private' => false } }

  # Slack::Messages::Message e um Hashie::Mash, entao instance_double nao verifica o metodo:
  # a resposta de verdade responde por chave, nao por metodo declarado na classe.
  def conversations_list_response(channels)
    Slack::Messages::Message.new(channels: channels, response_metadata: { next_cursor: nil })
  end

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(slack_client).to receive(:conversations_list)
      .with(hash_including(types: 'private_channel')).and_return(conversations_list_response([]))
    allow(slack_client).to receive(:conversations_list)
      .with(hash_including(types: 'public_channel')).and_return(conversations_list_response([channel]))
  end

  describe '#update_reference_id' do
    context 'when the channel is joinable' do
      before { allow(slack_client).to receive(:conversations_join).and_return(true) }

      it 'writes the channel it was pointed at' do
        described_class.new(hook: hook).update_reference_id('C123')

        expect(hook.reload.reference_id).to eq('C123')
        expect(hook.reload.settings['channel_name']).to eq('support')
        expect(hook.reload.status).to eq('enabled')
      end

      it 'leaves the settings it does not own alone' do
        described_class.new(hook: hook).update_reference_id('C123')

        expect(hook.reload.settings['unfurl_links']).to be(true)
      end

      # The merge is taken on a separate row object on purpose, so the hook handed back has to be
      # read again: the controller renders what this returns.
      it 'hands back a hook that carries what was written' do
        returned = described_class.new(hook: hook).update_reference_id('C123')

        expect(returned.settings['channel_name']).to eq('support')
        expect(returned.reference_id).to eq('C123')
      end
    end

    # A escrita de terceiro que entra DURANTE a chamada de rede. O outro escritor e a API publica
    # de hooks (`PATCH .../integrations/hooks/:id`, que aceita `settings` como hash aberto), e a
    # gravacao direta na linha e o que torna o defeito reproduzivel sem thread: a copia que o
    # builder escreve de volta nao e nem lida, ela e substituida por uma chave so.
    context 'when another writer lands on the settings while Slack is answering' do
      before do
        allow(slack_client).to receive(:conversations_join) do
          Integrations::Hook.where(id: hook.id)
                            .update_all("settings = settings || '{\"alert_channel\":\"ops\"}'::jsonb") # rubocop:disable Rails/SkipsModelValidations
          true
        end
      end

      it 'keeps the key that landed during the join' do
        described_class.new(hook: hook).update_reference_id('C123')

        expect(hook.reload.settings['alert_channel']).to eq('ops')
      end
    end

    context 'when the reference id names no channel' do
      it 'writes nothing' do
        expect(described_class.new(hook: hook).update_reference_id('C999')).to be_nil
        expect(hook.reload.settings['channel_name']).to eq('old-name')
      end
    end
  end

  describe '#join' do
    let(:hook) { create(:integrations_hook) }
    let(:slack_client) { instance_double(Slack::Web::Client, conversations_join: true) }
    let(:builder) { described_class.new(hook: hook) }

    before { allow(Slack::Web::Client).to receive(:new).with(token: hook.access_token).and_return(slack_client) }

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
