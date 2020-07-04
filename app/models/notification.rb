# == Schema Information
#
# Table name: notifications
#
#  id                   :bigint           not null, primary key
#  notification_type    :integer          not null
#  primary_actor_type   :string           not null
#  read_at              :datetime
#  secondary_actor_type :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  primary_actor_id     :bigint           not null
#  secondary_actor_id   :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  index_notifications_on_account_id               (account_id)
#  index_notifications_on_user_id                  (user_id)
#  uniq_primary_actor_per_account_notifications    (primary_actor_type,primary_actor_id)
#  uniq_secondary_actor_per_account_notifications  (secondary_actor_type,secondary_actor_id)
#

class Notification < ApplicationRecord
  belongs_to :account
  belongs_to :user

  belongs_to :primary_actor, polymorphic: true
  belongs_to :secondary_actor, polymorphic: true, optional: true

  NOTIFICATION_TYPES = {
    conversation_creation: 1,
    conversation_assignment: 2
  }.freeze

  enum notification_type: NOTIFICATION_TYPES

  after_create_commit :process_notification_delivery
  default_scope { order(id: :desc) }

  PRIMARY_ACTORS = ['Conversation'].freeze

  def push_event_data
    {
      id: id,
      notification_type: notification_type,
      primary_actor_type: primary_actor_type,
      primary_actor_id: primary_actor_id,
      primary_actor: primary_actor&.push_event_data,
      read_at: read_at,
      secondary_actor: secondary_actor&.push_event_data,
      user: user&.push_event_data,
      created_at: created_at,
      account_id: account_id
    }
  end

  # TODO: move to a data presenter
  def push_message_title
    if notification_type == 'conversation_creation'
      return "A new conversation [ID -#{primary_actor.display_id}] has been created in #{primary_actor.inbox.name}"
    end

    return "A new conversation [ID -#{primary_actor.display_id}] has been assigned to you." if notification_type == 'conversation_assignment'

    ''
  end

  private

  def process_notification_delivery
    Notification::PushNotificationJob.perform_later(self)

    # Queuing after 2 minutes so that we won't send emails for read notifications
    Notification::EmailNotificationJob.set(wait: 2.minutes).perform_later(self)
  end
end
