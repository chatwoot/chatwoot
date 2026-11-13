require 'rails_helper'

RSpec.describe 'Enterprise Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/:id' do
    let(:conversation) { create(:conversation, account: account) }
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:params) { { sla_policy_id: sla_policy.id } }

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        account.enable_features!('sla')
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'updates the conversation if you are an agent with access to inbox' do
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:sla_policy_id]).to eq(sla_policy.id)
      end

      it 'throws error if conversation already has a different sla' do
        conversation.update(sla_policy: create(:sla_policy, account: account))
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body, symbolize_names: true)[:message]).to eq('Sla policy conversation already has a different sla')
      end

      it 'throws error if conversation contact is blocked' do
        conversation.contact.update!(blocked: true)

        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body, symbolize_names: true)[:message])
          .to eq('Sla policy cannot be assigned to conversations with blocked contacts')
      end
    end

    context 'when the sla feature is disabled' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:existing_sla_policy) { create(:sla_policy, account: account) }

      before do
        account.enable_features!('sla')
        conversation.update!(sla_policy: existing_sla_policy)
        account.disable_features!('sla')
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'ignores the sla assignment and keeps the existing policy' do
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.sla_policy_id).to eq(existing_sla_policy.id)
      end
    end

    context 'when an agent switches auto translate for the conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:conversation) { create(:conversation, account: account, additional_attributes: { 'conversation_language' => 'tr' }) }
      let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}" }

      before do
        account.enable_features!(:auto_translate, :captain_tasks)
        account.update!(auto_translate: true)
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'turns it off and keeps the detected language' do
        patch url, params: { auto_translate_disabled: true }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['additional_attributes']).to eq('conversation_language' => 'tr', 'auto_translate_disabled' => true)
        expect(conversation.reload.auto_translate_enabled?).to be(false)
      end

      it 'turns it back on' do
        conversation.update!(auto_translate_disabled: true)

        patch url, params: { auto_translate_disabled: false }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.auto_translate_enabled?).to be(true)
      end

      it 'rejects a value that is not true or false' do
        patch url, params: { auto_translate_disabled: 'yes' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(conversation.reload.additional_attributes).not_to have_key('auto_translate_disabled')
      end

      it 'ignores the switch while auto translate is off for the account' do
        account.update!(auto_translate: false)

        patch url, params: { auto_translate_disabled: true }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.additional_attributes).not_to have_key('auto_translate_disabled')
      end
    end
  end
end
