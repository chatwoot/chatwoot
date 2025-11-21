# == Schema Information
#
# Table name: payment_links
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(10, 2)   not null
#  currency            :string           not null
#  payload             :jsonb            not null
#  payment_url         :string
#  provider            :string           not null
#  status              :integer          default("initiated"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  contact_id          :bigint           not null
#  conversation_id     :bigint           not null
#  created_by_id       :bigint           not null
#  external_payment_id :string
#  message_id          :bigint
#
# Indexes
#
#  index_payment_links_on_account_id           (account_id)
#  index_payment_links_on_contact_id           (contact_id)
#  index_payment_links_on_conversation_id      (conversation_id)
#  index_payment_links_on_created_by_id        (created_by_id)
#  index_payment_links_on_external_payment_id  (external_payment_id) UNIQUE
#  index_payment_links_on_message_id           (message_id)
#  index_payment_links_on_provider             (provider)
#  index_payment_links_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (message_id => messages.id)
#
class PaymentLink < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :message, optional: true
  belongs_to :contact
  belongs_to :created_by, class_name: 'User', inverse_of: :created_payment_links

  before_validation :generate_external_payment_id
  after_update :sync_message_status, if: :saved_change_to_status?

  enum status: {
    initiated: 0,
    pending: 1,
    paid: 2,
    failed: 3,
    expired: 4,
    cancelled: 5
  }

  validates :external_payment_id, uniqueness: true, presence: true
  validates :payment_url, presence: true, unless: :initiated?
  validates :provider, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :contact_id, presence: true
  validates :created_by_id, presence: true

  scope :for_contact, ->(contact_id) { where(contact_id: contact_id) if contact_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :filter_by_created_at, ->(range) { where(created_at: range) if range.present? }
  scope :filter_by_conversation, ->(conversation_id) { where(conversation_id: conversation_id) if conversation_id.present? }
  scope :search, lambda { |query|
    return all if query.blank?

    joins(:contact).where(
      'payment_links.external_payment_id ILIKE :q OR contacts.name ILIKE :q',
      q: "%#{query}%"
    )
  }
  scope :filter_by_amount_range, lambda { |min, max|
    return all if min.blank? && max.blank?
    return where('amount >= ?', min) if max.blank?
    return where('amount <= ?', max) if min.blank?

    where(amount: min..max)
  }
  scope :order_on_created_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"payment_links\".\"created_at\" #{direction} NULLS LAST")
      )
    )
  }
  scope :order_on_contact_name, lambda { |direction|
    joins(:contact).order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"name\" #{direction} NULLS LAST")
      )
    )
  }

  def mark_as_paid!(callback_data = {})
    update!(
      status: :paid,
      payload: payload.merge(
        paid_at: Time.current.iso8601,
        payment_callback: callback_data
      )
    )
  end

  def mark_as_failed!(callback_data = {})
    update!(
      status: :failed,
      payload: payload.merge(
        failed_at: Time.current.iso8601,
        payment_callback: callback_data
      )
    )
  end

  def mark_as_expired!
    update!(
      status: :expired,
      payload: payload.merge(expired_at: Time.current.iso8601)
    )
  end

  def mark_as_cancelled!(callback_data = {})
    update!(
      status: :cancelled,
      payload: payload.merge(
        cancelled_at: Time.current.iso8601,
        payment_callback: callback_data
      )
    )
  end

  # Helper method to get paid_at from payload
  def paid_at
    payload['paid_at'] ? Time.zone.parse(payload['paid_at']) : nil
  end

  # Helper to get customer data from payload
  def customer_data
    payload['customer_data'] || {}
  end

  private

  def generate_external_payment_id
    return if external_payment_id.present?

    loop do
      self.external_payment_id = SecureRandom.hex(8)
      break unless PaymentLink.exists?(external_payment_id: external_payment_id)
    end
  end

  def sync_message_status
    return if message.blank?

    message_data = message.content_attributes[:data] || {}
    updated_data = message_data.merge(status: status)

    message.update!(
      content_attributes: message.content_attributes.merge(data: updated_data)
    )
  end
end
