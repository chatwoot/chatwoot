require 'rails_helper'

RSpec.describe UserAuth do
  subject { create(:user_auth) }

  let(:successful_response) do
    {
      'token_type': 'Bearer',
      'expires_in': 2_592_000,
      'access_token': 'new_token',
      'refresh_token': 'new_refresh_token'
    }
  end
  let(:stub_body) do
    {
      'grant_type': 'refresh_token',
      'client_id': 'test',
      'tenant': 'test',
      'refresh_token': subject.refresh_token
    }
  end

  before do
    stub_request(:post, Digitaltolk::Auth::Generate::API_URL)
      .to_return(status: 200, body: successful_response.to_json, headers: {})
  end

  context 'with associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe '.expiring_soon' do
    context 'when there are expirating user_auths' do
      let!(:user_auth) { create(:user_auth, expiration_datetime: 1.day.from_now) }
      let!(:other_user_auth) { create(:user_auth, expiration_datetime: 3.days.from_now) }

      it 'returns user_auths that are expiring soon' do
        expect(described_class.expiring_soon).to include(user_auth)
        expect(described_class.expiring_soon).not_to include(other_user_auth)
      end
    end

    context 'when there is no expiring soon' do
      subject { create(:user_auth, expiration_datetime: 3.days.from_now) }

      it 'returns an empty array' do
        expect(described_class.expiring_soon).to be_empty
      end
    end
  end

  describe '.token_by_email' do
    let(:user_auth) { create(:user_auth) }
    let(:email) { user_auth.user.email }

    it 'returns the token for the given email' do
      expect(described_class.token_by_email(email)).to eq(user_auth.access_token)
    end
  end

  describe '#schedule_refresh_token' do
    let(:user_auth) { create(:user_auth) }

    it 'schedules the refresh token job' do
      expect(Digitaltolk::RefreshTokenJob).to receive(:perform_later).with(user_auth).once
      user_auth.schedule_refresh_token
    end
  end

  describe '#perform_refresh_token!' do
    subject { create(:user_auth, expiration_datetime: 1.hour.from_now) }

    context 'when the refresh token is valid' do
      it 'updates the user_auth with new data' do
        user_auth = subject
        user_auth.perform_refresh_token!
        user_auth.reload

        expect(user_auth.access_token).to eq('new_token')
        expect(user_auth.refresh_token).to eq('new_refresh_token')
        expect(user_auth.expiration_datetime).to be_within(1.second).of(2_592_000.seconds.from_now)
      end

      it 'removes all expiring user_auth' do
        expect(described_class.expiring_soon).to include(subject)
        subject.perform_refresh_token!
        expect(described_class.expiring_soon).not_to include(subject)
      end
    end
  end
end
