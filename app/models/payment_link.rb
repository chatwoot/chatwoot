# == Schema Information
#
# Table name: payment_links
#
#  id              :bigint           not null, primary key
#  amount          :decimal(10, 2)   not null
#  currency        :string           default("KWD"), not null
#  customer_data   :jsonb
#  expires_at      :datetime
#  paid_at         :datetime
#  payment_url     :string           not null
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint           not null
#  conversation_id :bigint           not null
#  created_by_id   :bigint           not null
#  message_id      :bigint           not null
#  payment_id      :string           not null
#  track_id        :string           not null
#
# Indexes
#
#  index_payment_links_on_account_id       (account_id)
#  index_payment_links_on_contact_id       (contact_id)
#  index_payment_links_on_conversation_id  (conversation_id)
#  index_payment_links_on_created_by_id    (created_by_id)
#  index_payment_links_on_message_id       (message_id) UNIQUE
#  index_payment_links_on_payment_id       (payment_id) UNIQUE
#  index_payment_links_on_status           (status)
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
  belongs_to :message
  belongs_to :contact
  belongs_to :created_by, class_name: 'User', inverse_of: :created_payment_links

  enum status: {
    pending: 0,
    paid: 1,
    failed: 2,
    expired: 3,
    cancelled: 4
  }

  validates :payment_id, presence: true, uniqueness: true
  validates :payment_url, presence: true
  validates :track_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :message_id, presence: true, uniqueness: true
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
      'payment_links.payment_id ILIKE :q OR payment_links.track_id ILIKE :q OR contacts.name ILIKE :q',
      q: "%#{query}%"
    )
  }
  scope :filter_by_amount_range, lambda { |min, max|
    return all if min.blank? && max.blank?
    return where('amount >= ?', min) if max.blank?
    return where('amount <= ?', max) if min.blank?

    where(amount: min..max)
  }

  def mark_as_paid!
    update!(status: :paid, paid_at: Time.current)
  end

  def mark_as_failed!
    update!(status: :failed)
  end

  def mark_as_expired!
    update!(status: :expired)
  end

  def mark_as_cancelled!
    update!(status: :cancelled)
  end
end
