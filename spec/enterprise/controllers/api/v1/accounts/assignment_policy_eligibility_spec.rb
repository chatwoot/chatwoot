require 'rails_helper'

RSpec.describe 'Assignment policy eligibility API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:role) { create(:custom_role, account: account) }

  it 'persists and returns the business-hours, role and customer-message priority controls' do
    params = { name: 'Sales', assignment_order: 'balanced', conversation_priority: 'latest_customer_message',
               business_hours_only: true, eligible_custom_role_id: role.id, fair_distribution_limit: 5, fair_distribution_window: 3600 }
    post "/api/v1/accounts/#{account.id}/assignment_policies", headers: admin.create_new_auth_token, params: params, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include('eligible_custom_role_id' => role.id, 'business_hours_only' => true,
                                            'conversation_priority' => 'latest_customer_message')
  end

  it 'rejects a custom role from another account without creating a policy' do
    post "/api/v1/accounts/#{account.id}/assignment_policies", headers: admin.create_new_auth_token,
                                                               params: { name: 'Sales', eligible_custom_role_id: create(:custom_role).id }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.assignment_policies.count).to eq(0)
  end
end
