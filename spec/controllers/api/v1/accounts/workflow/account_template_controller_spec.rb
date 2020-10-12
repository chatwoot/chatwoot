require 'rails_helper'

RSpec.describe 'Account Templates API', type: :request do
  let(:account) { create(:account) }

  before do
    create(:workflow_account_template, account: account)
  end

  describe 'GET /api/v1/accounts/{account.id}/workflow/account_templates' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/workflow/account_templates"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :administrator) }

      it 'returns all the workflow account templates' do
        get "/api/v1/accounts/#{account.id}/workflow/account_templates",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(account.workflow_account_templates.first.template.description)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/workflow/account_templates' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/workflow/account_templates"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates a new workflow template if its an administrator' do
        user = create(:user, account: account, role: :administrator)
        inbox = create(:inbox, account: account)
        params = { template_id: Workflow::Template.all.first.id, config: { test: 1 }, inbox_ids: [inbox.id] }

        post "/api/v1/accounts/#{account.id}/workflow/account_templates",
             params: params,
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        response = JSON.parse(body)
        expect(response['template_id']).to eq(Workflow::Template.all.first.id)
        expect(response['config']).to eq({ 'test' => 1 })
        expect(response['inboxes'].first['id']).to eq(inbox.id)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/workflow/account_templates/:id' do
    let(:account_template) { create(:workflow_account_template, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/workflow/account_templates/#{account_template.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the workflow template if its an administrator' do
        user = create(:user, account: account, role: :administrator)
        inbox = create(:inbox, account: account)
        params = { template_id: 'no_update', config: { test: 1 }, inbox_ids: [inbox.id] }

        put "/api/v1/accounts/#{account.id}/workflow/account_templates/#{account_template.id}",
            params: params,
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response = JSON.parse(body)
        expect(response['template_id']).to eq(account_template.template_id)
        expect(response['config']).to eq({ 'test' => 1 })
        expect(response['inboxes'].first['id']).to eq(inbox.id)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/workflow/account_templates/:id' do
    let(:account_template) { Workflow::AccountTemplate.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/workflow/account_templates/#{account_template.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'destroys the workflow template if its an administrator' do
        user = create(:user, account: account, role: :administrator)
        delete "/api/v1/accounts/#{account.id}/workflow/account_templates/#{Workflow::AccountTemplate.first.id}",
               headers: user.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Workflow::AccountTemplate.count).to eq(0)
      end
    end
  end
end
