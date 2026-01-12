# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_message_mappings
#
#  id                          :bigint           not null, primary key
#  campaign_delivery_report_id :bigint           not null
#  contact_id                  :bigint           not null
#  whatsapp_message_id         :string           not null
#  status                      :string           default("sent"), not null
#  error_code                  :string
#  error_message               :string
#  error_details               :text
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_campaign_message_mappings_on_campaign_delivery_report_id  (campaign_delivery_report_id)
#  index_campaign_message_mappings_on_contact_id                   (contact_id)
#  index_campaign_message_mappings_on_status                       (status)
#  index_campaign_message_mappings_on_whatsapp_message_id          (whatsapp_message_id) UNIQUE
#

class CampaignMessageMapping < ApplicationRecord
  belongs_to :campaign_delivery_report
  belongs_to :contact

  validates :whatsapp_message_id, presence: true, uniqueness: true
  validates :status, presence: true

  # Update status from webhook and sync with delivery report
  def update_from_webhook(status:, errors: nil)
    previous_status = self.status
    self.status = status

    extract_error_from_webhook(errors) if status == 'failed' && errors.present?
    save!

    sync_failure_to_report if status == 'failed' && previous_status != 'failed'
  end

  private

  def extract_error_from_webhook(errors)
    error = errors.first
    self.error_code = error[:code] || error['code']
    self.error_message = error[:title] || error['title'] || error[:message] || error['message']
    self.error_details = error.dig(:error_data, :details) || error.dig('error_data', 'details')
  end

  def sync_failure_to_report
    report = campaign_delivery_report
    return unless report

    report.succeeded -= 1 if report.succeeded.positive?
    report.failed += 1
    report.record_error(code: error_code, message: error_message, details: error_details)
    report.status = 'completed_with_errors' if report.status == 'completed'
    report.save!
  end
end
