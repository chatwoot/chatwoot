require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::MessageReports', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:message) do
    create(:message, account: account, conversation: conversation, message_type: :outgoing, sender: assistant)
  end

  before { create(:inbox_member, user: agent, inbox: inbox) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'POST /api/v1/accounts/:account_id/captain/message_reports' do
    let(:valid_params) do
      {
        message_id: message.id,
        report_reason: 'incorrect_information',
        description: 'The generated citation is wrong.'
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/captain/message_reports", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the installation is not on Chatwoot cloud' do
      before { InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_initialize.update!(value: 'self_hosted') }

      it 'returns not found' do
        post "/api/v1/accounts/#{account.id}/captain/message_reports",
             params: valid_params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'does not create a report' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/message_reports",
               params: valid_params, headers: agent.create_new_auth_token, as: :json
        end.not_to change(Captain::MessageReport, :count)
      end
    end

    context 'when on Chatwoot cloud' do
      before { InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_initialize.update!(value: 'cloud') }

      it 'creates a message report for the reporting agent' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/message_reports",
               params: valid_params, headers: agent.create_new_auth_token, as: :json
        end.to change(Captain::MessageReport, :count).by(1)

        report = Captain::MessageReport.last
        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(report.message_id).to eq(message.id)
          expect(report.conversation_id).to eq(conversation.id)
          expect(report.user_id).to eq(agent.id)
          expect(report.report_reason).to eq('incorrect_information')
          expect(report.description).to eq('The generated citation is wrong.')
          expect(json_response[:report_reason]).to eq('incorrect_information')
        end
      end

      it 'returns not found when the message does not belong to the account' do
        other_message = create(:message)

        post "/api/v1/accounts/#{account.id}/captain/message_reports",
             params: valid_params.merge(message_id: other_message.id),
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns unprocessable entity for an invalid report reason' do
        post "/api/v1/accounts/#{account.id}/captain/message_reports",
             params: valid_params.merge(report_reason: 'invalid_reason'),
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not allow an agent without access to the conversation to report' do
        other_agent = create(:user, account: account, role: :agent)

        expect do
          post "/api/v1/accounts/#{account.id}/captain/message_reports",
               params: valid_params, headers: other_agent.create_new_auth_token, as: :json
        end.not_to change(Captain::MessageReport, :count)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects messages that were not sent by a Captain assistant' do
        non_captain_message = create(:message, account: account, conversation: conversation)

        expect do
          post "/api/v1/accounts/#{account.id}/captain/message_reports",
               params: valid_params.merge(message_id: non_captain_message.id),
               headers: agent.create_new_auth_token, as: :json
        end.not_to change(Captain::MessageReport, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
