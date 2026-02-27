FactoryBot.define do
  factory :crm_lead, class: 'Crm::Lead' do
    sequence(:title) { |n| "Lead #{n}" }
    account
    association :crm_stage, factory: :crm_stage
    contact
    priority { 0 }
  end
end
