require 'rails_helper'

describe Facebook::FetchProfileService do
  subject(:service) { described_class.new(user_id: user_id, page_access_token: page_access_token) }

  let(:user_id) { '1234567890' }
  let(:page_access_token) { 'EAABbcQZCZCZCZC...' }
  let(:koala_client) { double(Koala::Facebook::API) }

  before do
    allow(Koala::Facebook::API).to receive(:new).with(page_access_token).and_return(koala_client)
  end

  describe '#perform' do
    context 'when API call is successful' do
      let(:user_data) do
        {
          'id' => '1234567890',
          'first_name' => 'John',
          'last_name' => 'Doe',
          'name' => 'John Doe',
          'profile_pic' => 'https://platform-lookaside.fbsbx.com/platform/profilepic/?psid=1234567890'
        }
      end

      before do
        allow(koala_client).to receive(:get_object).with(user_id, fields: 'first_name,last_name,profile_pic,name,id').and_return(user_data)
      end

      it 'returns user data from Facebook' do
        result = service.perform
        expect(result).to eq(user_data)
      end
    end

    context 'when profile_pic is missing' do
      let(:user_data) do
        {
          'id' => '1234567890',
          'first_name' => 'John',
          'last_name' => 'Doe',
          'name' => 'John Doe'
        }
      end

      before do
        allow(koala_client).to receive(:get_object).with(user_id, fields: 'first_name,last_name,profile_pic,name,id').and_return(user_data)
      end

      it 'adds a direct Graph API URL for avatar' do
        result = service.perform
        expect(result['profile_pic']).to eq("https://graph.facebook.com/#{user_id}/picture?type=large&access_token=#{page_access_token}")
      end
    end

    context 'when authentication error occurs' do
      before do
        allow(koala_client).to receive(:get_object).and_raise(Koala::Facebook::AuthenticationError.new(401, 'Invalid OAuth access token'))
      end

      it 'returns error information' do
        result = service.perform
        expect(result[:error]).to eq('authentication_error')
        expect(result[:message]).to include('Invalid OAuth access token')
      end
    end

    context 'when client error occurs' do
      before do
        allow(koala_client).to receive(:get_object).and_raise(Koala::Facebook::ClientError.new(400, 'Client error'))
      end

      it 'returns error information and direct avatar URL' do
        result = service.perform
        expect(result[:error]).to eq('client_error')
        expect(result[:message]).to include('Client error')
        expect(result['profile_pic']).to eq("https://graph.facebook.com/#{user_id}/picture?type=large&access_token=#{page_access_token}")
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(koala_client).to receive(:get_object).and_raise(StandardError.new('Unexpected error'))
      end

      it 'returns error information and direct avatar URL' do
        result = service.perform
        expect(result[:error]).to eq('unexpected_error')
        expect(result[:message]).to include('Unexpected error')
        expect(result['profile_pic']).to eq("https://graph.facebook.com/#{user_id}/picture?type=large&access_token=#{page_access_token}")
      end
    end
  end
end
