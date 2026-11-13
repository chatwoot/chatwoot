require 'rails_helper'

RSpec.describe 'Captain task custom role access', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }

  before do
    create(:inbox_member, inbox: conversation.inbox, user: agent)
    agent.account_users.find_by!(account: account).update!(custom_role: custom_role)
  end

  %w[summarize reply_suggestion rewrite follow_up].each do |action|
    it "rejects #{action} when the custom role excludes the conversation" do
      post "/api/v1/accounts/#{account.id}/captain/tasks/#{action}",
           params: { conversation_display_id: conversation.display_id, content: 'Draft', operation: 'improve' },
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it 'allows a conversation assigned to the agent' do
    conversation.update!(assignee: agent)
    service = instance_double(Captain::SummaryService, perform: { message: 'Allowed result' })
    expect(Captain::SummaryService).to receive(:new).and_return(service)
    post "/api/v1/accounts/#{account.id}/captain/tasks/summarize",
         params: { conversation_display_id: conversation.display_id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
  end
end
