# frozen_string_literal: true

FactoryBot.define do
  factory :synapseos_lead, class: 'Synapseos::Lead' do
    association :conversation
    status { :open }
    source { 'spec' }
    metadata { {} }

    after(:build) do |lead|
      lead.account ||= lead.conversation&.account || create(:account)
      lead.contact ||= lead.conversation&.contact
    end
  end

  factory :synapseos_pipeline_stage, class: 'Synapseos::PipelineStage' do
    association :account
    sequence(:name) { |n| "Stage #{n}" }
    stage_type { 'custom' }
    sequence(:position) { |n| n }
  end
end
