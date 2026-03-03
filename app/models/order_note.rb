# == Schema Information
#
# Table name: order_notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  order_id   :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_order_notes_on_account_id  (account_id)
#  index_order_notes_on_order_id    (order_id)
#  index_order_notes_on_user_id     (user_id)
#
class OrderNote < ApplicationRecord
  before_validation :ensure_account_id
  validates :content, presence: true
  validates :account_id, presence: true
  validates :order_id, presence: true

  belongs_to :account
  belongs_to :order
  belongs_to :user, optional: true

  scope :latest, -> { order(created_at: :desc) }

  private

  def ensure_account_id
    self.account_id = order&.account_id
  end
end
