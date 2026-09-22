class ConversationMonitors::Monitor < ApplicationRecord
  self.table_name = 'conversation_monitors'

  belongs_to :account
  belongs_to :creator, class_name: 'User', optional: true
  has_many :evaluations, class_name: 'ConversationMonitors::Evaluation', dependent: :delete_all, inverse_of: :monitor
  has_one :backfill, class_name: 'ConversationMonitors::Backfill', dependent: :destroy, inverse_of: :monitor
  has_many :resumptions, class_name: 'ConversationMonitors::Resumption', dependent: :delete_all

  validates :name, presence: true, length: { maximum: 100 }
  validates :condition, presence: true, length: { maximum: 2000 }
  validates :model, :history_since, presence: true
  validates :threshold, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  attr_readonly :model, :threshold, :context_version, :history_since, :account_id

  scope :visible, -> { where(deleted_at: nil) }
  scope :active, -> { visible.where(archived_at: nil, paused_at: nil) }

  def collecting?
    archived_at.nil? && paused_at.nil? && deleted_at.nil? && account.feature_enabled?('conversation_monitors')
  end

  def resumable?
    paused_at.present? && archived_at.nil? && deleted_at.nil?
  end

  def matched_conversations
    account.conversations.where(id: evaluations.where(status: 'matched').select(:conversation_id))
  end

  def eligible_activity?(work, evaluation)
    return true unless resumed_at
    return true if evaluation&.requested_version == collection_version
    return false unless work.activity_at
    return true if work.activity_at >= resumed_at

    resumptions.where(collection_version: collection_version, mode: 'catch_up')
               .exists?(['started_at <= ? AND ended_at > ?', work.activity_at, work.activity_at])
  end
end
