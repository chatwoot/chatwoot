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
  validates :message, presence: true
  validate :validate_campaign_inbox
  validate :validate_url
  validate :prevent_completed_campaign_from_update, on: :update
  validate :sender_must_belong_to_account
  validate :inbox_must_belong_to_account

  belongs_to :account
  belongs_to :inbox
  belongs_to :sender, class_name: 'User', optional: true

  enum campaign_type: { ongoing: 0, one_off: 1 }
  # TODO : enabled attribute is unneccessary . lets move that to the campaign status with additional statuses like draft, disabled etc.
  enum campaign_status: { active: 0, completed: 1, processing: 2 }

  has_many :conversations, dependent: :nullify, autosave: true

  before_validation :ensure_correct_campaign_attributes
  after_commit :set_display_id, unless: :display_id?
  after_destroy_commit :invalidate_filtered_unread_count_filters

  def trigger!
    return unless one_off?
    return unless feature_enabled?
    return unless mark_processing!

    execute_campaign
  end

  private

  def feature_enabled?
    !inbox.whatsapp? || account.feature_enabled?(:whatsapp_campaign)
  end

  def mark_processing!
    # Multiple scheduler jobs can pick the same active campaign; lock before flipping status to avoid duplicate sends.
    with_lock do
      next if completed? || processing?

      processing!
    end
  end

  def execute_campaign
    # Kiraid: campaign channel abstraction. Dispatch runs through the strategy
    # registry (Campaigns::ChannelStrategy) so adding a new campaign channel is a
    # one-line addition there — no model/controller change. Channels with no send
    # path raise CustomExceptions::Campaigns::UnsupportedInboxType (loud failure,
    # not silent skip).
    Campaigns::ChannelStrategy.for(inbox).execute(self)
  end

  def invalidate_filtered_unread_count_filters
    filters_changed = ::Conversations::UnreadCounts::FilteredCountInvalidator.new(account).conversation_changed!
    dispatch_account_cache_invalidated if filters_changed
  end

  def dispatch_account_cache_invalidated
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CACHE_INVALIDATED, Time.zone.now, account: account, cache_keys: account.cache_keys)
  end

  def set_display_id
    reload
  end

  # Kiraid: campaign channel abstraction. The allowed inbox types and their
  # outbound send paths live in Campaigns::ChannelStrategy — this validation only
  # checks that the inbox is a known campaign channel. Remove the abstraction by
  # reverting to the hardcoded allow-list in Campaigns::ChannelStrategy's removal
  # notes.
  def validate_campaign_inbox
    return unless inbox

    return if Campaigns::ChannelStrategy.for(inbox).campaignable?

    errors.add :inbox, 'Unsupported Inbox type'
  end

  # Kiraid: campaign channel abstraction. Whether a channel runs one_off (outbound)
  # vs ongoing (on-page trigger) is derived from Campaigns::ChannelStrategy instead
  # of a hardcoded list.
  def ensure_correct_campaign_attributes
    return if inbox.blank?

    if Campaigns::ChannelStrategy.for(inbox).one_off?
      self.campaign_type = 'one_off'
      self.scheduled_at ||= Time.now.utc
    else
      self.campaign_type = 'ongoing'
      self.scheduled_at = nil
    end
  end

  def validate_url
    return unless trigger_rules['url']

    use_http_protocol = trigger_rules['url'].starts_with?('http://') || trigger_rules['url'].starts_with?('https://')
    errors.add(:url, 'invalid') if inbox.web_widget? && !use_http_protocol
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

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end
end
