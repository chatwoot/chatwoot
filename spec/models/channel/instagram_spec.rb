# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::Instagram do
  let(:channel) { create(:channel_instagram) }

  it { is_expected.to validate_presence_of(:account_id) }
  it { is_expected.to validate_presence_of(:access_token) }
  it { is_expected.to validate_presence_of(:instagram_id) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_one(:inbox).dependent(:destroy_async) }

  it 'has a valid name' do
    expect(channel.name).to eq('Instagram')
  end

  it 'keeps the existing length limit for Instagram Login tokens' do
    channel = build(:channel_instagram, account: create(:account), access_token: 'a' * 256)
    expect(channel).not_to be_valid
    expect(channel.errors[:access_token]).to be_present
  end

  describe '#subscribe' do
    it 'logs an error when the subscription fails on the Instagram Login path' do
      channel = build(:channel_instagram, account: create(:account))
      allow(HTTParty).to receive(:post).and_raise(StandardError, 'boom')
      allow(Rails.logger).to receive(:error)

      channel.subscribe

      expect(Rails.logger).to have_received(:error)
        .with(a_string_including("Failed to subscribe account #{channel.instagram_id}"))
    end
  end

  context 'with Unified Login' do
    let(:channel) { build(:channel_instagram, account: create(:account), auth_type: 'unified_login', access_token: 'system_token', expires_at: nil) }

    it 'returns the non-expiring token without attempting an Instagram refresh' do
      expect(Instagram::RefreshOauthTokenService).not_to receive(:new)
      expect(channel.access_token).to eq('system_token')
      expect(channel.base_uri).to eq('https://graph.facebook.com/v22.0')
    end

    it 'keeps the stored token when validating an unsaved expired channel without prompting reauthorization' do
      channel.expires_at = 1.minute.ago
      expect(channel).not_to receive(:prompt_reauthorization!)
      expect(channel.access_token).to eq('system_token')
      expect(channel).to be_valid
    end

    it 'accepts long system-user tokens while retaining a bounded length validation' do
      channel.access_token = 'a' * 1500
      expect(channel).to be_valid
      channel.access_token = 'a' * (ApplicationRecord::MAX_TEXT_COLUMN_LENGTH + 1)
      expect(channel).not_to be_valid
      expect(channel.errors[:access_token]).to be_present
    end

    it 'unsubscribes using the correct Graph host' do
      request = stub_request(:delete, "#{channel.base_uri}/#{channel.instagram_id}/subscribed_apps")
                .with(query: { access_token: 'system_token' }).to_return(body: { success: true }.to_json)
      channel.unsubscribe
      expect(request).to have_been_requested.once
    end
  end

  describe '#find_message_by_source_id' do
    let(:channel) { create(:channel_instagram, auth_type: 'unified_login', expires_at: nil) }
    let(:ids) { JSON.parse(Rails.root.join('spec/fixtures/instagram/unified_login_message_ids.json').read) }
    let(:conversation) { create(:conversation, account: channel.account, inbox: channel.inbox) }
    let!(:message) do
      create(:message, account: channel.account, inbox: channel.inbox, conversation: conversation,
                       message_type: :outgoing, source_id: ids.fetch('first_send'))
    end

    it 'finds the original message using either provider ID' do
      expect(channel.find_message_by_source_id(ids.fetch('first_send'))).to eq(message)
      expect(channel.find_message_by_source_id(ids.fetch('first_echo'))).to eq(message)
    end

    it 'does not match an equivalent ID in a different inbox' do
      other_channel = create(:channel_instagram, auth_type: 'unified_login', expires_at: nil)
      expect(other_channel.find_message_by_source_id(ids.fetch('first_echo'))).to be_nil
    end

    it 'keeps exact ID matching for Instagram Login' do
      channel.update!(auth_type: 'instagram_login', expires_at: 60.days.from_now)
      expect(channel.find_message_by_source_id(ids.fetch('first_echo'))).to be_nil
      expect(channel.find_message_by_source_id(ids.fetch('first_send'))).to eq(message)
    end
  end

  context 'when a persisted Unified Login token expires' do
    let(:channel) { create(:channel_instagram, auth_type: 'unified_login', access_token: 'system_token', expires_at: 1.hour.from_now) }

    before do
      allow(channel).to receive(:send_channel_reauthorization_email)
      allow(channel).to receive(:dispatch_inbox_reauthorization_event)
    end

    it 'marks the inbox for reconnection at expiry and preserves the stored token' do
      expiry = channel.reload.expires_at
      travel_to(expiry, with_usec: true) do
        expect(channel.access_token).to eq('system_token')
        expect(channel.reauthorization_required?).to be(true)
        expect(channel).to have_received(:dispatch_inbox_reauthorization_event).with(true)
        expect(channel).to be_valid
      end
    end

    it 'notifies once across repeated reads and provider authorization errors' do
      expiry = channel.reload.expires_at
      travel_to(expiry, with_usec: true) do
        2.times { channel.access_token }
        channel.authorization_error!
        expect(channel).to have_received(:send_channel_reauthorization_email).with(:instagram_disconnect).once
      end
    end

    it 'allows reconnection and detects a later expiry again' do
      expiry = channel.reload.expires_at
      travel_to(expiry, with_usec: true) do
        channel.access_token
        channel.update!(access_token: 'replacement_token', expires_at: 1.hour.from_now)
        channel.reauthorized!
        expect(channel.reauthorization_required?).to be(false)
        expect(channel.access_token).to eq('replacement_token')
      end
      travel_to(expiry + 1.hour, with_usec: true) do
        expect(channel.access_token).to eq('replacement_token')
        expect(channel.reauthorization_required?).to be(true)
        expect(channel).to have_received(:send_channel_reauthorization_email).twice
      end
    end

    it 'does not prompt for reconnection while removing an expired app subscription' do
      expiry = channel.reload.expires_at
      stub_request(:delete, "#{channel.base_uri}/#{channel.instagram_id}/subscribed_apps")
        .with(query: { access_token: 'system_token' }).to_return(body: { success: true }.to_json)
      travel_to(expiry, with_usec: true) do
        channel.unsubscribe
        expect(channel.reauthorization_required?).to be(false)
        expect(channel).not_to have_received(:send_channel_reauthorization_email)
      end
    end
  end

  describe 'concerns' do
    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for instagram' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:instagram_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end
  end
end
