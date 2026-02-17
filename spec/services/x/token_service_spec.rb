require 'rails_helper'

RSpec.describe X::TokenService do
  let(:channel) do
    create(
      :channel_x,
      bearer_token: 'old-bearer-token',
      refresh_token: 'old-refresh-token',
      token_expires_at: 1.minute.ago,
      refresh_token_expires_at: 1.month.from_now
    )
  end

  describe '#access_token' do
    it 'returns current token when it is still valid' do
      channel.update!(token_expires_at: 10.minutes.from_now)

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('old-bearer-token')
    end

    it 'refreshes access token when expired and refresh token is valid' do
      lock_manager = instance_double(Redis::LockManager, lock: true, unlock: true)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)

      oauth_client = instance_double(OAuth2::Client)
      allow_any_instance_of(X::OAuthHelper).to receive(:auth_client).and_return(oauth_client)

      old_token = instance_double(OAuth2::AccessToken)
      allow(OAuth2::AccessToken).to receive(:from_hash).and_return(old_token)

      new_token_data = {
        token: 'new-bearer-token',
        refresh_token: 'new-refresh-token',
        expires_at: (2.hours.from_now).to_i
      }
      new_token = instance_double(OAuth2::AccessToken, new_token_data)
      allow(old_token).to receive(:refresh!).and_return(new_token)

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('new-bearer-token')
      expect(channel.reload.bearer_token).to eq('new-bearer-token')
      expect(channel.refresh_token).to eq('new-refresh-token')
      expect(channel.authorization_error_count).to eq(0)
    end

    it 'prompts reauthorization when both access and refresh tokens are expired' do
      channel.update!(token_expires_at: 1.day.ago, refresh_token_expires_at: 1.minute.ago)

      allow(channel).to receive(:reauthorization_required?).and_return(false)
      allow(channel).to receive(:prompt_reauthorization!)

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('old-bearer-token')
      expect(channel).to have_received(:prompt_reauthorization!)
    end

    it 'uses Redis lock to prevent concurrent refreshes' do
      lock_manager = instance_double(Redis::LockManager, unlock: true)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
      allow(lock_manager).to receive(:lock).and_return(false)

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('old-bearer-token')
      expect(lock_manager).to have_received(:lock)
    end

    it 'reloads channel before refresh to avoid stale data' do
      lock_manager = instance_double(Redis::LockManager, lock: true, unlock: true)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
      allow(channel).to receive(:reload).and_call_original

      # Make token expired so refresh is triggered
      channel.update!(token_expires_at: 1.hour.ago)

      # Stub OAuth2 refresh
      allow_any_instance_of(described_class).to receive(:attempt_refresh_token).and_return({
        access_token: 'new-token',
        refresh_token: 'new-refresh',
        expires_at: 2.hours.from_now
      })

      described_class.new(channel: channel).access_token

      expect(channel).to have_received(:reload)
    end
  end

  describe '#refresh_access_token' do
    it 'handles OAuth2 errors and increments authorization_error_count' do
      lock_manager = instance_double(Redis::LockManager, lock: true, unlock: true)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)

      allow_any_instance_of(described_class).to receive(:attempt_refresh_token).and_raise(OAuth2::Error.new('error'))
      allow(channel).to receive(:authorization_error!)
      allow(channel).to receive(:reauthorization_required?).and_return(false)

      expect { described_class.new(channel: channel).refresh_access_token }.to raise_error(OAuth2::Error)
      expect(channel).to have_received(:authorization_error!)
    end

    it 'sends notification email when reauthorization is required' do
      lock_manager = instance_double(Redis::LockManager, lock: true, unlock: true)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)

      mailer = double
      mailer_instance = double
      allow(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:x_disconnect).and_return(mailer_instance)
      allow(mailer_instance).to receive(:deliver_later)

      allow_any_instance_of(described_class).to receive(:attempt_refresh_token).and_raise(OAuth2::Error.new('error'))
      allow(channel).to receive(:authorization_error!)
      allow(channel).to receive(:reauthorization_required?).and_return(true)

      expect { described_class.new(channel: channel).refresh_access_token }.to raise_error(OAuth2::Error)

      expect(mailer).to have_received(:x_disconnect).with(channel.inbox)
      expect(mailer_instance).to have_received(:deliver_later)
    end
  end
end
