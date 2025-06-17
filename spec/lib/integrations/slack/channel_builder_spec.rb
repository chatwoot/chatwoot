require 'rails_helper'

RSpec.describe Integrations::Slack::ChannelBuilder do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account, app_id: 'slack', access_token: 'test-token') }
  let(:builder) { described_class.new(hook: hook) }
  let(:slack_client) { instance_double(Slack::Web::Client) }

  before do
    allow(Slack::Web::Client).to receive(:new).with(token: 'test-token').and_return(slack_client)
  end

  describe '#fetch_channels' do
    let(:public_channel) do
      double('Channel',
             id: 'C123',
             name: 'general',
             is_private: false)
    end

    let(:private_channel) do
      double('Channel',
             id: 'G456',
             name: 'private-team',
             is_private: true)
    end

    context 'when API returns channels without pagination' do
      let(:api_response) do
        double('Response',
               channels: [public_channel, private_channel],
               response_metadata: double('Metadata', next_cursor: nil))
      end

      before do
        allow(slack_client).to receive(:conversations_list)
          .with(types: 'public_channel,private_channel', exclude_archived: true)
          .and_return(api_response)
      end

      it 'fetches all channels' do
        channels = builder.fetch_channels
        expect(channels).to eq([public_channel, private_channel])
      end

      it 'calls Slack API with correct parameters' do
        builder.fetch_channels
        expect(slack_client).to have_received(:conversations_list)
          .with(types: 'public_channel,private_channel', exclude_archived: true)
      end
    end

    context 'when API returns channels with pagination' do
      let(:first_page_response) do
        double('Response',
               channels: [public_channel],
               response_metadata: double('Metadata', next_cursor: 'cursor-123'))
      end

      let(:second_page_response) do
        double('Response',
               channels: [private_channel],
               response_metadata: double('Metadata', next_cursor: nil))
      end

      before do
        allow(slack_client).to receive(:conversations_list)
          .with(types: 'public_channel,private_channel', exclude_archived: true)
          .and_return(first_page_response)

        allow(slack_client).to receive(:conversations_list)
          .with(
            cursor: 'cursor-123',
            types: 'public_channel,private_channel',
            exclude_archived: true
          )
          .and_return(second_page_response)
      end

      it 'fetches channels from all pages' do
        channels = builder.fetch_channels
        expect(channels).to eq([public_channel, private_channel])
      end

      it 'calls Slack API for each page with correct parameters' do
        builder.fetch_channels

        expect(slack_client).to have_received(:conversations_list)
          .with(types: 'public_channel,private_channel', exclude_archived: true)

        expect(slack_client).to have_received(:conversations_list)
          .with(
            cursor: 'cursor-123',
            types: 'public_channel,private_channel',
            exclude_archived: true
          )
      end
    end

    context 'when API returns multiple pages' do
      let(:page1_response) do
        double('Response',
               channels: [public_channel],
               response_metadata: double('Metadata', next_cursor: 'cursor-1'))
      end

      let(:page2_response) do
        double('Response',
               channels: [private_channel],
               response_metadata: double('Metadata', next_cursor: 'cursor-2'))
      end

      let(:page3_response) do
        double('Response',
               channels: [double('Channel', id: 'C789', name: 'random', is_private: false)],
               response_metadata: double('Metadata', next_cursor: nil))
      end

      before do
        allow(slack_client).to receive(:conversations_list)
          .with(types: 'public_channel,private_channel', exclude_archived: true)
          .and_return(page1_response)

        allow(slack_client).to receive(:conversations_list)
          .with(cursor: 'cursor-1', types: 'public_channel,private_channel', exclude_archived: true)
          .and_return(page2_response)

        allow(slack_client).to receive(:conversations_list)
          .with(cursor: 'cursor-2', types: 'public_channel,private_channel', exclude_archived: true)
          .and_return(page3_response)
      end

      it 'handles multiple pages correctly' do
        channels = builder.fetch_channels
        expect(channels.length).to eq(3)
        expect(channels.map(&:name)).to contain_exactly('general', 'private-team', 'random')
      end
    end

    context 'when filtering channels by privacy' do
      let(:api_response) do
        double('Response',
               channels: [public_channel, private_channel],
               response_metadata: double('Metadata', next_cursor: nil))
      end

      before do
        allow(slack_client).to receive(:conversations_list)
          .with(types: 'public_channel,private_channel', exclude_archived: true)
          .and_return(api_response)
      end

      it 'returns both public and private channels' do
        channels = builder.fetch_channels
        public_channels = channels.select { |c| !c.is_private }
        private_channels = channels.select { |c| c.is_private }

        expect(public_channels.length).to eq(1)
        expect(private_channels.length).to eq(1)
        expect(public_channels.first.name).to eq('general')
        expect(private_channels.first.name).to eq('private-team')
      end
    end

    context 'when Slack API raises an error' do
      before do
        allow(slack_client).to receive(:conversations_list)
          .and_raise(Slack::Web::Api::Errors::SlackError.new('invalid_auth'))
      end

      it 'propagates the error' do
        expect { builder.fetch_channels }.to raise_error(Slack::Web::Api::Errors::SlackError, 'invalid_auth')
      end
    end
  end

  describe '#update' do
    let(:reference_id) { 'C123456' }
    let(:channel_data) do
      {
        'id' => 'C123456',
        'name' => 'general',
        'is_private' => false,
        :id => 'C123456',
        :name => 'general',
        :is_private => false
      }
    end

    let(:channel_object) do
      double('Channel').tap do |channel|
        allow(channel).to receive(:[]).with('id').and_return('C123456')
        allow(channel).to receive(:[]).with('name').and_return('general')
        allow(channel).to receive(:[]).with('is_private').and_return(false)
        allow(channel).to receive(:[]).with(:id).and_return('C123456')
        allow(channel).to receive(:[]).with(:name).and_return('general')
        allow(channel).to receive(:[]).with(:is_private).and_return(false)
      end
    end

    let(:api_response) do
      double('Response',
             channels: [channel_object],
             response_metadata: double('Metadata', next_cursor: nil))
    end

    before do
      allow(slack_client).to receive(:conversations_list)
        .with(types: 'public_channel,private_channel', exclude_archived: true)
        .and_return(api_response)
      allow(slack_client).to receive(:conversations_join)
    end

    context 'when channel exists and is public' do
      it 'joins the channel and updates hook' do
        result = builder.update(reference_id)

        expect(slack_client).to have_received(:conversations_join).with(channel: 'C123456')
        expect(hook.reference_id).to eq('C123456')
        expect(hook.settings['channel_name']).to eq('general')
        expect(hook.status).to eq('enabled')
        expect(result).to eq(hook)
      end
    end

    context 'when channel exists and is private' do
      let(:channel_object) do
        double('Channel').tap do |channel|
          allow(channel).to receive(:[]).with('id').and_return('G123456')
          allow(channel).to receive(:[]).with('name').and_return('private-channel')
          allow(channel).to receive(:[]).with('is_private').and_return(true)
          allow(channel).to receive(:[]).with(:id).and_return('G123456')
          allow(channel).to receive(:[]).with(:name).and_return('private-channel')
          allow(channel).to receive(:[]).with(:is_private).and_return(true)
        end
      end

      let(:api_response) do
        double('Response',
               channels: [channel_object],
               response_metadata: double('Metadata', next_cursor: nil))
      end

      let(:reference_id) { 'G123456' }

      it 'does not join the channel but updates hook' do
        result = builder.update(reference_id)

        expect(slack_client).not_to have_received(:conversations_join)
        expect(hook.reference_id).to eq('G123456')
        expect(hook.settings['channel_name']).to eq('private-channel')
        expect(result).to eq(hook)
      end
    end

    context 'when channel does not exist' do
      let(:api_response) do
        double('Response',
               channels: [],
               response_metadata: double('Metadata', next_cursor: nil))
      end

      it 'does not update hook and returns nil' do
        original_reference_id = hook.reference_id
        result = builder.update('nonexistent')

        expect(hook.reference_id).to eq(original_reference_id)
        expect(slack_client).not_to have_received(:conversations_join)
        expect(result).to be_nil
      end
    end
  end
end