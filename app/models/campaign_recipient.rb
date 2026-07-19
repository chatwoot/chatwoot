# == Schema Information
#
# Table name: campaign_recipients
#
#  id            :bigint           not null, primary key
#  delivered_at  :datetime
#  error_message :text
#  failed_at     :datetime
#  phone_number  :string
#  read_at       :datetime
#  sent_at       :datetime
#  status        :integer          default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  campaign_id   :bigint           not null
#  contact_id    :bigint           not null
#  source_id     :string
#
class CampaignRecipient < ApplicationRecord
  belongs_to :campaign
  belongs_to :account
  belongs_to :contact

  enum status: { pending: 0, sent: 1, delivered: 2, read: 3, failed: 4, skipped: 5 }

  SUCCESS_RANK = {
    'pending' => 0,
    'sent' => 1,
    'delivered' => 2,
    'read' => 3
  }.freeze

  def mark_skipped!(reason)
    update!(status: :skipped, error_message: reason)
  end

  def mark_sent!(wamid)
    update!(status: :sent, source_id: wamid, sent_at: Time.current, error_message: nil)
  end

  def mark_failed!(reason)
    update!(status: :failed, error_message: reason, failed_at: Time.current)
  end

  def apply_whatsapp_status!(status_payload)
    new_status = status_payload[:status].to_s
    return unless %w[sent delivered read failed].include?(new_status)
    return if skipped?
    return if failed? && new_status != 'failed'
    return if success_downgrade?(new_status)

    attrs = { status: new_status }
    attrs[:sent_at] = Time.current if new_status == 'sent' && sent_at.blank?
    attrs[:delivered_at] = Time.current if new_status == 'delivered'
    attrs[:read_at] = Time.current if new_status == 'read'
    if new_status == 'failed'
      attrs[:failed_at] = Time.current
      error = status_payload[:errors]&.first
      attrs[:error_message] = "#{error[:code]}: #{error[:title]}" if error.present?
    end
    update!(attrs)
    campaign.refresh_execution_stats!
  end

  private

  def success_downgrade?(new_status)
    return false if new_status == 'failed'
    return false unless SUCCESS_RANK.key?(status) && SUCCESS_RANK.key?(new_status)

    SUCCESS_RANK[new_status] < SUCCESS_RANK[status]
  end
end
