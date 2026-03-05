# == Schema Information
#
# Table name: integrations_webhook_logs
#
#  id            :bigint           not null, primary key
#  error_message :text
#  event_type    :string           not null
#  payload       :jsonb
#  processed_at  :datetime
#  response_data :jsonb
#  status        :integer          default("received"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hook_id       :bigint           not null
#
# Indexes
#
#  index_integrations_webhook_logs_on_created_at              (created_at)
#  index_integrations_webhook_logs_on_hook_id                 (hook_id)
#  index_integrations_webhook_logs_on_hook_id_and_created_at  (hook_id,created_at)
#  index_integrations_webhook_logs_on_status                  (status)
#
# Foreign Keys
#
#  fk_rails_...  (hook_id => integrations_hooks.id)
#
class Integrations::WebhookLog < ApplicationRecord
  self.table_name = 'integrations_webhook_logs'

  belongs_to :hook, class_name: 'Integrations::Hook'

  enum status: { received: 0, processing: 1, processed: 2, failed: 3 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(s) { where(status: s) }
  scope :by_event_type, ->(type) { where(event_type: type) }

  def mark_processing!
    update!(status: :processing)
  end

  def mark_processed!(data = {})
    update!(status: :processed, response_data: data, processed_at: Time.current)
  end

  def mark_failed!(message)
    update!(status: :failed, error_message: message, processed_at: Time.current)
  end
end
