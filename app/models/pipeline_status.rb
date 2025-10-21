# == Schema Information
#
# Table name: pipeline_statuses
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipeline_statuses_on_account_id  (account_id)
#
class PipelineStatus < ApplicationRecord
  # == Constants ============================================================
  # == Extensions ===========================================================
  # == Enums ================================================================
  # == Validations ===========================================================
  validates :name, presence: true

  # == Callbacks =====================================================
  before_save :set_name
  before_destroy :check_for_conversations

  # == Attributes ===========================================================
  # == Scopes ===============================================================
  default_scope { order(created_at: :asc) }

  # == Relationships ========================================================
  belongs_to :account
  has_many :conversations, dependent: :restrict_with_error

  # == Instance Methods =====================================================

  private

  def set_name
    self.name = name.downcase
  end

  def check_for_conversations
    return unless conversations.exists?

    errors.add(:base, 'Cannot delete pipeline status with assigned conversations')
    throw(:abort)
  end
end
