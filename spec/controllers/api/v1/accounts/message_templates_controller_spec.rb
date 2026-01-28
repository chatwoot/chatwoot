require 'rails_helper'

RSpec.describe 'Message Templates API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/message_templates' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/message_templates"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:inbox) { create(:inbox, account: account) }
      let(:inbox2) { create(:inbox, account: account) }

      before do
        create(:message_template, account: account, inbox: inbox, name: 'template1', channel_type: 'Channel::Whatsapp', language: 'en',
                                  status: 'approved')
        create(:message_template, account: account, inbox: inbox, name: 'template2', channel_type: 'Channel::Sms', language: 'es', status: 'draft')
        create(:message_template, account: account, inbox: inbox2, name: 'template3', channel_type: 'Channel::Whatsapp', language: 'en',
                                  status: 'pending')
      end

      it 'returns all message templates for administrator' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(3)
      end

      it 'returns all message templates for agent' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(3)
      end

      it 'filters message templates by inbox_id' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: agent.create_new_auth_token,
            params: { inbox_id: inbox.id },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(2)
        expect(response_data.pluck(:inbox_id).uniq).to eq([inbox.id])
      end

      it 'filters message templates by channel_type' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: agent.create_new_auth_token,
            params: { channel_type: 'Channel::Whatsapp' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(2)
        expect(response_data.pluck(:channel_type).uniq).to eq(['Channel::Whatsapp'])
      end

      it 'filters message templates by language' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: agent.create_new_auth_token,
            params: { language: 'en' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(2)
        expect(response_data.pluck(:language).uniq).to eq(['en'])
      end

      it 'filters message templates by status' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: agent.create_new_auth_token,
            params: { status: 'approved' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(1)
        expect(response_data.first[:status]).to eq('approved')
      end

      it 'combines multiple filters' do
        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: agent.create_new_auth_token,
            params: { inbox_id: inbox.id, channel_type: 'Channel::Whatsapp', language: 'en' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(1)
        expect(response_data.first[:name]).to eq('template1')
      end

      it 'does not allow user from different account to access templates' do
        other_account = create(:account)
        other_user = create(:user, account: other_account, role: :administrator)

        get "/api/v1/accounts/#{account.id}/message_templates",
            headers: other_user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/message_templates/:id' do
    let(:inbox) { create(:inbox, account: account) }
    let(:message_template) { create(:message_template, account: account, inbox: inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/message_templates/#{message_template.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'shows the message template for administrator' do
        get "/api/v1/accounts/#{account.id}/message_templates/#{message_template.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:id]).to eq(message_template.id)
        expect(response_data[:name]).to eq(message_template.name)
      end

      it 'shows the message template for agent' do
        get "/api/v1/accounts/#{account.id}/message_templates/#{message_template.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:id]).to eq(message_template.id)
      end

      it 'returns not found for non-existent template' do
        get "/api/v1/accounts/#{account.id}/message_templates/999999",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/message_templates' do
    let(:inbox) { create(:inbox, account: account) }
    let(:valid_params) do
      {
        message_template: {
          name: 'new_template',
          inbox_id: inbox.id,
          category: 'marketing',
          language: 'en',
          channel_type: 'Channel::Sms', # TODO: channel type to be whatsapp
          status: 'draft',
          parameter_format: 'positional',
          content: {
            body: 'Hello {{1}}, welcome to our service!'
          }
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/message_templates",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        Current.user = nil
      end

      it 'creates a new message template as administrator' do
        post "/api/v1/accounts/#{account.id}/message_templates",
             headers: administrator.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:name]).to eq('new_template')
        expect(response_data[:category]).to eq('marketing')
        expect(response_data[:created_by][:id]).to eq(administrator.id)

        template = MessageTemplate.find(response_data[:id])
        expect(template.created_by).to eq(administrator)
      end

      it 'does not allow agent to create message template' do
        post "/api/v1/accounts/#{account.id}/message_templates",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error for invalid params' do
        invalid_params = valid_params.deep_dup
        invalid_params[:message_template][:name] = 'invalid name with spaces'

        post "/api/v1/accounts/#{account.id}/message_templates",
             headers: administrator.create_new_auth_token,
             params: invalid_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:message]).to include('Name is invalid')
      end

      it 'returns error for duplicate template name in same inbox and language' do
        create(:message_template, account: account, inbox: inbox, name: 'new_template', language: 'en')

        post "/api/v1/accounts/#{account.id}/message_templates",
             headers: administrator.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:message]).to include('already exists for this language and inbox')
      end

      it 'returns error when inbox does not belong to account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)
        invalid_params = valid_params.deep_dup
        invalid_params[:message_template][:inbox_id] = other_inbox.id

        post "/api/v1/accounts/#{account.id}/message_templates",
             headers: administrator.create_new_auth_token,
             params: invalid_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:message]).to include('Inbox does not belong to this account')
      end

      it 'does not allow user from different account to create templates' do
        other_account = create(:account)
        other_user = create(:user, account: other_account, role: :administrator)

        post "/api/v1/accounts/#{account.id}/message_templates",
             headers: other_user.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
