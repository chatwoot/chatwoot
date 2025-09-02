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
#  idx_on_account_id_name_language_channel_type_99a8ab867f  (account_id,name,language,channel_type) UNIQUE
#  index_message_templates_on_account_id                    (account_id)
#  index_message_templates_on_channel_type                  (channel_type)
#  index_message_templates_on_created_by_id                 (created_by_id)
#  index_message_templates_on_inbox_id                      (inbox_id)
#  index_message_templates_on_status                        (status)
#  index_message_templates_on_updated_by_id                 (updated_by_id)
#
class MessageTemplate < ApplicationRecord
  SUPPORTED_LANGUAGES = LANGUAGES_CONFIG.values.pluck(:iso_639_1_code).freeze

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :category, presence: true
  validates :channel_type, presence: true
  validates :name, presence: true,
                   length: { minimum: 2, maximum: 512 },
                   format: {
                     with: /\A[a-zA-Z0-9_]+\z/
                   }
  # NOTE: disable this for now as language config may not contain the lanugage created on meta
  # validates :language, inclusion: { in: SUPPORTED_LANGUAGES }
  validates :content, presence: true
  validate :validate_content
  validate :validate_inbox_belongs_to_account
  validate :validate_unique_template_name

  belongs_to :account
  belongs_to :inbox
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  enum status: {
    draft: 0,
    pending: 1,
    approved: 2,
    rejected: 3
  }

  enum category: {
    marketing: 0,
    utility: 1,
    authentication: 2
  }

  scope :by_channel_type, ->(type) { where(channel_type: type) }
  scope :by_language, ->(lang) { where(language: lang) }
  scope :by_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }
  scope :approved, -> { where(status: :approved) }

  before_save :set_updated_by
  before_create :create_on_provider_platform, unless: :platform_template_id?

  def whatsapp_template?
    channel_type == 'Channel::Whatsapp'
  end

  private

  def set_updated_by
    self.updated_by = Current.user if Current.user.present?
  end

  def validate_content
    return if content.blank?

    return errors.add(:channel_type, 'Not implemented') unless whatsapp_template?

    validate_whatsapp_content
  end

  def validate_whatsapp_content
    components = content['components']
    return errors.add(:content, 'Components are required') if components.blank?

    validate_whatsapp_components(components)
  end

  def validate_whatsapp_components(components)
    body_count = components.count { |c| c['type'] == 'BODY' }
    errors.add(:content, 'Must have exactly one BODY component') if body_count != 1
    # TODO: add header, footer and button components validation if need
  end

  def validate_inbox_belongs_to_account
    return if inbox_id.blank? || account_id.blank?
    return if inbox&.account_id == account_id

    errors.add(:inbox_id, 'does not belong to this account')
  end

  def validate_unique_template_name
    existing_template = account.message_templates
                               .where(name: name, language: language, inbox_id: inbox_id)
                               .where.not(id: id)
                               .exists?

    errors.add(:name, 'already exists for this language and inbox') if existing_template
  end

  def create_on_provider_platform
    case channel_type
    when 'Channel::Whatsapp'
      create_whatsapp_template
      # add more providers here
    end
  end

  def create_whatsapp_template
    provider_response = inbox.channel.provider_service.create_message_template(
      name: name,
      language: language,
      category: category.upcase,
      components: content['components']
    )

    Rails.logger.info "WhatsApp template creation response: #{provider_response.inspect}"

    self.platform_template_id = provider_response['id']
    self.status = provider_response['status']&.downcase || 'pending'
  rescue StandardError => e
    Rails.logger.error "WhatsApp template creation failed: #{e.message}"
    errors.add(:base, "Failed to create template on WhatsApp: #{e.message}")
    throw :abort
  end
end
