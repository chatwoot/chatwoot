require 'rails_helper'

# Fork: the assignee picker the dashboard actually calls.
#
# `Api::V1::Accounts::AssignableAgentsController#index` rebuilds the list as
# `inbox members + Current.account.administrators` rather than delegating to
# `Inbox#assignable_agents`, so scoping the model alone leaves this payload —
# and therefore the visible dropdown — still offering platform infrastructure.
#
# The overlay is prepended from config/initializers/custom_prepends.rb because
# upstream ships no `prepend_mod_with` hook on this controller.
RSpec.describe 'Custom::Api::V1::Accounts::AssignableAgentsController', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:vendor_admin) { create(:user, account: account, role: :administrator) }

  let!(:service_admin) do
    user = create(:user, account: account, role: :administrator)
    user.account_users.find_by(account: account).update!(platform_managed: true)
    user
  end

  it 'omits the platform service admin but keeps the vendor admin' do
    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [inbox.id] },
        headers: vendor_admin.create_new_auth_token,
        as: :json

    expect(response).to have_http_status(:success)
    # The view wraps the list in `payload` (index.json.jbuilder).
    ids = response.parsed_body['payload'].map { |agent| agent['id'] }

    expect(ids).to include(vendor_admin.id)
    expect(ids).not_to include(service_admin.id)
  end
end
