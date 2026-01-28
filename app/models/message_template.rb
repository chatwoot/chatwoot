# == Schema Information
#
# Table name: message_templates
#
#  id                   :bigint           not null, primary key
#  category             :integer          default("marketing"), not null
#  channel_type         :string(50)       not null
#  content              :jsonb            not null
#  language             :string(10)       default("en"), not null
#  last_synced_at       :datetime
#  metadata             :jsonb
#  name                 :string(512)      not null
#  parameter_format     :integer
#  status               :integer          default("draft")
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
  attr_accessor :skip_provider_sync

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

  enum parameter_format: {
    positional: 0,
    named: 1
  }

  scope :by_channel_type, ->(type) { where(channel_type: type) }
  scope :by_language, ->(lang) { where(language: lang) }
  scope :by_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }
  scope :by_status, ->(status) { where(status: status) }

  before_save :set_updated_by

  before_create :create_on_provider_platform, unless: :platform_template_id?
  after_create :sync_templates_from_provider_with_delay
  before_destroy :delete_on_provider_platform
  after_destroy :sync_templates_from_provider

  def whatsapp_template?
    channel_type == 'Channel::Whatsapp'
  end

  private

  def set_updated_by
    self.updated_by = Current.user if Current.user.present?
  end

  def validate_inbox_belongs_to_account
    return if inbox_id.blank? || account_id.blank?
    return if inbox&.account_id == account_id

    errors.add(:inbox_id, 'does not belong to this account')
  end

  def validate_unique_template_name
    return if account.blank?

    existing_template = account.message_templates
                               .where(name: name, language: language, inbox_id: inbox_id)
                               .where.not(id: id)
                               .exists?

    errors.add(:name, 'already exists for this language and inbox') if existing_template
  end

  def create_on_provider_platform
    case channel_type
    when 'Channel::Whatsapp'
      service = Whatsapp::TemplateCreationService.new(message_template: self)
      throw :abort unless service.call
    end
  end

  def sync_templates_from_provider_with_delay
    enqueue_template_sync(wait: 5.minutes)
  end

  def sync_templates_from_provider
    enqueue_template_sync
  end

  def enqueue_template_sync(wait: nil)
    return if skip_provider_sync
    return unless inbox&.channel

    channel = inbox.channel
    # only whatsapp is supported for now
    return unless channel.is_a?(Channel::Whatsapp)

    if wait
      Channels::Whatsapp::TemplatesSyncJob.set(wait: wait).perform_later(channel)
    else
      Channels::Whatsapp::TemplatesSyncJob.perform_later(channel)
    end
  end

  def delete_on_provider_platform
    case channel_type
    when 'Channel::Whatsapp'
      return unless inbox&.channel.is_a?(Channel::Whatsapp)

      inbox.channel.provider_service.delete_message_template(platform_template_id, name)
    end
  end
end
