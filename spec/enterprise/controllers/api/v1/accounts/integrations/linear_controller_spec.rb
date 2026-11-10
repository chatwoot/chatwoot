require 'rails_helper'

RSpec.describe 'Linear integration custom role authorization', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }

  before do
    create(:integrations_hook, :linear, account: account)
    create(:inbox_member, inbox: conversation.inbox, user: agent)
    agent.account_users.find_by!(account: account).update!(custom_role: custom_role)
  end

  %w[create_issue link_issue unlink_issue linked_issues].each do |action|
    it "denies #{action} when the inbox member's custom role excludes the conversation" do
      expect(Integrations::Linear::ProcessorService).not_to receive(:new)

      expect do
        public_send(action == 'linked_issues' ? :get : :post,
                    "/api/v1/accounts/#{account.id}/integrations/linear/#{action}",
                    params: { conversation_id: conversation.display_id, link_id: 'attachment1', issue_id: 'ENG-123' },
                    headers: agent.create_new_auth_token, as: :json)
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it 'permits an assigned conversation allowed by the custom role' do
    conversation.update!(assignee: agent)
    processor_service = instance_double(Integrations::Linear::ProcessorService)
    link = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/conversations/#{conversation.display_id}"
    allow(Integrations::Linear::ProcessorService).to receive(:new).with(account: account).and_return(processor_service)
    allow(processor_service).to receive(:linked_issues).with(link).and_return(data: [{ 'id' => 'attachment1' }])

    get "/api/v1/accounts/#{account.id}/integrations/linear/linked_issues",
        params: { conversation_id: conversation.display_id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([{ 'id' => 'attachment1' }])
  end
end
