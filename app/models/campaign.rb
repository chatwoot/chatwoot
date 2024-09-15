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
#  flexible_scheduled_at              :jsonb
#  inboxes                            :jsonb
#  is_zns                             :boolean          default(FALSE), not null
#  message                            :text
#  planned                            :boolean          default(FALSE), not null
#  private_note                       :text
#  received_count                     :integer          default(0), not null
#  scheduled_at                       :datetime
#  sent_count                         :integer          default(0), not null
#  title                              :string           not null
#  trigger_only_during_business_hours :boolean          default(FALSE)
#  trigger_rules                      :jsonb
#  zns_template_data                  :jsonb
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  account_id                         :bigint           not null
#  display_id                         :integer          not null
#  inbox_id                           :bigint
#  sender_id                          :integer
#  zns_template_id                    :text
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
  validates :title, presence: true
  validate :validate_campaign_inbox
  validate :validate_url
  validate :prevent_completed_campaign_from_update, on: :update
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :sender, class_name: 'User', optional: true

  enum campaign_type: { ongoing: 0, one_off: 1, flexible: 2 }
  # TODO : enabled attribute is unneccessary . lets move that to the campaign status with additional statuses like draft, disabled etc.
  enum campaign_status: { active: 0, completed: 1 }

  has_many :conversations, dependent: :nullify, autosave: true

  after_commit :set_display_id, unless: :display_id?

  def trigger!
    return if ongoing?
    return if completed?

    Campaign::MultiChannelCampaignService.new(campaign: self).perform
  end

  private

  def set_display_id
    reload
  end

  def validate_campaign_inbox
    return unless inbox

    errors.add :inbox, 'Unsupported Inbox type' if ongoing? && inbox.inbox_type != 'Website'

    errors.add :inbox, 'Unsupported Inbox type' if is_zns && inbox.inbox_type != 'ZaloOa'
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
