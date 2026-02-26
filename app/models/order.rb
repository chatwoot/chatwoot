class Order < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :message, optional: true
  belongs_to :contact
  belongs_to :created_by, polymorphic: true

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  before_validation :generate_external_payment_id
  before_validation :calculate_totals
  after_update :sync_message_status, if: :saved_change_to_status?
  after_update :restore_stock_on_terminal_status, if: :saved_change_to_status?
  after_update :send_order_notification_email, if: :became_paid?

  enum status: {
    initiated: 0,
    pending: 1,
    paid: 2,
    failed: 3,
    expired: 4,
    cancelled: 5
  }

  validates :external_payment_id, uniqueness: true, presence: true
  validates :payment_url, presence: true, unless: -> { initiated? || failed? }
  validates :provider, presence: true
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :contact_id, presence: true
  validates :created_by_id, presence: true

  accepts_nested_attributes_for :order_items, allow_destroy: true

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :filter_by_created_at, ->(range) { where(created_at: range) if range.present? }
  scope :search, lambda { |query|
    return all if query.blank?

    joins(:contact).where(
      'orders.external_payment_id ILIKE :q OR contacts.name ILIKE :q',
      q: "%#{query}%"
    )
  }
  scope :order_on_created_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"orders\".\"created_at\" #{direction} NULLS LAST")
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

  def amount
    total
  end

  def paid_at
    payload['paid_at'] ? Time.zone.parse(payload['paid_at']) : nil
  end

  def customer_data
    payload['customer_data'] || {}
  end

  def preview_url
    Rails.application.routes.url_helpers.order_preview_url(id: external_payment_id)
  end

  private

  def generate_external_payment_id
    return if external_payment_id.present?

    loop do
      self.external_payment_id = SecureRandom.hex(5)
      break unless Order.exists?(external_payment_id: external_payment_id)
    end
  end

  def calculate_totals
    return if order_items.blank?

    self.subtotal = order_items.sum { |item| item.unit_price.to_d * item.quantity.to_i }
    self.total = subtotal
  end

  def restore_stock_on_terminal_status
    return unless failed? || cancelled? || expired?

    order_items.includes(:product).find_each do |item|
      item.product.restore_stock!(item.quantity)
    end
  end

  def sync_message_status
    return if message.blank?

    message_data = message.content_attributes[:data] || message.content_attributes['data'] || {}
    updated_data = message_data.merge('status' => status)

    message.update!(
      content_attributes: message.content_attributes.merge('data' => updated_data)
    )
  end

  def became_paid?
    saved_change_to_status? && paid?
  end

  def send_order_notification_email
    emails = account.catalog_settings&.notification_email_list
    return if emails.blank?

    AdministratorNotifications::AccountNotificationMailer
      .with(account: account)
      .order_paid(self, emails)
      .deliver_later
  end
end
