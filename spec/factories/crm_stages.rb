FactoryBot.define do
  factory :crm_stage, class: 'Crm::Stage' do
    sequence(:name) { |n| "Stage #{n}" }
    association :crm_pipeline, factory: :crm_pipeline
    stage_type { 0 }
    display_order { 0 }
  end
end
