# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                   :bigint           not null, primary key
#  last_activity_at     :datetime
#  meta                 :jsonb
#  notification_type    :integer          not null
#  primary_actor_type   :string           not null
#  read_at              :datetime
#  secondary_actor_type :string
#  snoozed_until        :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  primary_actor_id     :bigint           not null
#  secondary_actor_id   :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  idx_notifications_performance                   (user_id,account_id,snoozed_until,read_at)
#  index_notifications_on_account_id               (account_id)
#  index_notifications_on_last_activity_at         (last_activity_at)
#  index_notifications_on_user_id                  (user_id)
#  uniq_primary_actor_per_account_notifications    (primary_actor_type,primary_actor_id)
#  uniq_secondary_actor_per_account_notifications  (secondary_actor_type,secondary_actor_id)
#
FactoryBot.define do
  factory :notification do
    primary_actor { create(:conversation, account: account) }
    notification_type { 'conversation_assignment' }
    user
    account
    read_at { nil }
    snoozed_until { nil }
  end

  trait :read do
    read_at { DateTime.now.utc - 3.days }
  end

  trait :snoozed do
    snoozed_until { DateTime.now.utc + 3.days }
  end
end
