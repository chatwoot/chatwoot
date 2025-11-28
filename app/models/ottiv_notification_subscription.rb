class OttivNotificationSubscription < ApplicationRecord
  belongs_to :user

  validates :identifier, presence: true

  SUBSCRIPTION_TYPES = {
    browser_push: 1,
    fcm: 2,
    onesignal: 3
  }.freeze

  enum subscription_type: SUBSCRIPTION_TYPES
end
