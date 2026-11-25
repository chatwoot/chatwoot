require 'rails_helper'

RSpec.describe 'Internal Chat Polls API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }

  describe 'POST /api/v1/accounts/:account_id/internal_chat/polls' do
    let(:valid_params) do
      {
        channel_id: channel.id,
        question: 'What is your favorite color?',
        options: [
          { text: 'Red' },
          { text: 'Blue' },
          { text: 'Green' }
        ]
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when polls are disabled' do
      before { allow(InternalChat::Limits).to receive(:polls_enabled?).and_return(false) }

      it 'returns payment_required' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:payment_required)
        body = response.parsed_body
        expect(body['error']).to eq('pro_feature_required')
        expect(body['feature']).to eq('polls')
      end
    end

    context 'when it is an authenticated agent' do
      before { allow(InternalChat::Limits).to receive(:polls_enabled?).and_return(true) }

      it 'creates a poll with options' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['content']).to eq('What is your favorite color?')
        expect(body['content_type']).to eq('poll')
        expect(body['content_attributes']['poll']).to be_present
        expect(body['content_attributes']['poll']['question']).to eq('What is your favorite color?')
        expect(body['content_attributes']['poll']['options'].length).to eq(3)
      end

      it 'includes poll metadata in the response' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params.merge(multiple_choice: true, public_results: false),
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        poll = body['content_attributes']['poll']
        expect(poll['multiple_choice']).to be true
        expect(poll['public_results']).to be false
      end

      it 'returns unauthorized for a private channel the agent is not a member of' do
        private_channel = create(:internal_chat_channel, :private_channel, account: account, name: 'secret')

        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params.merge(channel_id: private_channel.id),
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a poll with expiration date' do
        expiry = 1.day.from_now.iso8601

        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params.merge(expires_at: expiry),
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['content_attributes']['poll']['expires_at']).to be_present
      end

      it 'creates a poll with allow_revote disabled' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params.merge(allow_revote: false),
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['content_attributes']['poll']['allow_revote']).to be false
      end

      it 'returns bad request when options are missing' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls",
             params: valid_params.except(:options),
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'creates the poll record in the database' do
        expect do
          post "/api/v1/accounts/#{account.id}/internal_chat/polls",
               params: valid_params,
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(InternalChat::Poll, :count).by(1)
                                                 .and change(InternalChat::PollOption, :count).by(3)
                                                                                              .and change(InternalChat::Message, :count).by(1)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/polls/:id/vote' do
    let(:poll) { create(:internal_chat_poll, message: create(:internal_chat_message, :poll, account: account, channel: channel, sender: agent)) }
    let(:option) { create(:internal_chat_poll_option, poll: poll, position: 0) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option.id }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'creates a vote successfully' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['content_attributes']['poll']['options'].first['voted']).to be true
        expect(body['content_attributes']['poll']['total_votes']).to eq(1)
      end

      it 'returns bad request for an expired poll' do
        poll.update!(expires_at: 1.hour.ago)

        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns bad request when revoting is not allowed' do
        poll.update!(allow_revote: false)
        create(:internal_chat_poll_vote, option: option, user: agent)

        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'replaces previous vote when revoting is allowed on single-choice poll' do
        poll.update!(allow_revote: true, multiple_choice: false)
        option2 = create(:internal_chat_poll_option, poll: poll, position: 1)
        create(:internal_chat_poll_vote, option: option, user: agent)

        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option2.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(InternalChat::PollVote.where(user: agent).count).to eq(1)
        expect(InternalChat::PollVote.find_by(user: agent).option).to eq(option2)
      end

      it 'allows adding votes on multiple-choice poll' do
        poll.update!(multiple_choice: true)
        option2 = create(:internal_chat_poll_option, poll: poll, position: 1)
        create(:internal_chat_poll_vote, option: option, user: agent)

        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option2.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(InternalChat::PollVote.where(user: agent).count).to eq(2)
      end

      it 'returns bad request when voting on the same option twice in a multiple-choice poll' do
        poll.update!(multiple_choice: true, allow_revote: true)
        create(:internal_chat_poll_vote, option: option, user: agent)

        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:bad_request)
        expect(InternalChat::PollVote.where(user: agent, internal_chat_poll_option_id: option.id).count).to eq(1)
      end

      it 'includes poll response structure with total_votes and options' do
        post "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
             params: { option_id: option.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to have_key('content_attributes')
        poll_data = body['content_attributes']['poll']
        expect(poll_data).to have_key('total_votes')
        expect(poll_data).to have_key('options')
        expect(poll_data).to have_key('question')
        expect(poll_data).to have_key('multiple_choice')
        expect(poll_data).to have_key('allow_revote')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/internal_chat/polls/:id/vote' do
    let(:poll) { create(:internal_chat_poll, message: create(:internal_chat_message, :poll, account: account, channel: channel, sender: agent)) }
    let(:option) { create(:internal_chat_poll_option, poll: poll, position: 0) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'removes a vote successfully' do
        create(:internal_chat_poll_vote, option: option, user: agent)

        delete "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
        expect(InternalChat::PollVote.where(user: agent).count).to eq(0)
      end

      it 'returns not found when there is no existing vote' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns bad request when unvoting on an expired poll' do
        create(:internal_chat_poll_vote, option: option, user: agent)
        poll.update!(expires_at: 1.hour.ago)

        delete "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'removes a specific option vote when option_id is provided' do
        option2 = create(:internal_chat_poll_option, poll: poll, position: 1)
        poll.update!(multiple_choice: true)
        create(:internal_chat_poll_vote, option: option, user: agent)
        create(:internal_chat_poll_vote, option: option2, user: agent)

        delete "/api/v1/accounts/#{account.id}/internal_chat/polls/#{poll.id}/vote",
               params: { option_id: option.id },
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
        expect(InternalChat::PollVote.where(user: agent).count).to eq(1)
        expect(InternalChat::PollVote.find_by(user: agent).option).to eq(option2)
      end
    end
  end
end
