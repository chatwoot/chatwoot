require 'rails_helper'

RSpec.describe 'Workflow Templates API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/account/{account_id}/workflow/templates' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_workflow_templates_url(account)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all active apps' do
        first_template = Workflow::Template.all.first
        get api_v1_account_workflow_templates_url(account),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        template = JSON.parse(response.body)['payload'].first
        expect(template['id']).to eql(first_template.id)
        expect(template['name']).to eql(first_template.name)
      end
    end
  end
end
