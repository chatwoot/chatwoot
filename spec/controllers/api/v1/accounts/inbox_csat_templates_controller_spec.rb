require 'rails_helper'

RSpec.describe Api::V1::Accounts::InboxCsatTemplatesController, type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:web_widget_inbox) { create(:inbox, account: account) }
  let(:mock_service) { instance_double(Whatsapp::CsatTemplateService) }

  before do
    create(:inbox_member, user: agent, inbox: whatsapp_inbox)
    allow(Whatsapp::CsatTemplateService).to receive(:new).and_return(mock_service)
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/csat_template' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is not a WhatsApp channel' do
      it 'returns bad request' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{web_widget_inbox.id}/csat_template",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['error']).to eq('CSAT template operations only available for WhatsApp and Twilio WhatsApp channels')
      end
    end

    context 'when it is a WhatsApp channel' do
      it 'returns template not found when no configuration exists' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['template_exists']).to be false
      end

      it 'returns template status when template exists on WhatsApp' do
        template_config = {
          'template' => {
            'name' => 'custom_survey_template',
            'template_id' => '123456789',
            'language' => 'en'
          }
        }
        whatsapp_inbox.update!(csat_config: template_config)

        allow(mock_service).to receive(:get_template_status)
          .with('custom_survey_template')
          .and_return({
                        success: true,
                        template: { id: '123456789', status: 'APPROVED' }
                      })

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = response.parsed_body
        expect(response_data['template_exists']).to be true
        expect(response_data['template_name']).to eq('custom_survey_template')
        expect(response_data['status']).to eq('APPROVED')
        expect(response_data['template_id']).to eq('123456789')
      end

      it 'returns template not found when template does not exist on WhatsApp' do
        template_config = { 'template' => { 'name' => 'custom_survey_template' } }
        whatsapp_inbox.update!(csat_config: template_config)

        allow(mock_service).to receive(:get_template_status)
          .with('custom_survey_template')
          .and_return({ success: false, error: 'Template not found' })

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = response.parsed_body
        expect(response_data['template_exists']).to be false
        expect(response_data['error']).to eq('Template not found')
      end

      it 'handles service errors gracefully' do
        template_config = { 'template' => { 'name' => 'custom_survey_template' } }
        whatsapp_inbox.update!(csat_config: template_config)

        allow(mock_service).to receive(:get_template_status)
          .and_raise(StandardError, 'API connection failed')

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body['error']).to eq('API connection failed')
      end

      it 'returns unauthorized when agent is not assigned to inbox' do
        other_agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
            headers: other_agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'allows access when agent is assigned to inbox' do
        whatsapp_inbox.update!(csat_config: { 'template' => { 'name' => 'test' } })
        allow(mock_service).to receive(:get_template_status)
          .and_return({ success: true, template: { id: '123', status: 'APPROVED' } })

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/{inbox.id}/csat_template' do
    let(:valid_template_params) do
      {
        template: {
          message: 'How would you rate your experience?',
          button_text: 'Rate Us',
          language: 'en'
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is not a WhatsApp channel' do
      it 'returns bad request' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{web_widget_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['error']).to eq('CSAT template operations only available for WhatsApp and Twilio WhatsApp channels')
      end
    end

    context 'when it is a WhatsApp channel' do
      it 'returns error when message is missing' do
        invalid_params = {
          template: {
            button_text: 'Rate Us',
            language: 'en'
          }
        }

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: invalid_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Message is required')
      end

      it 'returns error when template parameters are completely missing' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: {},
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Template parameters are required')
      end

      it 'creates template successfully' do
        allow(mock_service).to receive(:get_template_status).and_return({ success: false })
        allow(mock_service).to receive(:create_template).and_return({
                                                                      success: true,
                                                                      template_name: "customer_satisfaction_survey_#{whatsapp_inbox.id}",
                                                                      template_id: '987654321'
                                                                    })

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:created)
        response_data = response.parsed_body
        expect(response_data['template']['name']).to eq("customer_satisfaction_survey_#{whatsapp_inbox.id}")
        expect(response_data['template']['template_id']).to eq('987654321')
        expect(response_data['template']['status']).to eq('PENDING')
        expect(response_data['template']['language']).to eq('en')
      end

      it 'uses default values for optional parameters' do
        minimal_params = {
          template: {
            message: 'How would you rate your experience?'
          }
        }

        allow(mock_service).to receive(:get_template_status).and_return({ success: false })
        expect(mock_service).to receive(:create_template) do |config|
          expect(config[:button_text]).to eq('Please rate us')
          expect(config[:language]).to eq('en')
          expect(config[:template_name]).to eq("customer_satisfaction_survey_#{whatsapp_inbox.id}")
          { success: true, template_name: "customer_satisfaction_survey_#{whatsapp_inbox.id}", template_id: '123' }
        end

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: minimal_params,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'handles WhatsApp API errors with user-friendly messages' do
        whatsapp_error_response = {
          'error' => {
            'code' => 100,
            'error_subcode' => 2_388_092,
            'message' => 'Invalid parameter',
            'error_user_title' => 'Template Creation Failed',
            'error_user_msg' => 'The template message contains invalid content. Please review your message and try again.'
          }
        }

        allow(mock_service).to receive(:get_template_status).and_return({ success: false })
        allow(mock_service).to receive(:create_template).and_return({
                                                                      success: false,
                                                                      error: 'Template creation failed',
                                                                      response_body: whatsapp_error_response.to_json
                                                                    })

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = response.parsed_body
        expect(response_data['error']).to eq('The template message contains invalid content. Please review your message and try again.')
        expect(response_data['details']).to include({
                                                      'code' => 100,
                                                      'subcode' => 2_388_092,
                                                      'title' => 'Template Creation Failed'
                                                    })
      end

      it 'handles generic API errors' do
        allow(mock_service).to receive(:get_template_status).and_return({ success: false })
        allow(mock_service).to receive(:create_template).and_return({
                                                                      success: false,
                                                                      error: 'Network timeout',
                                                                      response_body: nil
                                                                    })

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Network timeout')
      end

      it 'handles unexpected service errors' do
        allow(mock_service).to receive(:get_template_status).and_return({ success: false })
        allow(mock_service).to receive(:create_template)
          .and_raise(StandardError, 'Unexpected error')

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body['error']).to eq('Template creation failed')
      end

      it 'deletes existing template before creating new one' do
        whatsapp_inbox.update!(csat_config: {
                                 'template' => {
                                   'name' => 'existing_template',
                                   'template_id' => '111111111'
                                 }
                               })

        allow(mock_service).to receive(:get_template_status)
          .with('existing_template')
          .and_return({ success: true, template: { id: '111111111' } })
        expect(mock_service).to receive(:delete_template)
          .with('existing_template')
          .and_return({ success: true })
        expect(mock_service).to receive(:create_template)
          .and_return({
                        success: true,
                        template_name: "customer_satisfaction_survey_#{whatsapp_inbox.id}",
                        template_id: '222222222'
                      })

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'continues with creation even if deletion fails' do
        whatsapp_inbox.update!(csat_config: {
                                 'template' => { 'name' => 'existing_template' }
                               })

        allow(mock_service).to receive(:get_template_status).and_return({ success: true })
        allow(mock_service).to receive(:delete_template)
          .and_return({ success: false, response_body: 'Delete failed' })
        allow(mock_service).to receive(:create_template).and_return({
                                                                      success: true,
                                                                      template_name: "customer_satisfaction_survey_#{whatsapp_inbox.id}",
                                                                      template_id: '333333333'
                                                                    })

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: admin.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'returns unauthorized when agent is not assigned to inbox' do
        other_agent = create(:user, account: account, role: :agent)

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: other_agent.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'allows access when agent is assigned to inbox' do
        allow(mock_service).to receive(:get_template_status).and_return({ success: false })
        allow(mock_service).to receive(:create_template).and_return({
                                                                      success: true,
                                                                      template_name: 'customer_satisfaction_survey',
                                                                      template_id: '444444444'
                                                                    })

        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/csat_template",
             headers: agent.create_new_auth_token,
             params: valid_template_params,
             as: :json

        expect(response).to have_http_status(:created)
      end
    end
  end
end
