# == Schema Information
#
# Table name: notification_subscriptions
#
#  id                      :bigint           not null, primary key
#  identifier              :text
#  subscription_attributes :jsonb            not null
#  subscription_type       :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_notification_subscriptions_on_identifier  (identifier) UNIQUE
#  index_notification_subscriptions_on_user_id     (user_id)
#

class NotificationSubscription < ApplicationRecord
  belongs_to :user
  validates :identifier, presence: true

  SUBSCRIPTION_TYPES = {
    browser_push: 1,
    fcm: 2
  }.freeze

  enum subscription_type: SUBSCRIPTION_TYPES
end
