# == Schema Information
#
# Table name: moengage_webhook_event_logs
#
#  id                  :bigint           not null, primary key
#  account_id          :bigint           not null
#  hook_id             :bigint           not null
#  event_name          :string
#  status              :integer          default("pending"), not null
#  payload             :jsonb
#  response_data       :jsonb
#  error_message       :text
#  contact_id          :bigint
#  conversation_id     :bigint
#  processing_time_ms  :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
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
