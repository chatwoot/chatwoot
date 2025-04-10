require 'rails_helper'

RSpec.describe Conversations::CanReplyService do
  describe '#can_reply?' do
    describe 'on channels without 24 hour restriction' do
      let(:conversation) { create(:conversation) }
      let(:service) { described_class.new(conversation) }

      it 'returns true' do
        expect(service.can_reply?).to be true
      end

      it 'return true for facebook channels' do
        stub_request(:post, /graph.facebook.com/)
        facebook_channel = create(:channel_facebook_page)
        facebook_inbox = create(:inbox, channel: facebook_channel, account: facebook_channel.account)
        fb_conversation = create(:conversation, inbox: facebook_inbox, account: facebook_channel.account)
        service = described_class.new(fb_conversation)

        expect(service.can_reply?).to be true
        expect(facebook_channel.messaging_window_enabled?).to be false
      end
    end

    describe 'on channels with 24 hour restriction' do
      before do
        stub_request(:post, /graph.facebook.com/)
      end

      let!(:facebook_channel) { create(:channel_facebook_page) }
      let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: facebook_channel.account) }
      let!(:conversation) { create(:conversation, inbox: facebook_inbox, account: facebook_channel.account) }

      let!(:instagram_channel) { create(:channel_instagram) }
      let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: instagram_channel.account) }
      let!(:instagram_conversation) { create(:conversation, inbox: instagram_inbox, account: instagram_channel.account) }

      context 'when instagram messenger channel' do
        it 'return true with HUMAN_AGENT if it is outside of 24 hour window' do
          InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: true)

          conversation.update(additional_attributes: { type: 'instagram_direct_message' })
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 48.hours.ago
          )
          service = described_class.new(conversation)

          expect(service.can_reply?).to be true
        end

        it 'return false without HUMAN_AGENT if it is outside of 24 hour window' do
          InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: false)

          conversation.update(additional_attributes: { type: 'instagram_direct_message' })
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 48.hours.ago
          )
          service = described_class.new(conversation)

          expect(service.can_reply?).to be false
        end
      end

      context 'when instagram channel' do
        it 'return true with HUMAN_AGENT if it is outside of 24 hour window' do
          InstallationConfig.where(name: 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT').first_or_create(value: true)

          create(:message, account: instagram_conversation.account, inbox: instagram_inbox, conversation: instagram_conversation,
                           created_at: 48.hours.ago)
          service = described_class.new(instagram_conversation)

          expect(service.can_reply?).to be true
        end

        it 'return false without HUMAN_AGENT if it is outside of 24 hour window' do
          InstallationConfig.where(name: 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT').first_or_create(value: false)

          create(:message, account: instagram_conversation.account, inbox: instagram_inbox, conversation: instagram_conversation,
                           created_at: 48.hours.ago)
          service = described_class.new(instagram_conversation)

          expect(service.can_reply?).to be false
        end
      end
    end

    describe 'on API channels' do
      let!(:api_channel) { create(:channel_api, additional_attributes: {}) }
      let!(:api_channel_with_limit) { create(:channel_api, additional_attributes: { agent_reply_time_window: '12' }) }

      context 'when agent_reply_time_window is not configured' do
        it 'return true irrespective of the last message time' do
          conversation = create(:conversation, inbox: api_channel.inbox)
          create(
            :message,
            account: conversation.account,
            inbox: api_channel.inbox,
            conversation: conversation,
            created_at: 13.hours.ago
          )
          service = described_class.new(conversation)

          expect(api_channel.additional_attributes['agent_reply_time_window']).to be_nil
          expect(service.can_reply?).to be true
        end
      end

      context 'when agent_reply_time_window is configured' do
        it 'return false if it is outside of agent_reply_time_window' do
          conversation = create(:conversation, inbox: api_channel_with_limit.inbox)
          create(
            :message,
            account: conversation.account,
            inbox: api_channel_with_limit.inbox,
            conversation: conversation,
            created_at: 13.hours.ago
          )
          service = described_class.new(conversation)

          expect(api_channel_with_limit.additional_attributes['agent_reply_time_window']).to eq '12'
          expect(service.can_reply?).to be false
        end

        it 'return true if it is inside of agent_reply_time_window' do
          conversation = create(:conversation, inbox: api_channel_with_limit.inbox)
          create(
            :message,
            account: conversation.account,
            inbox: api_channel_with_limit.inbox,
            conversation: conversation
          )
          service = described_class.new(conversation)

          expect(service.can_reply?).to be true
        end
      end
    end
  end
end
