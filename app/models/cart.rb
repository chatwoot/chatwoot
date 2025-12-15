# == Schema Information
#
# Table name: carts
#
#  id                  :bigint           not null, primary key
#  currency            :string           not null
#  payload             :jsonb            not null
#  payment_url         :string
#  provider            :string           not null
#  status              :integer          default("initiated"), not null
#  subtotal            :decimal(10, 2)   not null
#  total               :decimal(10, 2)   not null
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
#  index_carts_on_account_id           (account_id)
#  index_carts_on_contact_id           (contact_id)
#  index_carts_on_conversation_id      (conversation_id)
#  index_carts_on_created_by_id        (created_by_id)
#  index_carts_on_external_payment_id  (external_payment_id) UNIQUE
#  index_carts_on_message_id           (message_id)
#  index_carts_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (message_id => messages.id)
#
class Cart < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :message, optional: true
  belongs_to :contact
  belongs_to :created_by, class_name: 'User', inverse_of: :created_carts

  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  before_validation :generate_external_payment_id
  before_validation :calculate_totals
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
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :contact_id, presence: true
  validates :created_by_id, presence: true

  accepts_nested_attributes_for :cart_items, allow_destroy: true

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :filter_by_created_at, ->(range) { where(created_at: range) if range.present? }
  scope :search, lambda { |query|
    return all if query.blank?

    joins(:contact).where(
      'carts.external_payment_id ILIKE :q OR contacts.name ILIKE :q',
      q: "%#{query}%"
    )
  }
  scope :order_on_created_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"carts\".\"created_at\" #{direction} NULLS LAST")
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

  def paid_at
    payload['paid_at'] ? Time.zone.parse(payload['paid_at']) : nil
  end

  def customer_data
    payload['customer_data'] || {}
  end

  private

  def generate_external_payment_id
    return if external_payment_id.present?

    loop do
      self.external_payment_id = SecureRandom.hex(8)
      break unless Cart.exists?(external_payment_id: external_payment_id)
    end
  end

  def calculate_totals
    return if cart_items.blank?

    self.subtotal = cart_items.sum { |item| item.unit_price.to_d * item.quantity.to_i }
    self.total = subtotal
  end

  def sync_message_status
    return if message.blank?

    message_data = message.content_attributes[:data] || message.content_attributes['data'] || {}
    updated_data = message_data.merge('status' => status)

    message.update!(
      content_attributes: message.content_attributes.merge('data' => updated_data)
    )
  end
end
