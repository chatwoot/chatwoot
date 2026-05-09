require 'rails_helper'

RSpec.describe 'Notion Integration API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:issue_tracker_service) { instance_double(Integrations::Notion::IssueTrackerService) }
  let!(:hook) do
    create(
      :integrations_hook,
      account: account,
      app_id: 'notion',
      access_token: 'notion_access_token',
      settings: {
        'workspace_name' => 'Support workspace',
        'issue_tracker' => {
          'data_source_id' => 'data-source-1',
          'title_property' => 'Name',
          'status_property' => 'Status'
        }
      }
    )
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/notion/create_issue' do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:issue_params) do
      {
        title: 'Sample Issue',
        description: 'This is a sample issue.',
        priority: 'High',
        state_id: 'In progress',
        label_ids: ['Billing'],
        conversation_id: conversation.display_id
      }
    end

    before do
      allow(Integrations::Notion::IssueTrackerService).to receive(:new).with(account: account).and_return(issue_tracker_service)
    end

    it 'returns the created issue for an agent' do
      allow(issue_tracker_service).to receive(:create_issue).with(issue_params.stringify_keys, agent).and_return(
        data: { id: 'page-1', title: 'Sample Issue', url: 'https://notion.so/page-1' }
      )

      post "/api/v1/accounts/#{account.id}/integrations/notion/create_issue",
           params: issue_params,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'id' => 'page-1',
        'title' => 'Sample Issue',
        'url' => 'https://notion.so/page-1'
      )
    end

    it 'creates activity message when the issue is created by an agent' do
      allow(issue_tracker_service).to receive(:create_issue).with(issue_params.stringify_keys, agent).and_return(
        data: { id: 'page-1', title: 'Sample Issue', url: 'https://notion.so/page-1' }
      )

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/notion/create_issue",
             params: issue_params,
             headers: agent.create_new_auth_token,
             as: :json
      end.to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, {
                account_id: conversation.account_id,
                inbox_id: conversation.inbox_id,
                message_type: :activity,
                content: "Notion issue Sample Issue was created by #{agent.name}"
              })
    end

    it 'returns error message and does not create activity message when creation fails' do
      allow(issue_tracker_service).to receive(:create_issue).with(issue_params.stringify_keys, agent).and_return(error: 'error message')

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/notion/create_issue",
             params: issue_params,
             headers: agent.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => 'error message')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/notion/linked_issues' do
    let(:conversation) { create(:conversation, account: account) }

    before do
      allow(Integrations::Notion::IssueTrackerService).to receive(:new).with(account: account).and_return(issue_tracker_service)
    end

    it 'returns linked Notion issues for an agent' do
      allow(issue_tracker_service).to receive(:linked_issues).with(conversation.display_id).and_return(
        data: [{ id: 'page-1', title: 'Sample Issue', url: 'https://notion.so/page-1' }]
      )

      get "/api/v1/accounts/#{account.id}/integrations/notion/linked_issues",
          params: { conversation_id: conversation.display_id },
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        [{ 'id' => 'page-1', 'title' => 'Sample Issue', 'url' => 'https://notion.so/page-1' }]
      )
    end

    it 'returns error message when linked issues cannot be loaded' do
      allow(issue_tracker_service).to receive(:linked_issues).with(conversation.display_id).and_return(error: 'error message')

      get "/api/v1/accounts/#{account.id}/integrations/notion/linked_issues",
          params: { conversation_id: conversation.display_id },
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => 'error message')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/notion/issue_tracker' do
    it 'returns the stored issue tracker settings' do
      get "/api/v1/accounts/#{account.id}/integrations/notion/issue_tracker",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'data_source_id' => 'data-source-1',
        'title_property' => 'Name',
        'status_property' => 'Status'
      )
    end

    it 'does not allow agents to access issue tracker settings' do
      get "/api/v1/accounts/#{account.id}/integrations/notion/issue_tracker",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/integrations/notion/issue_tracker' do
    it 'stores permitted issue tracker settings and keeps blank optional mappings' do
      patch "/api/v1/accounts/#{account.id}/integrations/notion/issue_tracker",
            params: {
              data_source_id: 'data-source-2',
              title_property: 'Task',
              description_property: 'Description',
              assignee_property: '',
              project_property: 'Project',
              status_property: 'Status',
              priority_property: '',
              label_property: 'Tags',
              unpermitted_property: 'Ignored'
            },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'data_source_id' => 'data-source-2',
        'title_property' => 'Task',
        'description_property' => 'Description',
        'assignee_property' => '',
        'project_property' => 'Project',
        'status_property' => 'Status',
        'priority_property' => '',
        'label_property' => 'Tags'
      )
      expect(hook.reload.settings['workspace_name']).to eq('Support workspace')
      expect(hook.settings['issue_tracker']).to eq(response.parsed_body)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/notion/validate_issue_tracker' do
    let(:service) { instance_double(Integrations::Notion::IssueTrackerConfigService) }

    before do
      allow(Integrations::Notion::IssueTrackerConfigService).to receive(:new).with(hook: hook).and_return(service)
    end

    it 'returns normalized data source properties' do
      allow(service).to receive(:validate).with('data-source-1').and_return(
        data: {
          data_source_id: 'data-source-1',
          title_property: 'Name',
          properties: [
            { name: 'Name', type: 'title' },
            { name: 'Status', type: 'status' }
          ]
        }
      )

      post "/api/v1/accounts/#{account.id}/integrations/notion/validate_issue_tracker",
           params: { data_source_id: 'data-source-1' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'data_source_id' => 'data-source-1',
        'title_property' => 'Name',
        'properties' => [
          { 'name' => 'Name', 'type' => 'title' },
          { 'name' => 'Status', 'type' => 'status' }
        ]
      )
    end

    it 'returns validation errors' do
      allow(service).to receive(:validate).with('missing-data-source').and_return(error: 'Unable to access data source')

      post "/api/v1/accounts/#{account.id}/integrations/notion/validate_issue_tracker",
           params: { data_source_id: 'missing-data-source' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => 'Unable to access data source')
    end
  end
end
