# == Schema Information
#
# Table name: conversation_with_labels
#
#  id                     :integer
#  additional_attributes  :jsonb
#  agent_last_seen_at     :datetime
#  assignee_last_seen_at  :datetime
#  contact_last_seen_at   :datetime
#  custom_attributes      :jsonb
#  first_reply_created_at :datetime
#  identifier             :string
#  labels_array           :string           is an Array
#  last_activity_at       :datetime
#  priority               :integer
#  snoozed_until          :datetime
#  status                 :integer
#  uuid                   :uuid
#  created_at             :datetime
#  updated_at             :datetime
#  account_id             :integer
#  assignee_id            :integer
#  campaign_id            :bigint
#  contact_id             :bigint
#  contact_inbox_id       :bigint
#  display_id             :integer
#  inbox_id               :integer
#  team_id                :bigint
#
# Indexes
#
#  idx_conv_labels_view__acc_id__status__last_activity  (account_id,status,last_activity_at)
#  index_conversation_with_labels_on_custom_attributes  (custom_attributes) USING gin
#  index_conversation_with_labels_on_id                 (id) UNIQUE
#  index_conversation_with_labels_on_labels_array       (labels_array) USING gin
#  index_conversation_with_labels_on_last_activity_at   (last_activity_at)
#
class ConversationWithLabel < ApplicationRecord
  self.primary_key = :id

  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :contact
  belongs_to :contact_inbox
  belongs_to :team, optional: true
  belongs_to :campaign, optional: true

  has_many :mentions
  has_many :messages
  has_one :csat_survey_response
  has_many :conversation_participants
  has_many :notifications, as: :primary_actor
  has_many :attachments, through: :messages

  scope :assigned_to, ->(agent) { where(assignee_id: agent.id) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :assigned, -> { where.not(assignee_id: nil) }
  scope :latest, -> { order(last_activity_at: :desc) }

  def self.refresh
    # https://github.com/scenic-views/scenic#what-about-materialized-views
    # needs atleast one unuque index for concurrent refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  def label_list
    labels_array
  end

  def muted?
    Redis::Alfred.get(mute_key).present?
  end

  def readonly?
    true
  end

  private

  def mute_key
    format(Redis::RedisKeys::CONVERSATION_MUTE_KEY, id: id)
  end
end
