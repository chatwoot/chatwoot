require 'rails_helper'

RSpec.describe 'Captain task conversation access', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:params) { { conversation_display_id: conversation.display_id, content: 'Draft', operation: 'improve' } }

  {
    summarize: Captain::SummaryService,
    reply_suggestion: Captain::ReplySuggestionService,
    rewrite: Captain::RewriteService,
    follow_up: Captain::FollowUpService
  }.each do |action, service_class|
    context "when calling #{action}" do
      let(:service) { instance_double(service_class, perform: { message: 'Allowed result' }) }

      it 'rejects a hidden conversation before invoking Captain' do
        expect(service_class).not_to receive(:new)
        post "/api/v1/accounts/#{account.id}/captain/tasks/#{action}", params: params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'allows an inbox member' do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
        expect(service_class).to receive(:new).and_return(service)
        post "/api/v1/accounts/#{account.id}/captain/tasks/#{action}", params: params, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to eq('Allowed result')
      end

      it 'allows an administrator without inbox membership' do
        admin = create(:user, account: account, role: :administrator)
        expect(service_class).to receive(:new).and_return(service)
        post "/api/v1/accounts/#{account.id}/captain/tasks/#{action}", params: params, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'rejects a conversation in another account' do
        foreign_conversation = create(:conversation)
        foreign_conversation.update!(display_id: conversation.display_id + 1)
        expect(service_class).not_to receive(:new)
        post "/api/v1/accounts/#{account.id}/captain/tasks/#{action}",
             params: params.merge(conversation_display_id: foreign_conversation.display_id), headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  it 'allows a team member to summarize without inbox membership' do
    team = create(:team, account: account)
    create(:team_member, team: team, user: agent)
    conversation.update!(team: team)
    service = instance_double(Captain::SummaryService, perform: { message: 'Allowed result' })
    expect(Captain::SummaryService).to receive(:new).and_return(service)
    post "/api/v1/accounts/#{account.id}/captain/tasks/summarize", params: params, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
  end

  { rewrite: Captain::RewriteService, follow_up: Captain::FollowUpService }.each do |action, service_class|
    it "allows #{action} without an optional conversation" do
      service = instance_double(service_class, perform: { message: 'Allowed result' })
      expect(service_class).to receive(:new).and_return(service)
      post "/api/v1/accounts/#{account.id}/captain/tasks/#{action}",
           params: { content: 'Draft', operation: 'professional' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
