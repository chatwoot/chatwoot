# frozen_string_literal: true

FactoryBot.define do
  factory :crm_flow do
    sequence(:name) { |n| "CRM Flow #{n}" }
    trigger_type { 'ticket_created' }
    scope_type { 'global' }
    actions { [{ 'order' => 1, 'action' => 'create_ticket', 'type' => 'desk', 'params' => {} }] }
    active { true }
    account

    trait :inactive do
      active { false }
    end

    trait :inbox_scoped do
      scope_type { 'inbox' }
      inbox
    end

    trait :with_required_fields do
      required_fields do
        [{ 'key' => 'ticket_subject', 'label' => 'Subject', 'type' => 'text', 'required' => true }]
      end
    end
  end
end
