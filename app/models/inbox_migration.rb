# frozen_string_literal: true

# == Schema Information
#
# Table name: inbox_migrations
#
#  id                     :bigint           not null, primary key
#  account_id             :bigint           not null
#  source_inbox_id        :bigint           not null
#  destination_inbox_id   :bigint           not null
#  user_id                :bigint
#  status                 :integer          default("queued"), not null
#  conversations_count    :integer          default(0)
#  conversations_moved    :integer          default(0)
#  messages_count         :integer          default(0)
#  messages_moved         :integer          default(0)
#  attachments_count      :integer          default(0)
#  attachments_moved      :integer          default(0)
#  contact_inboxes_count  :integer          default(0)
#  contact_inboxes_moved  :integer          default(0)
#  contacts_merged        :integer          default(0)
#  error_message          :text
#  error_backtrace        :text
#  started_at             :datetime
#  completed_at           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class InboxMigration < ApplicationRecord
  belongs_to :account
  belongs_to :source_inbox, class_name: 'Inbox'
  belongs_to :destination_inbox, class_name: 'Inbox'
  belongs_to :user, optional: true

  enum status: {
    queued: 0,
    running: 1,
    completed: 2,
    failed: 3,
    cancelled: 4
  }

  validates :account_id, presence: true
  validates :source_inbox_id, presence: true
  validates :destination_inbox_id, presence: true
  validate :inboxes_belong_to_same_account
  validate :inboxes_are_different
  validate :inboxes_are_whatsapp_like
  validate :no_active_migration_for_source, on: :create

  scope :active, -> { where(status: [:queued, :running]) }
  scope :recent, -> { order(created_at: :desc) }

  # Check if inbox is eligible for migration (API channels and WhatsApp-like)
  def self.whatsapp_like_inbox?(inbox)
    return false unless inbox

    # All API channels are eligible for migration
    return true if inbox.channel_type == 'Channel::Api'

    # Native WhatsApp inbox
    return true if inbox.channel_type == 'Channel::Whatsapp'

    # Twilio WhatsApp
    return inbox.channel&.medium == 'whatsapp' if inbox.channel_type == 'Channel::TwilioSms'

    false
  end

  def progress_percentage
    return 0 if conversations_count.zero?

    ((conversations_moved.to_f / conversations_count) * 100).round(1)
  end

  def duration_seconds
    return nil unless started_at

    end_time = completed_at || Time.current
    (end_time - started_at).to_i
  end

  def mark_running!
    update!(status: :running, started_at: Time.current)
  end

  def mark_completed!
    update!(status: :completed, completed_at: Time.current)
  end

  def mark_failed!(message, backtrace = nil)
    update!(
      status: :failed,
      completed_at: Time.current,
      error_message: message,
      error_backtrace: backtrace&.first(20)&.join("\n")
    )
  end

  def mark_cancelled!
    update!(status: :cancelled, completed_at: Time.current)
  end

  def update_counts!(conversations:, messages:, attachments:, contact_inboxes:)
    update!(
      conversations_count: conversations,
      messages_count: messages,
      attachments_count: attachments,
      contact_inboxes_count: contact_inboxes
    )
  end

  def increment_progress!(conversations: 0, messages: 0, attachments: 0, contact_inboxes: 0, contacts_merged: 0)
    self.class.where(id: id).update_all(
      "conversations_moved = conversations_moved + #{conversations.to_i}, " \
      "messages_moved = messages_moved + #{messages.to_i}, " \
      "attachments_moved = attachments_moved + #{attachments.to_i}, " \
      "contact_inboxes_moved = contact_inboxes_moved + #{contact_inboxes.to_i}, " \
      "contacts_merged = contacts_merged + #{contacts_merged.to_i}"
    )
    reload
  end

  private

  def inboxes_belong_to_same_account
    return unless source_inbox && destination_inbox

    errors.add(:base, 'Source and destination inboxes must belong to the same account') unless source_inbox.account_id == destination_inbox.account_id

    return if source_inbox.account_id == account_id

    errors.add(:base, 'Inboxes must belong to the migration account')
  end

  def inboxes_are_different
    return unless source_inbox_id && destination_inbox_id

    return unless source_inbox_id == destination_inbox_id

    errors.add(:base, 'Source and destination inboxes must be different')
  end

  def inboxes_are_whatsapp_like
    return unless source_inbox && destination_inbox

    unless self.class.whatsapp_like_inbox?(source_inbox)
      errors.add(:source_inbox, 'must be a WhatsApp-like inbox (Evolution API, WhatsApp, or Twilio WhatsApp)')
    end

    return if self.class.whatsapp_like_inbox?(destination_inbox)

    errors.add(:destination_inbox, 'must be a WhatsApp-like inbox (Evolution API, WhatsApp, or Twilio WhatsApp)')
  end

  def no_active_migration_for_source
    return unless source_inbox_id

    return unless InboxMigration.active.exists?(source_inbox_id: source_inbox_id)

    errors.add(:base, 'An active migration already exists for this source inbox')
  end
end
