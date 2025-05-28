require 'rails_helper'

RSpec.describe 'Linear Integration API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:api_key) { 'valid_api_key' }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:processor_service) { instance_double(Integrations::Linear::ProcessorService) }

  before do
    create(:integrations_hook, :linear, account: account)
    allow(Integrations::Linear::ProcessorService).to receive(:new).with(account: account).and_return(processor_service)
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/linear' do
    it 'deletes the linear integration' do
      delete "/api/v1/accounts/#{account.id}/integrations/linear",
             headers: agent.create_new_auth_token,
             as: :json
      expect(response).to have_http_status(:ok)
      expect(account.hooks.count).to eq(0)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/linear/teams' do
    context 'when it is an authenticated user' do
      context 'when data is retrieved successfully' do
        let(:teams_data) { { data: [{ 'id' => 'team1', 'name' => 'Team One' }] } }

        it 'returns team data' do
          allow(processor_service).to receive(:teams).and_return(teams_data)
          get "/api/v1/accounts/#{account.id}/integrations/linear/teams",
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Team One')
        end
      end

      context 'when data retrieval fails' do
        it 'returns error message' do
          allow(processor_service).to receive(:teams).and_return(error: 'error message')
          get "/api/v1/accounts/#{account.id}/integrations/linear/teams",
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/linear/team_entities' do
    let(:team_id) { 'team1' }

    context 'when it is an authenticated user' do
      context 'when data is retrieved successfully' do
        let(:team_entities_data) do
          { data: {
            users: [{ 'id' => 'user1', 'name' => 'User One' }],
            projects: [{ 'id' => 'project1', 'name' => 'Project One' }],
            states: [{ 'id' => 'state1', 'name' => 'State One' }],
            labels: [{ 'id' => 'label1', 'name' => 'Label One' }]
          } }
        end

        it 'returns team entities data' do
          allow(processor_service).to receive(:team_entities).with(team_id).and_return(team_entities_data)
          get "/api/v1/accounts/#{account.id}/integrations/linear/team_entities",
              params: { team_id: team_id },
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('User One')
          expect(response.body).to include('Project One')
          expect(response.body).to include('State One')
          expect(response.body).to include('Label One')
        end
      end

      context 'when data retrieval fails' do
        it 'returns error message' do
          allow(processor_service).to receive(:team_entities).with(team_id).and_return(error: 'error message')
          get "/api/v1/accounts/#{account.id}/integrations/linear/team_entities",
              params: { team_id: team_id },
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/linear/create_issue' do
    let(:issue_params) do
      {
        team_id: 'team1',
        title: 'Sample Issue',
        description: 'This is a sample issue.',
        assignee_id: 'user1',
        priority: 'high',
        state_id: 'state1',
        label_ids: ['label1']
      }
    end

    context 'when it is an authenticated user' do
      context 'when the issue is created successfully' do
        let(:created_issue) { { data: { 'id' => 'issue1', 'title' => 'Sample Issue' } } }

        it 'returns the created issue' do
          allow(processor_service).to receive(:create_issue).with(issue_params.stringify_keys).and_return(created_issue)
          post "/api/v1/accounts/#{account.id}/integrations/linear/create_issue",
               params: issue_params,
               headers: agent.create_new_auth_token,
               as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Sample Issue')
        end
      end

      context 'when issue creation fails' do
        it 'returns error message' do
          allow(processor_service).to receive(:create_issue).with(issue_params.stringify_keys).and_return(error: 'error message')
          post "/api/v1/accounts/#{account.id}/integrations/linear/create_issue",
               params: issue_params,
               headers: agent.create_new_auth_token,
               as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/linear/link_issue' do
    let(:issue_id) { 'issue1' }
    let(:conversation) { create(:conversation, account: account) }
    let(:link) { "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/conversations/#{conversation.display_id}" }
    let(:title) { 'Sample Issue' }

    context 'when it is an authenticated user' do
      context 'when the issue is linked successfully' do
        let(:linked_issue) { { data: { 'id' => 'issue1', 'link' => 'https://linear.app/issue1' } } }

        it 'returns the linked issue' do
          allow(processor_service).to receive(:link_issue).with(link, issue_id, title).and_return(linked_issue)
          post "/api/v1/accounts/#{account.id}/integrations/linear/link_issue",
               params: { conversation_id: conversation.display_id, issue_id: issue_id, title: title },
               headers: agent.create_new_auth_token,
               as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('https://linear.app/issue1')
        end
      end

      context 'when issue linking fails' do
        it 'returns error message' do
          allow(processor_service).to receive(:link_issue).with(link, issue_id, title).and_return(error: 'error message')
          post "/api/v1/accounts/#{account.id}/integrations/linear/link_issue",
               params: { conversation_id: conversation.display_id, issue_id: issue_id, title: title },
               headers: agent.create_new_auth_token,
               as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/linear/unlink_issue' do
    let(:link_id) { 'attachment1' }

    context 'when it is an authenticated user' do
      context 'when the issue is unlinked successfully' do
        let(:unlinked_issue) { { data: { 'id' => 'issue1', 'link' => 'https://linear.app/issue1' } } }

        it 'returns the unlinked issue' do
          allow(processor_service).to receive(:unlink_issue).with(link_id).and_return(unlinked_issue)
          post "/api/v1/accounts/#{account.id}/integrations/linear/unlink_issue",
               params: { link_id: link_id },
               headers: agent.create_new_auth_token,
               as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('https://linear.app/issue1')
        end
      end

      context 'when issue unlinking fails' do
        it 'returns error message' do
          allow(processor_service).to receive(:unlink_issue).with(link_id).and_return(error: 'error message')
          post "/api/v1/accounts/#{account.id}/integrations/linear/unlink_issue",
               params: { link_id: link_id },
               headers: agent.create_new_auth_token,
               as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/linear/search_issue' do
    let(:term) { 'issue' }

    context 'when it is an authenticated user' do
      context 'when search is successful' do
        let(:search_results) { { data: [{ 'id' => 'issue1', 'title' => 'Sample Issue' }] } }

        it 'returns search results' do
          allow(processor_service).to receive(:search_issue).with(term).and_return(search_results)
          get "/api/v1/accounts/#{account.id}/integrations/linear/search_issue",
              params: { q: term },
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Sample Issue')
        end
      end

      context 'when search fails' do
        it 'returns error message' do
          allow(processor_service).to receive(:search_issue).with(term).and_return(error: 'error message')
          get "/api/v1/accounts/#{account.id}/integrations/linear/search_issue",
              params: { q: term },
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/linear/linked_issues' do
    let(:conversation) { create(:conversation, account: account) }
    let(:link) { "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/conversations/#{conversation.display_id}" }

    context 'when it is an authenticated user' do
      context 'when linked issue is found' do
        let(:linked_issue) { { data: [{ 'id' => 'issue1', 'title' => 'Sample Issue' }] } }

        it 'returns linked issue' do
          allow(processor_service).to receive(:linked_issues).with(link).and_return(linked_issue)
          get "/api/v1/accounts/#{account.id}/integrations/linear/linked_issues",
              params: { conversation_id: conversation.display_id },
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Sample Issue')
        end
      end

      context 'when linked issue is not found' do
        it 'returns error message' do
          allow(processor_service).to receive(:linked_issues).with(link).and_return(error: 'error message')
          get "/api/v1/accounts/#{account.id}/integrations/linear/linked_issues",
              params: { conversation_id: conversation.display_id },
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('error message')
        end
      end
    end
  end
end
