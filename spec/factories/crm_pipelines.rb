FactoryBot.define do
  factory :crm_pipeline, class: 'Crm::Pipeline' do
    sequence(:name) { |n| "Pipeline #{n}" }
    account
    display_order { 0 }
  end
end
