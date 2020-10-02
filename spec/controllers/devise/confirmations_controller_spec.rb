require 'rails_helper'

RSpec.describe 'Token Confirmation', type: :request do
  describe 'POST /auth/confirmation' do
    let(:response_json) { JSON.parse(response.body, symbolize_names: true) }

    before do
      create(:user, email: 'john.doe@gmail.com', **user_attributes)

      post user_confirmation_url, params: { confirmation_token: confirmation_token }
    end

    context 'when token is valid' do
      let(:user_attributes) { { confirmation_token: '12345', skip_confirmation: false } }
      let(:confirmation_token) { '12345' }

      it 'has status 200' do
        expect(response.status).to eq 200
      end

      it 'returns message "Success"' do
        expect(response_json[:message]).to eq 'Success'
      end

      it 'returns "redirect_url"' do
        expect(response_json[:redirect_url]).to include '/app/auth/password/edit?config=default&redirect_url=&reset_password_token'
      end
    end

    context 'when token is invalid' do
      let(:user_attributes) { { confirmation_token: '12345' } }
      let(:confirmation_token) { '' }

      it 'has status 422' do
        expect(response.status).to eq 422
      end

      it 'returns message "Invalid token"' do
        expect(response_json).to eq({ message: 'Invalid token', redirect_url: '/' })
      end
    end

    context 'when user had already been confirmed' do
      let(:user_attributes) { { confirmation_token: '12345' } }
      let(:confirmation_token) { '12345' }

      it 'has status 422' do
        expect(response.status).to eq 422
      end

      it 'returns message "Already confirmed"' do
        expect(response_json).to eq({ message: 'Already confirmed', redirect_url: '/' })
      end
    end
  end
end
