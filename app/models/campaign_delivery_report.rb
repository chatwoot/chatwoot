# == Schema Information
#
# Table name: campaign_delivery_reports
#
#  id           :bigint           not null, primary key
#  campaign_id  :bigint           not null
#  provider     :string
#  status       :string           default("pending"), not null
#  total        :integer          default(0), not null
#  succeeded    :integer          default(0), not null
#  failed       :integer          default(0), not null
#  errors       :jsonb            default([]), not null
#  started_at   :datetime
#  completed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_campaign_delivery_reports_on_campaign_id  (campaign_id) UNIQUE
#  index_campaign_delivery_reports_on_status       (status)
#

class CampaignDeliveryReport < ApplicationRecord
  belongs_to :campaign

  # Delivery status (independent of campaign_status)
  # pending: delivery not started
  # running: delivery in progress
  # completed: all messages sent successfully
  # completed_with_errors: some messages failed
  STATUSES = %w[pending running completed completed_with_errors].freeze

  validates :status, inclusion: { in: STATUSES }

  # Add an error to the deduped errors array
  # Errors are deduped by signature (code + message + details)
  def record_error(code:, message:, details: nil, fbtrace_id: nil)
    signature = build_signature(code, message, details)
    existing = errors.find { |e| e['signature'] == signature }

    if existing
      existing['count'] += 1
      existing['last_fbtrace_id'] = fbtrace_id if fbtrace_id.present?
      existing['last_seen_at'] = Time.current.iso8601
    else
      errors << {
        'signature' => signature,
        'code' => code,
        'message' => message,
        'details' => details,
        'count' => 1,
        'last_fbtrace_id' => fbtrace_id,
        'last_seen_at' => Time.current.iso8601
      }
    end
  end

  def errors?
    failed.positive?
  end

  def finalize!
    self.completed_at = Time.current
    self.status = errors? ? 'completed_with_errors' : 'completed'
    save!
  end

  private

  def build_signature(code, message, details)
    [code, message, details].compact.join('|')
  end
end
