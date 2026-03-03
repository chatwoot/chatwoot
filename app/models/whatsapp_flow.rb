# == Schema Information
#
# Table name: whatsapp_flows
#
#  id                :bigint           not null, primary key
#  account_id        :bigint           not null
#  inbox_id          :bigint           not null
#  created_by_id     :bigint
#  name              :string(255)      not null
#  status            :integer          default("draft"), not null
#  flow_id           :string(255)
#  categories        :jsonb            default([])
#  flow_json         :jsonb            default({})
#  validation_errors :jsonb            default([])
#  preview_url       :string
#  endpoint_uri      :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class WhatsappFlow < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :created_by, class_name: 'User', optional: true

  enum :status, { draft: 0, published: 1, deprecated: 2, blocked: 3, throttled: 4 }

  validates :name, presence: true, length: { maximum: 255 }
  validates :flow_json, presence: true

  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }

  # Returns the screens from the flow JSON
  def screens
    flow_json['screens'] || []
  end

  # Returns the flow version
  def version
    flow_json['version'] || '6.0'
  end

  def published?
    status == 'published'
  end

  def can_publish?
    draft? && flow_id.present? && screens.any?
  end

  def can_edit?
    draft?
  end
end
