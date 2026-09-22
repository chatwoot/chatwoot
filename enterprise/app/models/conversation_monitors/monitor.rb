class ConversationMonitors::Monitor < ApplicationRecord
  self.table_name = 'conversation_monitors'

  belongs_to :account
  belongs_to :creator, class_name: 'User', optional: true
  has_many :evaluations, class_name: 'ConversationMonitors::Evaluation', dependent: :delete_all, inverse_of: :monitor
  has_many :scans, class_name: 'ConversationMonitors::Scan', dependent: :delete_all, inverse_of: :monitor

  validates :name, presence: true, length: { maximum: 100 }
  validates :condition, presence: true, length: { maximum: 2000 }
  validates :model, :history_since, presence: true
  validates :threshold, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  attr_readonly :model, :threshold, :history_since, :account_id

  scope :visible, -> { where(deleted_at: nil) }
  scope :active, -> { visible.where(paused_at: nil) }

  def initial_scan
    scans.find_by!(kind: 'initial')
  end

  def collecting?
    paused_at.nil? && deleted_at.nil? && ConversationMonitors::Configuration.enabled?(account)
  end

  def resumable?
    paused_at.present? && deleted_at.nil?
  end

  def matched_conversations
    account.conversations.where(id: evaluations.where(status: 'matched').select(:conversation_id))
  end

  def eligible_activity?(work, evaluation)
    return true if evaluation&.requested_version == collection_version
    return false unless work.activity_at
    return true if work.activity_at >= (resumed_at || created_at)
    return false unless resumed_at

    scans.where(collection_version: collection_version, kind: 'catch_up')
         .exists?(['started_at <= ? AND ended_at > ?', work.activity_at, work.activity_at])
  end
end
