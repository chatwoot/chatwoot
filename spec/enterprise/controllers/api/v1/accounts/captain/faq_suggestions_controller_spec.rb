require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::FaqSuggestions', type: :request do
  let(:account) { create(:account, locale: 'en') }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:suggestion) do
    assistant.faq_suggestions.create!(
      question: 'How do I enable the feature?',
      answer: 'Turn it on in settings.',
      source_count: 1
    )
  end

  before do
    suggestion.observations.create!(
      conversation: conversation,
      generated_question: suggestion.question,
      generated_answer: suggestion.answer,
      language: suggestion.language
    )
  end

  describe 'GET /api/v1/accounts/:account_id/captain/faq_suggestions' do
    it 'returns suggestions and their count to an administrator' do
      get "/api/v1/accounts/#{account.id}/captain/faq_suggestions",
          params: { assistant_id: assistant.id },
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to contain_exactly(
        include('id' => suggestion.id, 'question' => suggestion.question, 'status' => 'open')
      )
      expect(response.parsed_body['meta']).to include('total_count' => 1)
    end

    it 'returns only suggestions backed by conversations the agent can access' do
      create(:inbox_member, user: agent, inbox: inbox)
      hidden_inbox = create(:inbox, account: account)
      hidden_conversation = create(:conversation, account: account, inbox: hidden_inbox)
      hidden_suggestion = assistant.faq_suggestions.create!(question: 'Hidden question', answer: 'Hidden answer')
      hidden_suggestion.observations.create!(
        conversation: hidden_conversation,
        generated_question: hidden_suggestion.question,
        generated_answer: hidden_suggestion.answer,
        language: hidden_suggestion.language
      )

      get "/api/v1/accounts/#{account.id}/captain/faq_suggestions",
          params: { assistant_id: assistant.id },
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(suggestion.id)
      expect(response.parsed_body['meta']).to include('total_count' => 1)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/faq_suggestions/:id' do
    it 'returns the suggestion with its source conversation' do
      get "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('id' => suggestion.id, 'question' => suggestion.question)
      expect(response.parsed_body['observations']).to contain_exactly(
        include('conversation' => include('id' => conversation.id, 'display_id' => conversation.display_id))
      )
    end

    it 'returns only source conversations the agent can access' do
      create(:inbox_member, user: agent, inbox: inbox)
      hidden_conversation = create(:conversation, account: account, inbox: create(:inbox, account: account))
      suggestion.observations.create!(
        conversation: hidden_conversation,
        generated_question: suggestion.question,
        generated_answer: suggestion.answer,
        language: suggestion.language
      )

      get "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['observations'].pluck('conversation').pluck('id')).to contain_exactly(conversation.id)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/captain/faq_suggestions/:id' do
    it 'lets an administrator edit an open suggestion' do
      patch "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}",
            params: { faq_suggestion: { question: 'Updated question' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['question']).to eq('Updated question')
      expect(suggestion.reload.question).to eq('Updated question')
    end

    it 'lets an agent edit an accessible suggestion' do
      create(:inbox_member, user: agent, inbox: inbox)

      patch "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}",
            params: { faq_suggestion: { question: 'Updated question' } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(suggestion.reload.question).to eq('Updated question')
    end

    it 'does not let an agent edit an inaccessible suggestion' do
      patch "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}",
            params: { faq_suggestion: { question: 'Updated question' } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:not_found)
      expect(suggestion.reload.question).to eq('How do I enable the feature?')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/faq_suggestions/:id/approve' do
    it 'lets an administrator approve an edited suggestion as an FAQ' do
      expect do
        post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/approve",
             params: { faq_suggestion: { answer: 'Enable it in account settings.' } },
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(assistant.responses.approved, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['answer']).to eq('Enable it in account settings.')
      expect(suggestion.reload).to be_approved
      expect(suggestion.observations.pluck(:conversation_id)).to contain_exactly(conversation.id)
    end

    it 'lets an agent approve an accessible suggestion' do
      create(:inbox_member, user: agent, inbox: inbox)

      expect do
        post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/approve",
             headers: agent.create_new_auth_token,
             as: :json
      end.to change(assistant.responses.approved, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(suggestion.reload).to be_approved
    end

    it 'approves a suggestion written in a language other than the account locale' do
      suggestion.update!(language: 'pt')

      expect do
        post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/approve",
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(assistant.responses.approved, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(suggestion.reload).to be_approved
    end

    it 'does not let an agent approve an inaccessible suggestion' do
      expect do
        post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/approve",
             headers: agent.create_new_auth_token,
             as: :json
      end.not_to change(assistant.responses, :count)

      expect(response).to have_http_status(:not_found)
      expect(suggestion.reload).to be_open
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/faq_suggestions/:id/dismiss' do
    it 'lets an administrator dismiss an open suggestion without creating an FAQ' do
      expect do
        post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/dismiss",
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to change(assistant.responses, :count)

      expect(response).to have_http_status(:success)
      expect(suggestion.reload).to be_dismissed
    end

    it 'lets an agent dismiss an accessible suggestion' do
      create(:inbox_member, user: agent, inbox: inbox)

      post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/dismiss",
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(suggestion.reload).to be_dismissed
    end

    it 'does not let an agent dismiss an inaccessible suggestion' do
      post "/api/v1/accounts/#{account.id}/captain/faq_suggestions/#{suggestion.id}/dismiss",
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:not_found)
      expect(suggestion.reload).to be_open
    end
  end
end
