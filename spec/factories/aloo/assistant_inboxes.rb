# frozen_string_literal: true

# == Schema Information
#
# Table name: aloo_assistant_inboxes
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  aloo_assistant_id :bigint           not null
#  inbox_id          :bigint           not null
#
# Indexes
#
#  index_aloo_assistant_inboxes_on_aloo_assistant_id  (aloo_assistant_id)
#  index_aloo_assistant_inboxes_on_inbox_unique       (inbox_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (aloo_assistant_id => aloo_assistants.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
FactoryBot.define do
  factory :aloo_assistant_inbox, class: 'Aloo::AssistantInbox' do
    association :assistant, factory: :aloo_assistant
    inbox
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
