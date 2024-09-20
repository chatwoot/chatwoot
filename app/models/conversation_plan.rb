# == Schema Information
#
# Table name: conversation_plans
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  description     :string
#  snoozed_until   :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint
#  conversation_id :bigint           not null
#  created_by_id   :bigint           not null
#
# Indexes
#
#  index_conversation_plans_on_account_id       (account_id)
#  index_conversation_plans_on_contact_id       (contact_id)
#  index_conversation_plans_on_conversation_id  (conversation_id)
#  index_conversation_plans_on_created_by_id    (created_by_id)
#

class ConversationPlan < ApplicationRecord
  before_validation :ensure_account_id
  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :conversation_id, presence: true
  validates :created_by_id, presence: true
  validates :description, presence: true

  belongs_to :account
  belongs_to :contact
  belongs_to :conversation
  belongs_to :created_by, class_name: 'User'

  scope :completed, -> { where.not(completed_at: nil) }
  scope :latest, -> { order(created_at: :desc) }
  scope :incomplete, -> { where(completed_at: nil) }

  private

  def ensure_account_id
    self.account_id = contact&.account_id
  end
end
