require 'rails_helper'

RSpec.describe X::RefreshTokensJob do
  let(:account) { create(:account) }

  describe '#perform' do
    it 'refreshes tokens for channels expiring within one hour' do
      expiring_channel = create(
        :channel_x,
        account: account,
        token_expires_at: 30.minutes.from_now
      )
      valid_channel = create(
        :channel_x,
        account: account,
        token_expires_at: 2.hours.from_now
      )

      token_service = instance_double(X::TokenService, refresh_access_token: true)
      allow(X::TokenService).to receive(:new).and_return(token_service)

      described_class.new.perform

      expect(X::TokenService).to have_received(:new).with(channel: expiring_channel)
      expect(X::TokenService).not_to have_received(:new).with(channel: valid_channel)
      expect(token_service).to have_received(:refresh_access_token)
    end

    it 'does not refresh already expired tokens' do
      create(
        :channel_x,
        account: account,
        token_expires_at: 2.hours.ago
      )

      allow(X::TokenService).to receive(:new)

      described_class.new.perform

      expect(X::TokenService).not_to have_received(:new)
    end

    it 'handles errors gracefully and continues processing other channels' do
      channel1 = create(:channel_x, account: account, token_expires_at: 30.minutes.from_now)
      channel2 = create(:channel_x, account: account, token_expires_at: 45.minutes.from_now)

      token_service1 = instance_double(X::TokenService)
      token_service2 = instance_double(X::TokenService, refresh_access_token: true)

      allow(X::TokenService).to receive(:new).with(channel: channel1).and_return(token_service1)
      allow(X::TokenService).to receive(:new).with(channel: channel2).and_return(token_service2)
      allow(token_service1).to receive(:refresh_access_token).and_raise(StandardError, 'Refresh failed')

      allow(Rails.logger).to receive(:error)

      described_class.new.perform

      expect(Rails.logger).to have_received(:error).with(/Failed to refresh X channel #{channel1.id}/)
      expect(token_service2).to have_received(:refresh_access_token)
    end

    it 'processes multiple channels' do
      3.times do
        create(:channel_x, account: account, token_expires_at: 30.minutes.from_now)
      end

      token_service = instance_double(X::TokenService, refresh_access_token: true)
      allow(X::TokenService).to receive(:new).and_return(token_service)

      described_class.new.perform

      expect(X::TokenService).to have_received(:new).exactly(3).times
      expect(token_service).to have_received(:refresh_access_token).exactly(3).times
    end
  end
end
