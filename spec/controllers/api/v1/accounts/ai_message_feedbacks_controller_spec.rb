require 'rails_helper'

RSpec.describe 'AI Message Feedbacks API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: conversation.inbox)
    create(:inbox_member, user: admin, inbox: conversation.inbox)
  end

  describe 'POST /api/v1/accounts/{account.id}/ai_message_feedbacks' do
    let(:valid_feedback_params) do
      {
        message_id: message.id,
        ai_feedback: {
          rating: 'positive',
          feedback_text: 'This AI response was very helpful and accurate.'
        }
      }
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
             params: valid_feedback_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      context 'with valid parameters' do
        it 'creates feedback successfully' do
          post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
               headers: agent.create_new_auth_token,
               params: valid_feedback_params,
               as: :json

          expect(response).to have_http_status(:success)

          message.reload
          ai_feedback = message.content_attributes['ai_feedback']

          expect(ai_feedback).to be_present
          expect(ai_feedback['rating']).to eq('positive')
          expect(ai_feedback['feedback_text']).to eq('This AI response was very helpful and accurate.')
          expect(ai_feedback['agent_id']).to eq(agent.id)
          expect(ai_feedback['created_at']).to be_present
        end

        it 'returns the updated message in response' do
          post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
               headers: agent.create_new_auth_token,
               params: valid_feedback_params,
               as: :json

          expect(response).to have_http_status(:success)

          body = JSON.parse(response.body)
          expect(body['id']).to eq(message.id)
          expect(body['content_attributes']['ai_feedback']).to be_present
        end
      end

      context 'with invalid parameters' do
        it 'handles missing rating' do
          invalid_params = valid_feedback_params.deep_dup
          invalid_params[:ai_feedback].delete(:rating)

          post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
               headers: agent.create_new_auth_token,
               params: invalid_params,
               as: :json

          expect(response).to have_http_status(:success) # Still creates with nil rating

          message.reload
          ai_feedback = message.content_attributes['ai_feedback']
          expect(ai_feedback['rating']).to be_nil
        end

        it 'handles missing feedback_text' do
          invalid_params = valid_feedback_params.deep_dup
          invalid_params[:ai_feedback].delete(:feedback_text)

          post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
               headers: agent.create_new_auth_token,
               params: invalid_params,
               as: :json

          expect(response).to have_http_status(:success) # Still creates with nil feedback_text

          message.reload
          ai_feedback = message.content_attributes['ai_feedback']
          expect(ai_feedback['feedback_text']).to be_nil
        end
      end

      context 'when message does not exist' do
        it 'returns not found' do
          invalid_params = valid_feedback_params.dup
          invalid_params[:message_id] = 999_999

          post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
               headers: agent.create_new_auth_token,
               params: invalid_params,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when user does not have access to message' do
        let(:other_account) { create(:account) }
        let(:other_message) { create(:message, account: other_account) }

        it 'returns not found' do
          invalid_params = valid_feedback_params.dup
          invalid_params[:message_id] = other_message.id

          post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
               headers: agent.create_new_auth_token,
               params: invalid_params,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/ai_message_feedbacks' do
    let(:existing_feedback) do
      {
        'rating' => 'positive',
        'feedback_text' => 'Original feedback',
        'agent_id' => agent.id,
        'created_at' => 1.hour.ago.utc.iso8601
      }
    end

    let(:update_params) do
      {
        message_id: message.id,
        ai_feedback: {
          rating: 'negative',
          feedback_text: 'Updated feedback - this was not helpful'
        }
      }
    end

    before do
      message.content_attributes = message.content_attributes.merge('ai_feedback' => existing_feedback)
      message.save!
    end

    context 'when user is authenticated and authorized' do
      it 'updates existing feedback successfully' do
        patch "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message.id}",
              headers: agent.create_new_auth_token,
              params: { ai_feedback: update_params[:ai_feedback] },
              as: :json

        expect(response).to have_http_status(:success)

        message.reload
        ai_feedback = message.content_attributes['ai_feedback']

        expect(ai_feedback['rating']).to eq('negative')
        expect(ai_feedback['feedback_text']).to eq('Updated feedback - this was not helpful')
        expect(ai_feedback['agent_id']).to eq(agent.id) # Unchanged
        expect(ai_feedback['created_at']).to eq(existing_feedback['created_at']) # Unchanged
        expect(ai_feedback['updated_at']).to be_present
      end

      it 'allows admin to update any feedback' do
        patch "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message.id}",
              headers: admin.create_new_auth_token,
              params: { ai_feedback: update_params[:ai_feedback] },
              as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context 'when feedback does not exist' do
      let(:message_without_feedback) { create(:message, conversation: conversation, account: account) }

      it 'returns not found' do
        patch "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message_without_feedback.id}",
              headers: agent.create_new_auth_token,
              params: { ai_feedback: update_params[:ai_feedback] },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not the original feedback author' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: other_agent, inbox: conversation.inbox)
      end

      it 'returns unauthorized for regular agent' do
        patch "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message.id}",
              headers: other_agent.create_new_auth_token,
              params: { ai_feedback: update_params[:ai_feedback] },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/ai_message_feedbacks/{message_id}' do
    let(:existing_feedback) do
      {
        'rating' => 'positive',
        'feedback_text' => 'Original feedback',
        'agent_id' => agent.id,
        'created_at' => 1.hour.ago.utc.iso8601
      }
    end

    before do
      message.content_attributes = message.content_attributes.merge('ai_feedback' => existing_feedback)
      message.save!
    end

    context 'when user is authenticated and authorized' do
      it 'deletes feedback successfully' do
        delete "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)

        message.reload
        expect(message.content_attributes['ai_feedback']).to be_nil
      end

      it 'allows admin to delete any feedback' do
        delete "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when feedback does not exist' do
      let(:message_without_feedback) { create(:message, conversation: conversation, account: account) }

      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message_without_feedback.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not the original feedback author' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: other_agent, inbox: conversation.inbox)
      end

      it 'returns unauthorized for regular agent' do
        delete "/api/v1/accounts/#{account.id}/ai_message_feedbacks/#{message.id}",
               headers: other_agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'authorization edge cases' do
    context 'when agent does not have inbox access' do
      let(:other_inbox) { create(:inbox, account: account) }
      let(:other_conversation) { create(:conversation, account: account, inbox: other_inbox) }
      let(:other_message) { create(:message, conversation: other_conversation, account: account) }

      it 'prevents feedback creation for inaccessible message' do
        post "/api/v1/accounts/#{account.id}/ai_message_feedbacks",
             headers: agent.create_new_auth_token,
             params: {
               message_id: other_message.id,
               ai_feedback: { rating: 'positive', feedback_text: 'Test' }
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end