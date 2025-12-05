# == Schema Information
#
# Table name: campaigns
#
#  id                                 :bigint           not null, primary key
#  audience                           :jsonb
#  campaign_status                    :integer          default("active"), not null
#  campaign_type                      :integer          default("ongoing"), not null
#  description                        :text
#  enabled                            :boolean          default(TRUE)
#  message                            :text             not null
#  scheduled_at                       :datetime
#  template_params                    :jsonb
#  title                              :string           not null
#  trigger_only_during_business_hours :boolean          default(FALSE)
#  trigger_rules                      :jsonb
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  account_id                         :bigint           not null
#  display_id                         :integer          not null
#  inbox_id                           :bigint           not null
#  sender_id                          :integer
#
# Indexes
#
#  index_campaigns_on_account_id       (account_id)
#  index_campaigns_on_campaign_status  (campaign_status)
#  index_campaigns_on_campaign_type    (campaign_type)
#  index_campaigns_on_inbox_id         (inbox_id)
#  index_campaigns_on_scheduled_at     (scheduled_at)
#
class Campaign < ApplicationRecord
  include UrlHelper
  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :title, presence: true
  validates :message, presence: true, length: { maximum: Limits::CAMPAIGN_MESSAGE_MAX_LENGTH }
  validate :validate_campaign_inbox
  validate :validate_url
  validate :prevent_completed_campaign_from_update, on: :update
  validate :sender_must_belong_to_account
  validate :inbox_must_belong_to_account
  validate :validate_delay_configuration

  belongs_to :account
  belongs_to :inbox
  belongs_to :sender, class_name: 'User', optional: true

  enum campaign_type: { ongoing: 0, one_off: 1 }
  # TODO : enabled attribute is unneccessary . lets move that to the campaign status with additional statuses like draft, disabled etc.
  enum campaign_status: { active: 0, completed: 1 }

  has_many :conversations, dependent: :nullify, autosave: true

  before_validation :ensure_correct_campaign_attributes
  after_commit :set_display_id, unless: :display_id?

  def trigger!
    return unless one_off?
    return if completed?

    execute_campaign
  end

  # Calculate delay based on trigger_rules configuration
  def calculate_delay
    return 0 unless trigger_rules&.dig('delay')

    delay_config = trigger_rules['delay']
    delay_type_value = delay_config['type']

    case delay_type_value
    when 'fixed'
      delay_config['seconds'].to_i
    when 'random'
      min = delay_config['min'].to_i
      max = delay_config['max'].to_i
      rand(min..max)
    else
      0 # 'none' or missing
    end
  end

  # Get delay type for display
  def delay_type
    trigger_rules&.dig('delay', 'type') || 'none'
  end

  # Check if delay is configured
  def delay?
    delay_type != 'none'
  end

  private

  def execute_campaign
    case inbox.inbox_type
    when 'Twilio SMS'
      Twilio::OneoffSmsCampaignService.new(campaign: self).perform
    when 'Sms'
      Sms::OneoffSmsCampaignService.new(campaign: self).perform
    when 'Whatsapp'
      Whatsapp::OneoffCampaignService.new(campaign: self).perform if account.feature_enabled?(:whatsapp_campaign)
      # Whatsapp::OneoffWhatsappCampaignService.new(campaign: self).perform if inbox.inbox_type == 'Whatsapp'
    when 'API'
      Api::OneoffApiCampaignService.new(campaign: self).perform
    end
  end

  def set_display_id
    reload
  end

  def validate_campaign_inbox
    return unless inbox

    errors.add :inbox, 'Unsupported Inbox type' unless ['Website', 'Twilio SMS', 'Sms', 'Whatsapp', 'API'].include? inbox.inbox_type
  end

  # TO-DO we clean up with better validations when campaigns evolve into more inboxes
  def ensure_correct_campaign_attributes
    return if inbox.blank?

    if ['Twilio SMS', 'Sms', 'Whatsapp', 'API'].include?(inbox.inbox_type)
      self.campaign_type = 'one_off'
      self.scheduled_at ||= Time.now.utc
    else
      self.campaign_type = 'ongoing'
      self.scheduled_at = nil
    end
  end

  def validate_url
    return unless trigger_rules&.dig('url')

    use_http_protocol = trigger_rules['url'].starts_with?('http://') || trigger_rules['url'].starts_with?('https://')
    errors.add(:url, 'invalid') if inbox.inbox_type == 'Website' && !use_http_protocol
  end

  def inbox_must_belong_to_account
    return unless inbox

    return if inbox.account_id == account_id

    errors.add(:inbox_id, 'must belong to the same account as the campaign')
  end

  def sender_must_belong_to_account
    return unless sender

    return if account.users.exists?(id: sender.id)

    errors.add(:sender_id, 'must belong to the same account as the campaign')
  end

  def prevent_completed_campaign_from_update
    errors.add :status, 'The campaign is already completed' if !campaign_status_changed? && completed?
  end

  def validate_delay_configuration
    return unless trigger_rules&.dig('delay')

    delay_config = trigger_rules['delay']
    delay_type_value = delay_config['type']

    case delay_type_value
    when 'fixed'
      validate_fixed_delay(delay_config)
    when 'random'
      validate_random_delay(delay_config)
    when 'none', nil
      # No validation needed
    else
      errors.add(:trigger_rules, "Invalid delay type: #{delay_type_value}")
    end
  end

  def validate_fixed_delay(config)
    seconds = config['seconds'].to_i

    errors.add(:trigger_rules, 'Fixed delay must be between 0 and 300 seconds') if seconds.negative? || seconds > 300
  end

  def validate_random_delay(config)
    min = config['min'].to_i
    max = config['max'].to_i

    errors.add(:trigger_rules, 'Min delay must be between 0 and 300 seconds') if min.negative? || min > 300
    errors.add(:trigger_rules, 'Max delay must be between 0 and 300 seconds') if max.negative? || max > 300
    errors.add(:trigger_rules, 'Min delay must be less than or equal to max delay') if min > max
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end
end
