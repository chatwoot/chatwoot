require 'rails_helper'

RSpec.describe 'Notion Integration API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
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

  describe 'GET /api/v1/accounts/:account_id/integrations/notion/issue_tracker' do
    it 'returns the stored issue tracker settings' do
      get "/api/v1/accounts/#{account.id}/integrations/notion/issue_tracker",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'data_source_id' => 'data-source-1',
        'title_property' => 'Name',
        'status_property' => 'Status'
      )
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
            headers: agent.create_new_auth_token,
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
           headers: agent.create_new_auth_token,
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
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => 'Unable to access data source')
    end
  end
end
