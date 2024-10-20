# == Schema Information
#
# Table name: conversation_plans
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  description     :string
#  replied         :boolean          default(FALSE), not null
#  snoozed_until   :datetime
#  status          :integer          default("todo"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint
#  conversation_id :bigint           not null
#  created_by_id   :bigint
#
# Indexes
#
#  index_conversation_plans_on_account_id       (account_id)
#  index_conversation_plans_on_contact_id       (contact_id)
#  index_conversation_plans_on_conversation_id  (conversation_id)
#  index_conversation_plans_on_created_by_id    (created_by_id)
#

class ConversationPlan < ApplicationRecord
  enum status: { todo: 0, doing: 1, done: 2 }
  before_validation :ensure_account_id
  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :conversation_id, presence: true

  belongs_to :account
  belongs_to :contact
  belongs_to :conversation
  belongs_to :created_by, class_name: 'User', optional: true

  scope :completed, -> { where(status: :done) }
  scope :latest, -> { order(created_at: :desc) }
  scope :incomplete, -> { where.not(status: :done) }

  private

  def ensure_account_id
    self.account_id = contact&.account_id
  end
end
