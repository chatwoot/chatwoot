require 'rails_helper'

RSpec.describe Instagram::RefreshOauthTokenService do
  let(:account) { create(:account) }
  let(:refresh_response) do
    {
      'access_token' => 'new_refreshed_token',
      'expires_in' => 5_184_000 # 60 days in seconds
    }
  end
  let(:fixed_token) { 'c061d0c51973a8fcab2ecec86f6aa41718414a10070967a5e9a58f49bf8a798e' }
  let(:instagram_channel) do
    create(:channel_instagram,
           account: account,
           access_token: fixed_token,
           expires_at: 20.days.from_now) # Set default expiry
  end
  let(:service) { described_class.new(channel: instagram_channel) }

  before do
    stub_request(:get, 'https://graph.instagram.com/refresh_access_token')
      .with(
        query: {
          'access_token' => fixed_token,
          'grant_type' => 'ig_refresh_token'
        },
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: refresh_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#access_token' do
    context 'when token is valid and not eligible for refresh' do
      before do
        instagram_channel.update!(
          updated_at: 12.hours.ago # Less than 24 hours old
        )
      end

      it 'returns existing token without refresh' do
        expect(service).not_to receive(:refresh_long_lived_token)
        expect(service.access_token).to eq(fixed_token)
      end
    end

    context 'when token is eligible for refresh' do
      before do
        instagram_channel.update!(
          expires_at: 5.days.from_now, # Within 10 days window
          updated_at: 25.hours.ago     # More than 24 hours old
        )
      end

      it 'refreshes the token and updates channel' do
        expect(service.access_token).to eq('new_refreshed_token')
        instagram_channel.reload
        expect(instagram_channel.access_token).to eq('new_refreshed_token')
        expect(instagram_channel.expires_at).to be_within(1.second).of(5_184_000.seconds.from_now)
      end
    end
  end

  describe 'private methods' do
    describe '#token_valid?' do
      # For the expires_at null test, we need to modify the validation or use a different approach
      context 'when expires_at is blank' do
        it 'returns false' do
          allow(instagram_channel).to receive(:expires_at).and_return(nil)
          expect(service.send(:token_valid?)).to be false
        end
      end

      context 'when token is expired' do
        it 'returns false' do
          allow(instagram_channel).to receive(:expires_at).and_return(1.hour.ago)
          expect(service.send(:token_valid?)).to be false
        end
      end

      context 'when token is valid' do
        it 'returns true' do
          allow(instagram_channel).to receive(:expires_at).and_return(1.day.from_now)
          expect(service.send(:token_valid?)).to be true
        end
      end
    end

    describe '#token_eligible_for_refresh?' do
      context 'when token is too new' do
        before do
          allow(instagram_channel).to receive(:updated_at).and_return(12.hours.ago)
          allow(instagram_channel).to receive(:expires_at).and_return(5.days.from_now)
        end

        it 'returns false' do
          expect(service.send(:token_eligible_for_refresh?)).to be false
        end
      end

      context 'when token is not approaching expiry' do
        before do
          allow(instagram_channel).to receive(:updated_at).and_return(25.hours.ago)
          allow(instagram_channel).to receive(:expires_at).and_return(20.days.from_now)
        end

        it 'returns false' do
          expect(service.send(:token_eligible_for_refresh?)).to be false
        end
      end

      context 'when token is expired' do
        before do
          allow(instagram_channel).to receive(:updated_at).and_return(25.hours.ago)
          allow(instagram_channel).to receive(:expires_at).and_return(1.hour.ago)
        end

        it 'returns false' do
          expect(service.send(:token_eligible_for_refresh?)).to be false
        end
      end
    end
  end
end
