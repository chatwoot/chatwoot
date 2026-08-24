FactoryBot.define do
  factory :captain_tool_catalog_installation, class: 'Captain::ToolCatalogInstallation' do
    account
    association :initiated_by, factory: :user
    provider_key { 'stripe' }
    selected_templates do
      [
        {
          'template_key' => 'find_customer',
          'template_version' => '1.0.0',
          'configuration' => {}
        }
      ]
    end
    status { 'pending' }
    expires_at { 30.minutes.from_now }
  end
end
