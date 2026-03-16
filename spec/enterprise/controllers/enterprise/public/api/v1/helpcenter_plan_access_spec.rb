require 'rails_helper'

RSpec.describe 'Public Help Center Plan Access', type: :request do
  let!(:account) { create(:account, custom_attributes: { 'plan_name' => 'Hacker' }) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'test-portal', account: account, custom_domain: 'docs.example.com') }
  let!(:category) { create(:category, portal: portal, account: account, locale: 'en', slug: 'category-slug') }
  let!(:article) { create(:article, category: category, portal: portal, account: account, author: agent, status: :published) }

  around do |example|
    with_modified_env FRONTEND_URL: 'https://app.chatwoot.com', HELPCENTER_URL: 'https://help.chatwoot.com' do
      example.run
    ensure
      host! 'www.example.com'
    end
  end

  before do
    InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_initialize.update!(value: 'cloud')
    InstallationConfig.where(name: 'CHATWOOT_CLOUD_PLANS').first_or_initialize.update!(value: [{ 'name' => 'Hacker' }])
  end

  it 'blocks chatwoot-hosted portal pages for the default plan' do
    host! 'help.chatwoot.com'

    get "/hc/#{portal.slug}/en"

    expect(response).to have_http_status(:payment_required)
    expect(response.body).to include('Help Center Not Active')
  end

  it 'blocks custom-domain article pages for the default plan' do
    host! portal.custom_domain

    get "/hc/#{portal.slug}/articles/#{article.slug}"

    expect(response).to have_http_status(:payment_required)
    expect(response.body).to include('Help Center Not Active')
  end
end
