# == Schema Information
#
# Table name: moengage_webhook_event_logs
#
#  id                 :bigint           not null, primary key
#  error_message      :text
#  event_name         :string
#  payload            :jsonb
#  processing_time_ms :integer
#  response_data      :jsonb
#  status             :integer          default("pending"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  contact_id         :bigint
#  conversation_id    :bigint
#  hook_id            :bigint           not null
#
# Indexes
#
#  index_moengage_webhook_event_logs_on_account_id                 (account_id)
#  index_moengage_webhook_event_logs_on_account_id_and_created_at  (account_id,created_at)
#  index_moengage_webhook_event_logs_on_contact_id                 (contact_id)
#  index_moengage_webhook_event_logs_on_conversation_id            (conversation_id)
#  index_moengage_webhook_event_logs_on_hook_id                    (hook_id)
#  index_moengage_webhook_event_logs_on_hook_id_and_created_at     (hook_id,created_at)
#  index_moengage_webhook_event_logs_on_status_and_created_at      (status,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (hook_id => integrations_hooks.id)
#
class MoengageWebhookEventLog < ApplicationRecord
  belongs_to :account
  belongs_to :hook, class_name: 'Integrations::Hook'
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true

  enum :status, { pending: 0, success: 1, failed: 2, skipped: 3 }

  validates :account_id, presence: true
  validates :hook_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_event_name, ->(name) { where(event_name: name) if name.present? }
  scope :since, ->(date) { where('created_at >= ?', date) if date.present? }
  scope :until_date, ->(date) { where('created_at <= ?', date) if date.present? }

  # Clean up old logs (keep last 30 days by default)
  def self.cleanup_old_logs(days: 30)
    where('created_at < ?', days.days.ago).delete_all
  end
end
