FactoryBot.define do
  factory :kbase_portal_category, class: 'Kbase::PortalCategory' do
    account_id { 1 }
    portal_id { 1 }
    category_id { 1 }
  end
end
