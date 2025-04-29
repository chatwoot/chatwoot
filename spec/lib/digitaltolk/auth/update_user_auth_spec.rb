require 'rails_helper'

describe Digitaltolk::Auth::UpdateUserAuth do
  subject { described_class.new(user, data) }

  let(:user) { create(:user) }
  let(:data) do
    {
      'token_type': 'Bearer',
      'expires_in': 2_592_000,
      'access_token': 'new_token',
      'refresh_token': 'new_refresh_token'
    }
  end

  describe '#perform' do
    context 'when user is nil' do
      let(:user) { nil }

      it 'returns nil' do
        expect(subject.perform).to be_nil
      end
    end

    context 'when data is nil' do
      let(:data) { nil }

      it 'returns nil' do
        expect(subject.perform).to be_nil
      end
    end

    context 'when data is valid' do
      before do
        create(:user_auth, user: user)
      end

      it 'updates the user_auth with new data' do
        user_auth = subject.perform

        expect(user_auth.user).to eq(user)
        expect(user_auth.access_token).to eq('new_token')
        expect(user_auth.refresh_token).to eq('new_refresh_token')
        expect(user_auth.expiration_datetime).to be_within(1.second).of(2_592_000.seconds.from_now)
      end
    end
  end
end
