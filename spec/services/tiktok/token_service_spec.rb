require 'rails_helper'

RSpec.describe Tiktok::TokenService do
  let(:channel) do
    create(
      :channel_tiktok,
      access_token: 'old-access-token',
      refresh_token: 'old-refresh-token',
      expires_at: 1.minute.ago,
      refresh_token_expires_at: 1.day.from_now
    )
  end

  describe '#access_token' do
    it 'returns current token when it is still valid' do
      channel.update!(expires_at: 10.minutes.from_now)
      allow(Tiktok::AuthClient).to receive(:renew_short_term_access_token)

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('old-access-token')
      expect(Tiktok::AuthClient).not_to have_received(:renew_short_term_access_token)
    end

    it 'refreshes access token when expired and refresh token is valid' do
      lock_manager = instance_double(Redis::LockManager, lock: true, unlock: true)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)

      allow(Tiktok::AuthClient).to receive(:renew_short_term_access_token).and_return(
        {
          access_token: 'new-access-token',
          refresh_token: 'new-refresh-token',
          expires_at: 1.day.from_now,
          refresh_token_expires_at: 30.days.from_now
        }.with_indifferent_access
      )

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('new-access-token')
      expect(channel.reload.access_token).to eq('new-access-token')
      expect(channel.refresh_token).to eq('new-refresh-token')
    end

    it 'prompts reauthorization when both access and refresh tokens are expired' do
      channel.update!(expires_at: 1.day.ago, refresh_token_expires_at: 1.minute.ago)

      allow(channel).to receive(:reauthorization_required?).and_return(false)
      allow(channel).to receive(:prompt_reauthorization!)

      token = described_class.new(channel: channel).access_token

      expect(token).to eq('old-access-token')
      expect(channel).to have_received(:prompt_reauthorization!)
    end
  end
end
