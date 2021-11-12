require 'rails_helper'

RSpec.describe 'Conversation Assignment API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/assignments' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to the inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:team) { create(:team, account: account) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'assigns a user to the conversation' do
        params = { assignee_id: agent.id }

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'assigns a team to the conversation' do
        params = { team_id: team.id }

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to eq(team)
      end
    end

    context 'when conversation already has an assignee' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation.update!(assignee: agent)
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'unassigns the assignee from the conversation' do
        params = { assignee_id: 0 }
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(nil)
        expect(Conversations::ActivityMessageJob)
          .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "Conversation unassigned by #{agent.name}" }))
      end
    end

    context 'when conversation already has a team' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:team) { create(:team, account: account) }

      before do
        conversation.update!(team: team)
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'unassigns the team from the conversation' do
        params = { team_id: 0 }
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to eq(nil)
      end
    end
  end
end
