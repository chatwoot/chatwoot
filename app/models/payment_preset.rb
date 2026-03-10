class PaymentPreset < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
end
