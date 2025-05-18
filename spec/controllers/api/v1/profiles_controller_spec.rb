require 'rails_helper'

RSpec.describe 'Profile API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/profile' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, custom_attributes: { test: 'test' }, role: :agent) }

      it 'returns current user information' do
        get '/api/v1/profile',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['email']).to eq(agent.email)
        expect(json_response['access_token']).to eq(agent.access_token.token)
        expect(json_response['custom_attributes']['test']).to eq('test')
        expect(json_response['message_signature']).to be_nil
      end
    end
  end

  describe 'PUT /api/v1/profile' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put '/api/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

      it 'updates the name' do
        put '/api/v1/profile',
            params: { profile: { name: 'test' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        agent.reload
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['name']).to eq(agent.name)
        expect(agent.name).to eq('test')
      end

      it 'updates custom attributes' do
        put '/api/v1/profile',
            params: { profile: { phone_number: '+123456789' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        agent.reload

        expect(agent.custom_attributes['phone_number']).to eq('+123456789')
      end

      it 'updates the message_signature' do
        put '/api/v1/profile',
            params: { profile: { name: 'test', message_signature: 'Thanks\nMy Signature' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        agent.reload
        expect(json_response['id']).to eq(agent.id)
        expect(json_response['name']).to eq(agent.name)
        expect(agent.name).to eq('test')
        expect(json_response['message_signature']).to eq('Thanks\nMy Signature')
      end

      it 'updates the password when current password is provided' do
        put '/api/v1/profile',
            params: { profile: { current_password: 'Test123!', password: 'Test1234!', password_confirmation: 'Test1234!' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(agent.reload.valid_password?('Test1234!')).to be true
      end

      it 'throws error when current password provided is invalid' do
        put '/api/v1/profile',
            params: { profile: { current_password: 'Test', password: 'test123', password_confirmation: 'test123' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'validate name' do
        user_name = 'test' * 999
        put '/api/v1/profile',
            params: { profile: { name: user_name } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['message']).to eq('Name is too long (maximum is 255 characters)')
      end

      it 'updates avatar' do
        # no avatar before upload
        expect(agent.avatar.attached?).to be(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        put '/api/v1/profile',
            params: { profile: { avatar: file } },
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        agent.reload
        expect(agent.avatar.attached?).to be(true)
      end

      it 'updates the ui settings' do
        put '/api/v1/profile',
            params: { profile: { ui_settings: { is_contact_sidebar_open: false } } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['ui_settings']['is_contact_sidebar_open']).to be(false)
      end
    end

    context 'when an authenticated user updates email' do
      let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

      it 'populates the unconfirmed email' do
        new_email = Faker::Internet.email
        put '/api/v1/profile',
            params: { profile: { email: new_email } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        agent.reload

        expect(agent.unconfirmed_email).to eq(new_email)
      end
    end
  end

  describe 'DELETE /api/v1/profile/avatar' do
    let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete '/api/v1/profile/avatar'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        agent.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end

      it 'deletes the agent avatar' do
        delete '/api/v1/profile/avatar',
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['avatar_url']).to be_empty
      end
    end
  end

  describe 'POST /api/v1/profile/availability' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post '/api/v1/profile/availability'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

      it 'updates the availability status' do
        post '/api/v1/profile/availability',
             params: { profile: { availability: 'busy', account_id: account.id } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(OnlineStatusTracker.get_status(account.id, agent.id)).to eq('busy')
      end

      it 'dispatches account presence updated event' do
        freeze_time
        allow(Rails.configuration.dispatcher).to receive(:dispatch).with(
          Events::Types::ACCOUNT_PRESENCE_UPDATED,
          Time.zone.now,
          account_id: account.id,
          user_id: agent.id,
          status: 'online'
        )

        post '/api/v1/profile/availability',
             params: { profile: { availability: 'online', account_id: account.id } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
      end
    end
  end

  describe 'POST /api/v1/profile/auto_offline' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post '/api/v1/profile/auto_offline'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

      it 'updates the auto offline status' do
        post '/api/v1/profile/auto_offline',
             params: { profile: { auto_offline: false, account_id: account.id } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['accounts'].first['auto_offline']).to be(false)
      end
    end
  end

  describe 'PUT /api/v1/profile/set_active_account' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put '/api/v1/profile/set_active_account'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, password: 'Test123!', account: account, role: :agent) }

      it 'updates the last active account id' do
        put '/api/v1/profile/set_active_account',
            params: { profile: { account_id: account.id } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/profile/resend_confirmation' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post '/api/v1/profile/resend_confirmation'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) do
        create(:user, password: 'Test123!', email: 'test-unconfirmed@email.com', account: account, role: :agent,
                      unconfirmed_email: 'test-unconfirmed@email.com')
      end

      it 'does not send the confirmation email if the user is already confirmed' do
        expect do
          post '/api/v1/profile/resend_confirmation',
               headers: agent.create_new_auth_token,
               as: :json
        end.not_to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)

        expect(response).to have_http_status(:success)
      end

      it 'resends the confirmation email if the user is unconfirmed' do
        agent.confirmed_at = nil
        agent.save!

        expect do
          post '/api/v1/profile/resend_confirmation',
               headers: agent.create_new_auth_token,
               as: :json
        end.to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)

        expect(response).to have_http_status(:success)
      end
    end
  end
end
