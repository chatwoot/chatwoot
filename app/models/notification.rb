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
#  index_notifications_on_account_id               (account_id)
#  index_notifications_on_last_activity_at         (last_activity_at)
#  index_notifications_on_user_id                  (user_id)
#  uniq_primary_actor_per_account_notifications    (primary_actor_type,primary_actor_id)
#  uniq_secondary_actor_per_account_notifications  (secondary_actor_type,secondary_actor_id)
#

class Notification < ApplicationRecord
  include MessageFormatHelper
  belongs_to :account
  belongs_to :user

  belongs_to :primary_actor, polymorphic: true
  belongs_to :secondary_actor, polymorphic: true, optional: true

  NOTIFICATION_TYPES = {
    conversation_creation: 1,
    conversation_assignment: 2,
    assigned_conversation_new_message: 3,
    conversation_mention: 4,
    participating_conversation_new_message: 5,
    sla_missed_first_response: 6,
    sla_missed_next_response: 7,
    sla_missed_resolution: 8
  }.freeze

  enum notification_type: NOTIFICATION_TYPES

  before_create :set_last_activity_at
  after_create_commit :process_notification_delivery, :dispatch_create_event
  after_destroy_commit :dispatch_destroy_event
  after_update_commit :dispatch_update_event

  PRIMARY_ACTORS = ['Conversation'].freeze

  def push_event_data
    # Secondary actor could be nil for cases like system assigning conversation
    payload = {
      id: id,
      notification_type: notification_type,
      primary_actor_type: primary_actor_type,
      primary_actor_id: primary_actor_id,
      read_at: read_at,
      secondary_actor: secondary_actor&.push_event_data,
      user: user&.push_event_data,
      created_at: created_at.to_i,
      last_activity_at: last_activity_at.to_i,
      snoozed_until: snoozed_until,
      meta: meta,
      account_id: account_id

    }
    if primary_actor.present?
      payload[:primary_actor] = primary_actor&.push_event_data
      # TODO: Rename push_message_title to push_message_body
      payload[:push_message_title] = push_message_body
    end
    payload
  end

  def fcm_push_data
    {
      id: id,
      notification_type: notification_type,
      primary_actor_id: primary_actor_id,
      primary_actor_type: primary_actor_type,
      primary_actor: primary_actor.push_event_data.with_indifferent_access.slice('conversation_id', 'id')
    }
  end

  # rubocop:disable Metrics/MethodLength
  def push_message_title
    notification_title_map = {
      'conversation_creation' => 'notifications.notification_title.conversation_creation',
      'conversation_assignment' => 'notifications.notification_title.conversation_assignment',
      'assigned_conversation_new_message' => 'notifications.notification_title.assigned_conversation_new_message',
      'participating_conversation_new_message' => 'notifications.notification_title.assigned_conversation_new_message',
      'conversation_mention' => 'notifications.notification_title.conversation_mention',
      'sla_missed_first_response' => 'notifications.notification_title.sla_missed_first_response',
      'sla_missed_next_response' => 'notifications.notification_title.sla_missed_next_response',
      'sla_missed_resolution' => 'notifications.notification_title.sla_missed_resolution'
    }

    i18n_key = notification_title_map[notification_type]
    return '' unless i18n_key

    if notification_type == 'conversation_creation'
      I18n.t(i18n_key, display_id: conversation.display_id, inbox_name: primary_actor.inbox.name)
    elsif %w[conversation_assignment assigned_conversation_new_message participating_conversation_new_message
             conversation_mention].include?(notification_type)
      I18n.t(i18n_key, display_id: conversation.display_id)
    else
      I18n.t(i18n_key, display_id: primary_actor.display_id)
    end
  end
  # rubocop:enable Metrics/MethodLength

  def push_message_body
    case notification_type
    when 'conversation_creation', 'sla_missed_first_response'
      message_body(conversation.messages.first)
    when 'assigned_conversation_new_message', 'participating_conversation_new_message', 'conversation_mention'
      message_body(secondary_actor)
    when 'conversation_assignment', 'sla_missed_next_response', 'sla_missed_resolution'
      message_body(conversation.messages.incoming.last)
    else
      ''
    end
  end

  def conversation
    primary_actor
  end

  private

  def message_body(actor)
    sender_name = sender_name(actor)
    content = message_content(actor)
    "#{sender_name}: #{content}"
  end

  def sender_name(actor)
    actor.try(:sender)&.name || ''
  end

  def message_content(actor)
    content = actor.try(:content)
    attachments = actor.try(:attachments)

    if content.present?
      transform_user_mention_content(content.truncate_words(10))
    else
      attachments.present? ? I18n.t('notifications.attachment') : I18n.t('notifications.no_content')
    end
  end

  def process_notification_delivery
    Notification::PushNotificationJob.perform_later(self) if user_subscribed_to_notification?('push')

    # Should we do something about the case where user subscribed to both push and email ?
    # In future, we could probably add condition here to enqueue the job for 30 seconds later
    # when push enabled and then check in email job whether notification has been read already.
    Notification::EmailNotificationJob.perform_later(self) if user_subscribed_to_notification?('email')

    Notification::RemoveDuplicateNotificationJob.perform_later(self)
  end

  def user_subscribed_to_notification?(delivery_type)
    notification_setting = user.notification_settings.find_by(account_id: account.id)
    return false if notification_setting.blank?

    # Check if the user has subscribed to the specified type of notification
    notification_setting.public_send("#{delivery_type}_#{notification_type}?")
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(NOTIFICATION_CREATED, Time.zone.now, notification: self)
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(NOTIFICATION_UPDATED, Time.zone.now, notification: self)
  end

  def dispatch_destroy_event
    Rails.configuration.dispatcher.dispatch(NOTIFICATION_DELETED, Time.zone.now, notification: self)
  end

  def set_last_activity_at
    self.last_activity_at = created_at
  end
end
