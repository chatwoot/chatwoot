# == Schema Information
#
# Table name: message_templates
#
#  id                   :bigint           not null, primary key
#  category             :integer          default(0), not null
#  channel_type         :string(50)       not null
#  content              :jsonb            not null
#  language             :string(10)       default("en"), not null
#  last_synced_at       :datetime
#  metadata             :jsonb
#  name                 :string(255)      not null
#  status               :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  created_by_id        :bigint
#  inbox_id             :bigint
#  platform_template_id :string(255)
#  updated_by_id        :bigint
#
# Indexes
#
#  idx_message_templates_unique_per_account  (account_id,name,language,channel_type) UNIQUE
#  index_message_templates_on_account_id     (account_id)
#  index_message_templates_on_channel_type   (channel_type)
#  index_message_templates_on_created_by_id  (created_by_id)
#  index_message_templates_on_inbox_id       (inbox_id)
#  index_message_templates_on_status         (status)
#  index_message_templates_on_updated_by_id  (updated_by_id)
#

class MessageTemplate < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  # Categories mirror Meta's WhatsApp template categories
  enum :category, { marketing: 0, utility: 1, authentication: 2 }, prefix: true

  # Status tracks the template lifecycle through Meta's approval process
  enum :status, { draft: 0, pending: 1, approved: 2, rejected: 3, paused: 4, disabled: 5 }, prefix: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, format: { with: /\A[a-z0-9_]+\z/, message: 'must contain only lowercase letters, numbers, and underscores' } # rubocop:disable Rails/I18nLocaleTexts
  validates :language, presence: true, length: { maximum: 10 }
  validates :channel_type, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: [:account_id, :language, :channel_type], message: 'already exists for this language and channel' } # rubocop:disable Rails/I18nLocaleTexts

  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }
  scope :by_channel_type, ->(channel_type) { where(channel_type: channel_type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :approved_whatsapp, -> { where(channel_type: 'Channel::Whatsapp', status: :approved) }

  # Returns the components array stored in the content JSONB
  def components
    content['components'] || []
  end

  # Returns the body text from the template components
  def body_text
    body = components.find { |c| c['type'] == 'BODY' }
    body&.dig('text')
  end

  # Returns the header component if present
  def header
    components.find { |c| c['type'] == 'HEADER' }
  end

  # Returns the footer component if present
  def footer
    components.find { |c| c['type'] == 'FOOTER' }
  end

  # Returns the buttons component if present
  def buttons
    btn = components.find { |c| c['type'] == 'BUTTONS' }
    btn&.dig('buttons') || []
  end

  # Extract variable placeholders ({{1}}, {{2}}, etc.) from body text
  def body_variables
    return [] unless body_text

    body_text.scan(/\{\{(\d+)\}\}/).flatten.map(&:to_i).sort
  end

  # Build a hash compatible with the legacy message_templates JSONB format
  # used by Channel::Whatsapp for backward compatibility
  def to_legacy_format
    {
      'id' => platform_template_id || id.to_s,
      'name' => name,
      'language' => language,
      'status' => status.upcase,
      'category' => category.upcase,
      'components' => components
    }
  end
end
