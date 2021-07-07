# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  audience      :jsonb
#  campaign_type :integer          default("ongoing"), not null
#  description   :text
#  enabled       :boolean          default(TRUE)
#  locked        :boolean          default(FALSE), not null
#  message       :text             not null
#  title         :string           not null
#  trigger_rules :jsonb
#  trigger_time  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  display_id    :integer          not null
#  inbox_id      :bigint           not null
#  sender_id     :integer
#
# Indexes
#
#  index_campaigns_on_account_id  (account_id)
#  index_campaigns_on_inbox_id    (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class Campaign < ApplicationRecord
  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :title, presence: true
  validates :message, presence: true
  validate :validate_campaign_inbox
  validate :prevent_locked_record_from_update, on: :update
  belongs_to :account
  belongs_to :inbox
  belongs_to :sender, class_name: 'User', optional: true

  enum campaign_type: { ongoing: 0, one_off: 1 }

  has_many :conversations, dependent: :nullify, autosave: true

  before_validation :ensure_correct_campaign_attributes
  after_commit :set_display_id, unless: :display_id?

  private

  def set_display_id
    reload
  end

  def validate_campaign_inbox
    return unless inbox

    errors.add :inbox, 'Unsupported Inbox type' unless ['Website', 'Twilio SMS'].include? inbox.inbox_type
  end

  # TO-DO we clean up with better validations when campaigns evolve into more inboxes
  def ensure_correct_campaign_attributes
    return if inbox.blank?

    if inbox.inbox_type == 'Twilio SMS'
      self.campaign_type = 'one_off'
      self.trigger_time ||= Time.now.utc
    else
      self.campaign_type = 'ongoing'
      self.trigger_time = nil
    end
  end

  def prevent_locked_record_from_update
    errors.add :locked, 'The campaign is locked' if locked
  end

  # creating db triggers
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end
end
