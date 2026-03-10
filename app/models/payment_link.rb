class PaymentLink < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :user, optional: true

  validates :order_nsu, presence: true, uniqueness: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }

  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }

  def paid?
    status == 'paid'
  end

  def mark_as_paid!(payload)
    update!(
      status: 'paid',
      invoice_slug: payload['invoice_slug'],
      transaction_nsu: payload['transaction_nsu'],
      capture_method: payload['capture_method'],
      paid_amount_cents: payload['paid_amount'],
      receipt_url: payload['receipt_url'],
      webhook_payload: payload
    )
  end
end
