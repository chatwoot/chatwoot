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
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
require 'uri'
class Campaign < ApplicationRecord
  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :title, presence: true
  validates :message, presence: true
  validate :validate_campaign_inbox
  validate :validate_url
  validate :prevent_completed_campaign_from_update, on: :update
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

    Twilio::OneoffSmsCampaignService.new(campaign: self).perform if inbox.inbox_type == 'Twilio SMS'
    Sms::OneoffSmsCampaignService.new(campaign: self).perform if inbox.inbox_type == 'Sms'
  end

  private

  def set_display_id
    reload
  end

  def validate_campaign_inbox
    return unless inbox

    errors.add :inbox, 'Unsupported Inbox type' unless ['Website', 'Twilio SMS', 'Sms'].include? inbox.inbox_type
  end

  # TO-DO we clean up with better validations when campaigns evolve into more inboxes
  def ensure_correct_campaign_attributes
    return if inbox.blank?

    if ['Twilio SMS', 'Sms'].include?(inbox.inbox_type)
      self.campaign_type = 'one_off'
      self.scheduled_at ||= Time.now.utc
    else
      self.campaign_type = 'ongoing'
      self.scheduled_at = nil
    end
  end

  def validate_url
    return unless trigger_rules['url']

    errors.add(:url, 'invalid') if inbox.inbox_type == 'Website' && !url_valid?(trigger_rules['url'])
  end

  def url_valid?(url)
    url = begin
      URI.parse(url)
    rescue StandardError
      false
    end
    url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS)
  end

  def prevent_completed_campaign_from_update
    errors.add :status, 'The campaign is already completed' if !campaign_status_changed? && completed?
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end
end
