# frozen_string_literal: true

# == Schema Information
#
# Table name: scheduled_messages
#
#  id                     :bigint           not null, primary key
#  account_id             :bigint           not null
#  conversation_id        :bigint           not null
#  inbox_id               :bigint           not null
#  sender_id              :bigint
#  message_id             :bigint
#  content                :text             not null
#  message_type           :integer          default("outgoing"), not null
#  content_type           :integer          default("text"), not null
#  content_attributes     :json
#  additional_attributes  :jsonb
#  private                :boolean          default(FALSE), not null
#  scheduled_at           :datetime         not null
#  sent_at                :datetime
#  cancelled_at           :datetime
#  status                 :integer          default("pending"), not null
#  error_message          :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class ScheduledMessage < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :conversation
  belongs_to :inbox
  belongs_to :sender, class_name: 'User'
  belongs_to :message, optional: true

  # Enums
  enum status: { pending: 0, sent: 1, failed: 2, cancelled: 3 }
  enum message_type: { incoming: 0, outgoing: 1, activity: 2, template: 3 }
  enum content_type: {
    text: 0,
    input_text: 1,
    input_textarea: 2,
    input_email: 3,
    input_select: 4,
    cards: 5,
    form: 6,
    article: 7,
    incoming_email: 8,
    input_csat: 9,
    integrations: 10,
    sticker: 11
  }

  # Validations
  validates :content, presence: true, length: { maximum: 150_000 }
  validates :scheduled_at, presence: true
  validate :scheduled_at_in_future, on: :create
  validate :conversation_must_be_accessible

  # Scopes
  scope :due, -> { pending.where('scheduled_at <= ?', Time.current) }
  scope :upcoming, -> { pending.where('scheduled_at > ?', Time.current) }
  scope :by_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }

  # Callbacks
  before_validation :ensure_defaults
  after_create :notify_scheduled

  # Instance Methods
  def due?
    pending? && scheduled_at <= Time.current
  end

  def cancel!
    return false unless pending?

    update!(status: :cancelled, cancelled_at: Time.current)
  end

  def send_now!
    return false unless pending?

    ScheduledMessages::SendJob.perform_later(id)
  end

  def mark_as_sent!(message)
    update!(
      status: :sent,
      message_id: message.id,
      sent_at: Time.current
    )
  end

  def mark_as_failed!(error)
    update!(
      status: :failed,
      error_message: error.to_s
    )
  end

  private

  def ensure_defaults
    self.message_type ||= :outgoing
    self.content_type ||= :text
    self.inbox_id ||= conversation&.inbox_id
    self.account_id ||= conversation&.account_id
  end

  def scheduled_at_in_future
    return if scheduled_at.blank?
    return if scheduled_at > Time.current

    errors.add(:scheduled_at, 'must be in the future')
  end

  def conversation_must_be_accessible
    return if conversation.blank?
    return if conversation.account_id == account_id

    errors.add(:conversation_id, 'must belong to the same account')
  end

  def notify_scheduled
    # Pode adicionar webhook ou notificação aqui no futuro
    Rails.logger.info "ScheduledMessage #{id} created for conversation #{conversation_id} at #{scheduled_at}"
  end
end
