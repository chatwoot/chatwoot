# == Schema Information
#
# Table name: meta_campaign_interactions
#
#  id               :bigint           not null, primary key
#  ctwa_clid        :string
#  interaction_type :string           default("initial_message")
#  metadata         :jsonb
#  source_type      :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  conversation_id  :bigint           not null
#  inbox_id         :bigint           not null
#  message_id       :bigint           not null
#  source_id        :string           not null
#
# Indexes
#
#  index_meta_campaign_interactions_on_account_id                (account_id)
#  index_meta_campaign_interactions_on_account_id_and_source_id  (account_id,source_id)
#  index_meta_campaign_interactions_on_conversation_id           (conversation_id)
#  index_meta_campaign_interactions_on_created_at                (created_at)
#  index_meta_campaign_interactions_on_inbox_id                  (inbox_id)
#  index_meta_campaign_interactions_on_inbox_id_and_source_id    (inbox_id,source_id)
#  index_meta_campaign_interactions_on_message_id                (message_id) UNIQUE
#  index_meta_campaign_interactions_on_source_id                 (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#  fk_rails_...  (message_id => messages.id)
#
class MetaCampaignInteraction < ApplicationRecord
  belongs_to :inbox
  belongs_to :account
  belongs_to :conversation
  belongs_to :message

  validates :source_id, presence: true
  validates :interaction_type, presence: true
  validates :message_id, uniqueness: true

  scope :for_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }
  scope :for_campaign, ->(source_id) { where(source_id: source_id) }
  scope :created_between, ->(start_time, end_time) { where(created_at: start_time..end_time) }

  # Get unique campaigns for an inbox
  def self.campaigns_for_inbox(inbox_id)
    where(inbox_id: inbox_id)
      .select('DISTINCT ON (source_id) *')
      .order(:source_id, created_at: :desc)
  end

  # Get interaction count by campaign
  def self.stats_by_campaign(account_id, inbox_id = nil, start_time = nil, end_time = nil)
    query = where(account_id: account_id)
    query = query.where(inbox_id: inbox_id) if inbox_id.present?
    query = query.created_between(start_time, end_time) if start_time && end_time

    # Use a subquery to get the first metadata for each campaign
    query.group(:source_id, :source_type)
         .select('source_id,
                  source_type,
                  COUNT(*) as interaction_count,
                  (SELECT metadata FROM meta_campaign_interactions mci
                   WHERE mci.source_id = meta_campaign_interactions.source_id
                   AND mci.metadata IS NOT NULL
                   LIMIT 1) as campaign_metadata,
                  MIN(created_at) as first_interaction,
                  MAX(created_at) as last_interaction')
  end
end
