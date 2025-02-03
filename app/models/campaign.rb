# == Schema Information
#
# Table name: campaigns
#
#  id                                 :bigint           not null, primary key
#  audience                           :jsonb
#  campaign_status                    :integer          default("draft"), not null
#  campaign_type                      :integer          default("ongoing"), not null
#  description                        :text
#  enabled                            :boolean          default(TRUE)
#  failed_contacts_count              :integer          default(0)
#  message                            :text             not null
#  processed_contacts_count           :integer          default(0)
#  read_count                         :integer          default(0)
#  scheduled_at                       :datetime
#  title                              :string           not null
#  trigger_only_during_business_hours :boolean          default(FALSE)
#  trigger_rules                      :jsonb
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  account_id                         :bigint           not null
#  display_id                         :integer          not null
#  inbox_id                           :bigint           not null
#  sender_id                          :integer
#  template_id                        :bigint
#
# Indexes
#
#  index_campaigns_on_account_id       (account_id)
#  index_campaigns_on_campaign_status  (campaign_status)
#  index_campaigns_on_campaign_type    (campaign_type)
#  index_campaigns_on_inbox_id         (inbox_id)
#  index_campaigns_on_scheduled_at     (scheduled_at)
#  index_campaigns_on_template_id      (template_id)
#
class Campaign < ApplicationRecord
  include UrlHelper

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :title, presence: true
  validates :message, presence: true, unless: :whatsapp_campaign? # Message not required for WhatsApp
  validates :template_id, presence: true, if: :whatsapp_campaign? # Template required for WhatsApp
  validates :scheduled_at, presence: true, if: :scheduled_campaign?
  validate :validate_campaign_inbox
  validate :validate_url
  validate :prevent_completed_campaign_from_update, on: :update

  belongs_to :account
  belongs_to :inbox
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :template, optional: true

  has_many :conversations, dependent: :nullify, autosave: true
  has_many :campaign_contacts, dependent: :destroy
  has_many :contacts, through: :campaign_contacts

  enum campaign_type: { ongoing: 0, one_off: 1, whatsapp: 2 }
  enum campaign_status: { draft: 0, active: 1, completed: 2, scheduled: 3 }

  before_validation :ensure_correct_campaign_attributes
  after_commit :set_display_id, unless: :display_id?

  def pending_contacts
    contacts.joins(:campaign_contacts).where(campaign_contacts: { status: 'pending', campaign_id: self.id })
  end

  def processed_contacts
    contacts.joins(:campaign_contacts).where(campaign_contacts: { status: 'processed', campaign_id: self.id })
  end
  
  def failed_contacts
    contacts.joins(:campaign_contacts).where(campaign_contacts: { status: 'failed', campaign_id: self.id })
  end
  
  def delivered_contacts
    contacts.joins(:campaign_contacts).where(campaign_contacts: { status: 'delivered', campaign_id: self.id })
  end

  # New Methods for Read and Replied Contacts
  def read_contacts
    contacts.joins(:campaign_contacts).where(campaign_contacts: { status: 'read', campaign_id: self.id })
  end

  def replied_contacts
    contacts.joins(:campaign_contacts).where(campaign_contacts: { status: 'replied', campaign_id: self.id })
  end

  def processing?
    campaign_status == 'active'
  end
  
  def complete?
    campaign_contacts.where(status: ['pending']).empty?
  end
  

  def trigger!
    return if completed?

    case inbox.inbox_type
    when 'Twilio SMS'
      return unless one_off?

      Twilio::OneoffSmsCampaignService.new(campaign: self).perform
    when 'Sms'
      return unless one_off?

      Sms::OneoffSmsCampaignService.new(campaign: self).perform
    when 'Whatsapp'
      return unless whatsapp?

      Whatsapp::WhatsappCampaignService.new(campaign: self).perform
    end
  end

  def whatsapp_campaign?
    inbox&.inbox_type == 'Whatsapp'
  end

  def scheduled_campaign?
    scheduled_at.present?
  end

  private

  def set_display_id
    reload
  end

  def validate_campaign_inbox
    return unless inbox

    return if ['Website', 'Twilio SMS', 'Sms', 'Whatsapp'].include? inbox.inbox_type

    errors.add :inbox, 'Unsupported Inbox type'
  end

  def ensure_correct_campaign_attributes
    return if inbox.blank?

    case inbox.inbox_type
    when 'Twilio SMS', 'Sms'
      self.campaign_type = 'one_off'
      self.scheduled_at ||= Time.now.utc
    when 'Whatsapp'
      self.campaign_type = 'whatsapp'
      self.scheduled_at ||= Time.now.utc
      # Only set campaign_status to scheduled if it's a new record or status is nil
      self.campaign_status = 'scheduled' if scheduled_at.present? && (new_record? || campaign_status.nil?)
      self.message = "WhatsApp Campaign: #{title}"
    else
      self.campaign_type = 'ongoing'
      self.scheduled_at = nil
    end
  end

  def validate_url
    return unless trigger_rules['url']

    use_http_protocol = trigger_rules['url'].starts_with?('http://') || trigger_rules['url'].starts_with?('https://')
    errors.add(:url, 'invalid') if inbox.inbox_type == 'Website' && !use_http_protocol
  end

  def prevent_completed_campaign_from_update
    errors.add :status, 'The campaign is already completed' if !campaign_status_changed? && completed?
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end
end
