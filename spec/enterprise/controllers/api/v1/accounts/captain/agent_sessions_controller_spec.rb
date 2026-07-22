require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::AgentSessions', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:message) do
    create(:message, account: account, conversation: conversation, message_type: :outgoing, sender: assistant)
  end

  before { create(:inbox_member, user: agent, inbox: inbox) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/:account_id/captain/agent_sessions/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/captain/agent_sessions/#{message.id}", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the message has an agent session' do
      let(:document) { create(:captain_document, account: account, assistant: assistant) }
      let(:documented_faq) do
        create(:captain_assistant_response, account: account, assistant: assistant,
                                            question: 'How do I reset my password?', documentable: document)
      end
      let(:plain_faq) do
        create(:captain_assistant_response, account: account, assistant: assistant, question: 'How do I change my email?')
      end
      let(:pdf_document) do
        create(:captain_document, account: account, assistant: assistant, external_link: nil,
                                  pdf_file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.pdf'), 'application/pdf'))
      end
      let(:pdf_faq) do
        create(:captain_assistant_response, account: account, assistant: assistant,
                                            question: 'What are the pricing tiers?', documentable: pdf_document)
      end
      let(:scenario) { create(:captain_scenario, account: account, assistant: assistant, title: 'Refund flow') }
      let(:run_context) do
        [
          { 'role' => 'user', 'content' => 'I want a refund' },
          { 'role' => 'assistant', 'content' => '', 'agent_name' => 'Assistant',
            'tool_calls' => [{ 'id' => 'call_1', 'name' => 'faq_lookup', 'arguments' => { 'query' => 'refund' } }] },
          { 'role' => 'tool', 'content' => 'Refunds take 5 days', 'tool_call_id' => 'call_1' },
          { 'role' => 'assistant', 'content' => 'Refunds take 5 days', 'agent_name' => "scenario_#{scenario.id}_refund_flow" }
        ]
      end
      let!(:agent_session) do
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: conversation, result: message,
                                       llm_model: 'openai-gpt-5.2', credits_consumed: 1.0,
                                       faq_ids: [documented_faq.id, plain_faq.id, pdf_faq.id, documented_faq.id + 100_000],
                                       scenario_ids: [scenario.id],
                                       run_context: run_context)
      end

      it 'returns the session with hydrated citations and scenarios' do
        get "/api/v1/accounts/#{account.id}/captain/agent_sessions/#{message.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        aggregate_failures do
          expect(json_response[:id]).to eq(agent_session.id)
          expect(json_response[:message_id]).to eq(message.id)
          expect(json_response[:llm_model]).to eq('openai-gpt-5.2')
          expect(json_response[:credits_consumed]).to eq(1.0)
          expect(json_response[:run_context].length).to eq(4)
          expect(json_response[:run_context].second[:tool_calls].first[:arguments][:query]).to eq('refund')

          citations = json_response[:citations].index_by { |citation| citation[:id] }
          expect(citations.keys).to contain_exactly(documented_faq.id, plain_faq.id, pdf_faq.id)
          expect(citations[documented_faq.id][:title]).to eq('How do I reset my password?')
          expect(citations[documented_faq.id][:link]).to eq(document.external_link)
          expect(citations[plain_faq.id][:link]).to be_nil
          expect(pdf_document.external_link).to start_with('PDF:')
          expect(citations[pdf_faq.id][:link]).to eq(pdf_document.display_url)
          expect(citations[pdf_faq.id][:link]).to match(%r{\Ahttps?://})

          expect(json_response[:scenarios]).to eq([{ id: scenario.id, title: 'Refund flow' }])
        end
      end

      it 'does not allow an agent without access to the conversation' do
        other_agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/captain/agent_sessions/#{message.id}",
            headers: other_agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the message has no agent session' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/captain/agent_sessions/#{message.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the message does not belong to the account' do
      it 'returns not found' do
        other_message = create(:message)

        get "/api/v1/accounts/#{account.id}/captain/agent_sessions/#{other_message.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
