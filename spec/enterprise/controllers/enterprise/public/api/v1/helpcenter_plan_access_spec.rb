require 'rails_helper'

RSpec.describe 'Public Help Center Access', type: :request do
  let(:plan_name) { 'Startups' }
  let!(:account) { create(:account, custom_attributes: { 'plan_name' => plan_name }) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, account: account, custom_domain: 'docs-helpcenter.example.com') }
  let!(:category) { create(:category, portal: portal, account: account, locale: 'en', slug: 'category-slug') }
  let!(:article) { create(:article, category: category, portal: portal, account: account, author: agent, status: :published) }

  around do |example|
    with_modified_env FRONTEND_URL: 'https://app.chatwoot.com', HELPCENTER_URL: 'https://help.chatwoot.com' do
      previous_deployment_env = InstallationConfig.find_by(name: 'DEPLOYMENT_ENV')&.value
      InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_initialize.update!(value: 'cloud')

      example.run
    ensure
      config = InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_initialize
      previous_deployment_env.present? ? config.update!(value: previous_deployment_env) : config.destroy!
      host! 'www.example.com'
    end
  end

  it 'blocks chatwoot-hosted portal pages when the help center feature is disabled' do
    account.disable_features!(:help_center)
    host! 'help.chatwoot.com'

    get "/hc/#{portal.slug}/en"

    expect(response).to have_http_status(:payment_required)
    expect(response.body).to include('Help Center Unavailable')
  end

  context 'when the account is on the default plan' do
    let(:plan_name) { 'Hacker' }

    it 'still allows access if the feature flag is enabled' do
      account.enable_features!(:help_center)
      host! portal.custom_domain

      get "/hc/#{portal.slug}/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
    end
  end
end
