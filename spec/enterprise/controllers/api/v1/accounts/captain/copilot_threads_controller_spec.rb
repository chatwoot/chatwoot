require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::CopilotThreads', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/copilot_threads' do
    context 'when it is an un-authenticated user' do
      it 'does not fetch copilot threads' do
        get "/api/v1/accounts/#{account.id}/captain/copilot_threads",
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'fetches copilot threads for the current user' do
        # Create threads for the current agent
        create_list(:captain_copilot_thread, 3, account: account, user: agent)
        # Create threads for another user (should not be included)
        create_list(:captain_copilot_thread, 2, account: account, user: admin)

        get "/api/v1/accounts/#{account.id}/captain/copilot_threads",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(3)
        expect(json_response[:meta]).to eq(total_count: 3, page: 1)

        expect(json_response[:payload].map { |thread| thread[:user][:id] }.uniq).to eq([agent.id])
      end

      it 'paginates older threads' do
        threads = create_list(:captain_copilot_thread, 21, account: account, user: agent)

        get "/api/v1/accounts/#{account.id}/captain/copilot_threads",
            params: { page: 2 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].pluck(:id)).to eq([threads.first.id])
        expect(json_response[:meta]).to eq(total_count: 21, page: 2)
      end

      it 'returns threads in descending order of creation' do
        threads = create_list(:captain_copilot_thread, 3, account: account, user: agent)

        get "/api/v1/accounts/#{account.id}/captain/copilot_threads",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].pluck(:id)).to eq(threads.reverse.pluck(:id))
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/copilot_threads' do
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:valid_params) { { message: 'Hello, how can you help me?', assistant_id: assistant.id, conversation_id: conversation.display_id } }

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'with invalid params' do
        it 'returns error when message is blank' do
          post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
               params: { message: '', assistant_id: assistant.id },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response[:error]).to eq('Message is required')
        end

        it 'returns error when assistant_id is invalid' do
          post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
               params: { message: 'Hello', assistant_id: 0 },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'with valid params' do
        it 'returns error when usage limit is exceeded' do
          account.limits = { captain_responses: 2 }
          account.custom_attributes = { captain_responses_usage: 2 }
          account.save!

          post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)

          expect(CopilotMessage.last.message['content']).to eq(
            'You are out of Copilot credits. You can buy more credits from the billing section.'
          )
        end

        it 'creates a new copilot thread with initial message' do
          account.limits = { captain_responses: 2 }
          account.custom_attributes = { captain_responses_usage: 0 }
          account.save!

          expect do
            post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
                 params: valid_params,
                 headers: agent.create_new_auth_token,
                 as: :json
          end.to change(CopilotThread, :count).by(1)
             .and change(CopilotMessage, :count).by(1)

          expect(response).to have_http_status(:success)

          thread = CopilotThread.last
          expect(thread.title).to eq(valid_params[:message])
          expect(thread.user_id).to eq(agent.id)
          expect(thread.assistant_id).to eq(assistant.id)

          message = thread.copilot_messages.last
          expect(message.message).to eq({ 'content' => valid_params[:message] })

          expect(Captain::Copilot::ResponseJob).to have_been_enqueued.with(
            assistant: assistant,
            conversation_id: valid_params[:conversation_id],
            user_id: agent.id,
            copilot_thread_id: thread.id,
            message: valid_params[:message]
          )
        end

        it 'truncates the thread title but stores the full message when the message exceeds 255 characters' do
          account.limits = { captain_responses: 2 }
          account.custom_attributes = { captain_responses_usage: 0 }
          account.save!

          long_message = 'a' * 300

          post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
               params: { message: long_message, assistant_id: assistant.id, conversation_id: conversation.display_id },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)

          thread = CopilotThread.last
          expect(thread.title).to eq(long_message.truncate(255, omission: ''))

          message = thread.copilot_messages.last
          expect(message.message).to eq({ 'content' => long_message })
        end

        it 'enqueues the dedicated reply suggestion job' do
          account.limits = { captain_responses: 2 }
          account.custom_attributes = { captain_responses_usage: 0 }
          account.save!
          create(:inbox_member, user: agent, inbox: inbox)

          post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
               params: valid_params.merge(request_type: 'reply_suggestion'),
               headers: agent.create_new_auth_token,
               as: :json

          thread = CopilotThread.last
          expect(Captain::Copilot::ReplySuggestionJob).to have_been_enqueued.with(
            assistant: assistant,
            conversation_id: valid_params[:conversation_id],
            user_id: agent.id,
            copilot_thread_id: thread.id
          )
        end

        it 'rejects an inaccessible reply suggestion before creating its thread' do
          account.limits = { captain_responses: 2 }
          account.custom_attributes = { captain_responses_usage: 0 }
          account.save!

          expect do
            post "/api/v1/accounts/#{account.id}/captain/copilot_threads",
                 params: valid_params.merge(request_type: 'reply_suggestion'),
                 headers: agent.create_new_auth_token,
                 as: :json
          end.not_to change(CopilotThread, :count)

          expect(response).to have_http_status(:not_found)
          expect(CopilotMessage.count).to be_zero
          expect(Captain::Copilot::ReplySuggestionJob).not_to have_been_enqueued
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/copilot_threads/{thread.id}/stop' do
    let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: admin) }
    let(:message) { create(:captain_copilot_message, account: account, copilot_thread: copilot_thread) }
    let(:turn) do
      CopilotRun::Turn.create!(account: account, user: admin, copilot_thread: copilot_thread, copilot_message: message,
                               status: :awaiting_background_run)
    end
    let(:conversations) { create_list(:conversation, 3, account: account, inbox: inbox) }
    let(:collection) do
      CopilotRun::Collection.create!(account: account, user: admin, copilot_thread: copilot_thread, status: :completed,
                                     context: { resource: 'conversations', selected_ids: conversations.map(&:id), filters: {},
                                                as_of: 1.minute.from_now.iso8601 })
    end
    let(:stop_path) { "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{copilot_thread.id}/stop" }

    it 'ends the turn and its review, keeps the conversations already reviewed, and saves nothing that finishes later' do
      review = CopilotRun::Review.create!(
        account: account, user: admin, copilot_thread: copilot_thread, source_run: collection, status: :reviewing,
        copilot_tool_call: turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations'),
        context: { request: 'Which ones ask about billing?', criteria: 'Asks about billing', turn_start: 0, turn_limit: 10,
                   turn_start_matched: 0, turn_start_failed: 0, pending_ids: conversations.drop(1).map(&:id) }
      )
      review.findings.create!(conversation_id: conversations.first.id, status: :reviewed, matched: true)
      allow(Captain::Copilot::ReviewService).to receive(:new)

      post stop_path, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(turn.reload).to be_incomplete
      expect(review.reload).to have_attributes(status: 'incomplete', error: I18n.t('captain.copilot.stopped'))
      expect(copilot_thread.copilot_messages.order(:id).last).to have_attributes(
        message_type: 'assistant', message: { 'run_id' => turn.id, 'content' => I18n.t('captain.copilot.stopped_message') }
      )

      Captain::Copilot::ReviewConversationJob.perform_now(review.id, conversations.second.id)
      expect(Captain::Copilot::ReviewService).not_to have_received(:new)
      expect(review.findings.pluck(:conversation_id)).to eq([conversations.first.id])
    end

    it 'rejects a change still awaiting approval, so approving its card later changes nothing' do
      card = copilot_thread.copilot_messages.create!(message_type: :assistant_approval,
                                                     message: { approval: { status: 'awaiting_approval', count: 1 } })
      action = CopilotRun::Action.create!(
        account: account, user: admin, copilot_thread: copilot_thread, status: :awaiting_approval,
        copilot_tool_call: turn.tool_calls.create!(call_id: 'act-1', name: 'act'),
        context: { action: 'add_labels', arguments: { labels: ['billing'] }, target_ids: [conversations.first.id],
                   approval_message_id: card.id }
      )

      post stop_path, headers: admin.create_new_auth_token, as: :json

      expect(action.reload).to be_rejected
      expect(action.approve).to be(false)
      expect(card.reload.message.dig('approval', 'status')).to eq('rejected')
    end

    it 'does not stop another agent\'s thread' do
      turn

      post stop_path, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
      expect(turn.reload).to be_awaiting_background_run
    end
  end
end
