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
