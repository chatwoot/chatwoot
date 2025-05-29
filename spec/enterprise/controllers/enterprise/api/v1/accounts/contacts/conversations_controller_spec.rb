require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/conversations enterprise', type: :request do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/conversations with custom role permissions' do
    context 'with user having custom role' do
      let(:agent_with_custom_role) { create(:user, account: account, role: :agent) }
      let(:custom_role) { create(:custom_role, account: account) }

      before do
        create(:inbox_member, user: agent_with_custom_role, inbox: inbox)
      end

      context 'with conversation_participating_manage permission' do
        let(:assigned_conversation) do
          create(:conversation, account: account, inbox: inbox, contact: contact,
                                contact_inbox: contact_inbox, assignee: agent_with_custom_role)
        end

        before do
          # Create a conversation assigned to this agent
          assigned_conversation

          # Create another conversation that shouldn't be visible
          create(:conversation, account: account, inbox: inbox, contact: contact,
                                contact_inbox: contact_inbox, assignee: create(:user, account: account, role: :agent))

          # Set up permissions
          custom_role.update!(permissions: %w[conversation_participating_manage])

          # Associate the custom role with the agent
          account_user = AccountUser.find_by(user: agent_with_custom_role, account: account)
          account_user.update!(role: :agent, custom_role: custom_role)
        end

        it 'returns only conversations assigned to the agent' do
          get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations",
              headers: agent_with_custom_role.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          # Should only return the conversation assigned to this agent
          expect(json_response['payload'].length).to eq 1
          expect(json_response['payload'][0]['id']).to eq assigned_conversation.display_id
        end
      end

      context 'with conversation_unassigned_manage permission' do
        let(:unassigned_conversation) do
          create(:conversation, account: account, inbox: inbox, contact: contact,
                                contact_inbox: contact_inbox, assignee: nil)
        end

        let(:assigned_conversation) do
          create(:conversation, account: account, inbox: inbox, contact: contact,
                                contact_inbox: contact_inbox, assignee: agent_with_custom_role)
        end

        before do
          # Create the conversations
          unassigned_conversation
          assigned_conversation
          create(:conversation, account: account, inbox: inbox, contact: contact,
                                contact_inbox: contact_inbox, assignee: create(:user, account: account, role: :agent))

          # Set up permissions
          custom_role.update!(permissions: %w[conversation_unassigned_manage])

          # Associate the custom role with the agent
          account_user = AccountUser.find_by(user: agent_with_custom_role, account: account)
          account_user.update!(role: :agent, custom_role: custom_role)
        end

        it 'returns unassigned conversations AND conversations assigned to the agent' do
          get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations",
              headers: agent_with_custom_role.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          # Should return both unassigned and assigned to this agent conversations
          expect(json_response['payload'].length).to eq 2
          conversation_ids = json_response['payload'].pluck('id')
          expect(conversation_ids).to include(unassigned_conversation.display_id)
          expect(conversation_ids).to include(assigned_conversation.display_id)
        end
      end

      context 'with conversation_manage permission' do
        before do
          # Create multiple conversations
          3.times do
            create(:conversation, account: account, inbox: inbox, contact: contact,
                                  contact_inbox: contact_inbox)
          end

          # Set up permissions
          custom_role.update!(permissions: %w[conversation_manage])

          # Associate the custom role with the agent
          account_user = AccountUser.find_by(user: agent_with_custom_role, account: account)
          account_user.update!(role: :agent, custom_role: custom_role)
        end

        it 'returns all conversations' do
          get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations",
              headers: agent_with_custom_role.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          # Should return all conversations in this inbox
          expect(json_response['payload'].length).to eq 3
        end
      end
    end
  end
end
