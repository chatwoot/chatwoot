require 'rails_helper'

RSpec.describe 'Pathors Calls API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  let(:create_payload) do
    {
      conversation_id: conversation.display_id,
      provider_call_id: 'pathors-call-1',
      direction: 'inbound',
      from_number: '+886912345678',
      to_number: '+886222222222',
      started_at: '2026-08-05T10:00:00Z'
    }
  end

  describe 'POST /api/v1/accounts/{account.id}/pathors/calls' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/pathors/calls", params: create_payload, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'creates a pathors call and a voice_call message' do
        expect do
          post "/api/v1/accounts/#{account.id}/pathors/calls",
               params: create_payload, headers: admin.create_new_auth_token, as: :json
        end.to change(Call, :count).by(1)

        expect(response).to have_http_status(:success)

        call = Call.last
        expect(call.provider).to eq('pathors')
        expect(call.direction).to eq('incoming')
        expect(call.status).to eq('in_progress')
        expect(call.from_number).to eq('+886912345678')
        expect(call.message).to be_present
      end

      it 'creates an incoming voice_call message for an inbound call' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: admin.create_new_auth_token, as: :json

        message = Call.last.message
        expect(message.content_type).to eq('voice_call')
        expect(message.message_type).to eq('incoming')
        expect(message.conversation_id).to eq(conversation.id)
      end

      it 'creates an outgoing voice_call message for an outbound call' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload.merge(direction: 'outbound'),
             headers: admin.create_new_auth_token, as: :json

        call = Call.last
        expect(call.direction).to eq('outgoing')
        expect(call.message.message_type).to eq('outgoing')
      end

      it 'responds with the push event payload plus the message id' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: admin.create_new_auth_token, as: :json

        call = Call.last
        body = response.parsed_body
        expect(body['id']).to eq(call.id)
        expect(body['status']).to eq('in-progress')
        expect(body['direction']).to eq('incoming')
        expect(body['accepted_by_agent_name']).to eq('Pathors AI')
        expect(body['message_id']).to eq(call.message_id)
      end

      it 'is idempotent for a repeated provider_call_id' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: admin.create_new_auth_token, as: :json
        first_id = response.parsed_body['id']

        expect do
          post "/api/v1/accounts/#{account.id}/pathors/calls",
               params: create_payload, headers: admin.create_new_auth_token, as: :json
        end.not_to change(Call, :count)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(first_id)
      end

      it 'rejects an unknown direction' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload.merge(direction: 'sideways'),
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found for a conversation outside the account' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload.merge(conversation_id: conversation.display_id + 9999),
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pathors/calls/{id}' do
    let(:message) do
      create(:message, account: account, conversation: conversation, inbox: conversation.inbox, content_type: 'voice_call')
    end
    let(:call) do
      create(:call, :pathors, account: account, conversation: conversation, inbox: conversation.inbox,
                              contact: conversation.contact, message: message)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}", params: { status: 'completed' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'completed' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'updates the status, duration and end reason' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'completed', duration_seconds: 42, end_reason: 'hangup', ended_at: '2026-08-05T10:05:00Z' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        call.reload
        expect(call.status).to eq('completed')
        expect(call.duration_seconds).to eq(42)
        expect(call.end_reason).to eq('hangup')
        expect(call.ended_at).to eq(Time.zone.parse('2026-08-05T10:05:00Z').iso8601)
      end

      it 'touches the linked message so the dashboard re-renders' do
        original = message.updated_at

        travel_to(2.minutes.from_now) do
          patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
                params: { status: 'completed' }, headers: admin.create_new_auth_token, as: :json
        end

        expect(message.reload.updated_at).to be > original
      end

      it 'responds with the display status' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'no_answer' }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['status']).to eq('no-answer')
      end

      it 'accepts the dashed display status on the way in' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'in-progress' }, headers: admin.create_new_auth_token, as: :json

        expect(call.reload.status).to eq('in_progress')
      end

      it 'ignores a transition out of a terminal status' do
        call.update!(status: 'completed')

        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'in_progress', duration_seconds: 99 }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        call.reload
        expect(call.status).to eq('completed')
        expect(call.duration_seconds).to be_nil
        expect(response.parsed_body['status']).to eq('completed')
      end

      it 'allows a terminal to terminal correction' do
        call.update!(status: 'completed')

        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'failed' }, headers: admin.create_new_auth_token, as: :json

        expect(call.reload.status).to eq('failed')
      end

      it 'returns not found for a call outside the account' do
        other_call = create(:call, :pathors)

        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{other_call.id}",
              params: { status: 'completed' }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/pathors/calls/{id}/join' do
    let(:join_url) { 'https://api.pathors.example/project/proj_42/integration/chatwoot/voice/join' }
    let(:message) do
      create(:message, account: account, conversation: conversation, inbox: conversation.inbox, content_type: 'voice_call')
    end
    let(:call) do
      create(:call, :pathors, account: account, conversation: conversation, inbox: conversation.inbox,
                              contact: conversation.contact, message: message, status: 'ringing')
    end
    let!(:agent_bot) do
      create(:agent_bot, account: account,
                         outgoing_url: 'https://api.pathors.example/project/proj_42/integration/chatwoot/callback')
    end
    let(:join_response) do
      {
        token: 'lk-token', serverUrl: 'wss://livekit.example', roomName: 'room-1',
        participantIdentity: "chatwoot-human-#{agent.id}", yieldDelivered: true
      }
    end

    def stub_join(status: 200, body: nil)
      stub_request(:post, join_url).to_return(
        status: status,
        body: (body || join_response).to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    before do
      create(:inbox_member, user: agent, inbox: conversation.inbox)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the agent has no access to the conversation' do
      let(:outsider) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: outsider.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent with conversation access' do
      it 'relays the pathors join payload' do
        stub_join

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['token']).to eq('lk-token')
        expect(response.parsed_body['serverUrl']).to eq('wss://livekit.example')
      end

      it 'signs the exact raw request body with the agent bot secret' do
        stub_join

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expected_body = {
          sessionId: call.provider_call_id,
          conversationId: conversation.display_id,
          agent: { id: agent.id, name: agent.available_name }
        }.to_json
        expected_signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', agent_bot.secret, expected_body)}"

        expect(
          a_request(:post, join_url).with(body: expected_body, headers: { 'X-Pathors-Signature' => expected_signature })
        ).to have_been_made.once
      end

      it 'records the answering agent and touches the message' do
        stub_join
        original = message.updated_at

        travel_to(2.minutes.from_now) do
          post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
               headers: agent.create_new_auth_token, as: :json
        end

        expect(call.reload.accepted_by_agent_id).to eq(agent.id)
        expect(message.reload.updated_at).to be > original
      end

      it 'assigns the conversation to the joining agent when unassigned' do
        stub_join

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(conversation.reload.assignee_id).to eq(agent.id)
      end

      it 'leaves an existing assignee untouched' do
        other_agent = create(:user, account: account, role: :agent)
        create(:inbox_member, user: other_agent, inbox: conversation.inbox)
        conversation.update!(assignee: other_agent)
        stub_join

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(conversation.reload.assignee_id).to eq(other_agent.id)
      end

      it 'relays a 409 already_claimed verbatim' do
        stub_join(status: 409, body: { error: 'already_claimed' })

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['error']).to eq('already_claimed')
        expect(call.reload.accepted_by_agent_id).to be_nil
      end

      it 'relays a 404 call_not_found verbatim' do
        stub_join(status: 404, body: { error: 'call_not_found' })

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('call_not_found')
      end

      it 'reports a rejected signature as a server error' do
        stub_join(status: 401, body: { error: 'invalid_signature' })

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body['error']).to eq('pathors_auth_failed')
      end

      it 'reports an unreachable backend as a bad gateway' do
        stub_request(:post, join_url).to_timeout

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body['error']).to eq('pathors_unreachable')
      end

      it 'returns gone for a terminal call without contacting pathors' do
        stub_join
        call.update!(status: 'completed')

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:gone)
        expect(response.parsed_body['error']).to eq('call_ended')
        expect(a_request(:post, join_url)).not_to have_been_made
      end

      it 'returns not found for a non-pathors call without contacting pathors' do
        stub_join
        twilio_call = create(:call, account: account, conversation: conversation, inbox: conversation.inbox,
                                    contact: conversation.contact)

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{twilio_call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
        expect(a_request(:post, join_url)).not_to have_been_made
      end

      it 'returns unprocessable entity when no pathors agent bot is configured' do
        agent_bot.update!(outgoing_url: 'https://example.com/other')

        post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('pathors_not_configured')
      end

      context 'when the account holds bots for more than one pathors project' do
        let(:inbox_join_url) { 'https://api.pathors.example/project/proj_99/integration/chatwoot/voice/join' }
        let(:inbox_bot) do
          create(:agent_bot, account: account,
                             outgoing_url: 'https://api.pathors.example/project/proj_99/integration/chatwoot/callback')
        end

        before do
          stub_request(:post, inbox_join_url).to_return(
            status: 200, body: join_response.to_json, headers: { 'Content-Type' => 'application/json' }
          )
          stub_join
        end

        it 'signs with the bot bound to the call inbox rather than another project bot' do
          create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: inbox_bot)

          post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
               headers: agent.create_new_auth_token, as: :json

          expected_body = {
            sessionId: call.provider_call_id,
            conversationId: conversation.display_id,
            agent: { id: agent.id, name: agent.available_name }
          }.to_json
          expected_signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', inbox_bot.secret, expected_body)}"

          expect(response).to have_http_status(:success)
          expect(
            a_request(:post, inbox_join_url).with(body: expected_body, headers: { 'X-Pathors-Signature' => expected_signature })
          ).to have_been_made.once
          expect(a_request(:post, join_url)).not_to have_been_made
        end

        it 'falls back to the account bot when the inbox has no bot bound' do
          inbox_bot

          post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
               headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:success)
          expect(a_request(:post, join_url)).to have_been_made.once
          expect(a_request(:post, inbox_join_url)).not_to have_been_made
        end

        it 'falls back to the account bot when the inbox is bound to a non-pathors bot' do
          other_bot = create(:agent_bot, account: account, outgoing_url: 'https://example.com/hooks/other')
          create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: other_bot)

          post "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}/join",
               headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:success)
          expect(a_request(:post, join_url)).to have_been_made.once
        end
      end
    end
  end
end
