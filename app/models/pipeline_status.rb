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
  enum pipeline_type: { conversation: 'conversation', contact: 'contact' }

  # == Validations ===========================================================
  validates :name, presence: true
  validates :name, uniqueness: { scope: [:account_id, :pipeline_type] }

  # == Callbacks =====================================================
  before_save :set_name
  before_create :set_position
  before_destroy :check_for_assigned_records

  # == Attributes ===========================================================
  # == Scopes ===============================================================
  default_scope { order(Arel.sql('position ASC NULLS LAST, created_at ASC')) }

  # == Relationships ========================================================
  belongs_to :account
  has_many :conversations, dependent: :restrict_with_error
  has_many :contacts, dependent: :restrict_with_error

  # == Instance Methods =====================================================

  private

  def set_name
    self.name = name.downcase
  end

  def set_position
    self.position = (account.pipeline_statuses.where(pipeline_type: pipeline_type).maximum(:position) || 0) + 1
  end

  def check_for_assigned_records
    if pipeline_type == 'conversation' && conversations.exists?
      errors.add(:base, 'Cannot delete pipeline status with assigned conversations')
      throw(:abort)
    elsif pipeline_type == 'contact' && contacts.exists?
      errors.add(:base, 'Cannot delete pipeline status with assigned contacts')
      throw(:abort)
    end
  end
end
