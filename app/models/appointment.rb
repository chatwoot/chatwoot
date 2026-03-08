# == Schema Information
#
# Table name: appointments
#
#  id                :bigint           not null, primary key
#  event_type_name   :string
#  event_type_uri    :string
#  payload           :jsonb            not null
#  provider          :string           not null
#  scheduled_at      :datetime
#  scheduling_url    :string
#  status            :integer          default("initiated"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  contact_id        :bigint           not null
#  conversation_id   :bigint           not null
#  created_by_id     :bigint           not null
#  external_event_id :string
#  message_id        :bigint
#
# Indexes
#
#  index_appointments_on_account_id         (account_id)
#  index_appointments_on_contact_id         (contact_id)
#  index_appointments_on_conversation_id    (conversation_id)
#  index_appointments_on_created_by_id      (created_by_id)
#  index_appointments_on_external_event_id  (external_event_id) UNIQUE
#  index_appointments_on_message_id         (message_id)
#  index_appointments_on_provider           (provider)
#  index_appointments_on_scheduled_at       (scheduled_at)
#  index_appointments_on_status             (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (message_id => messages.id)
#
class Appointment < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :contact
  belongs_to :created_by, class_name: 'User', inverse_of: :created_appointments
  belongs_to :message, optional: true

  after_update :sync_message_status, if: :saved_change_to_status?

  enum status: {
    initiated: 0,
    pending: 1,
    scheduled: 2,
    completed: 3,
    cancelled: 4,
    no_show: 5
  }

  validates :provider, presence: true
  validates :external_event_id, uniqueness: true, allow_nil: true
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :contact_id, presence: true
  validates :created_by_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :upcoming, -> { where(status: :scheduled).where('scheduled_at > ?', Time.current).order(scheduled_at: :asc) }
  scope :for_contact, ->(contact_id) { where(contact_id: contact_id) if contact_id.present? }
  scope :filter_by_conversation, ->(conversation_id) { where(conversation_id: conversation_id) if conversation_id.present? }
  scope :search, lambda { |query|
    return all if query.blank?

    joins(:contact).where(
      'appointments.event_type_name ILIKE :q OR contacts.name ILIKE :q',
      q: "%#{query}%"
    )
  }

  def mark_as_scheduled!(event_data = {})
    update!(
      status: :scheduled,
      scheduled_at: event_data[:start_time],
      external_event_id: event_data[:event_id],
      payload: payload.merge(
        scheduled_at_raw: event_data[:start_time],
        invitee_data: event_data[:invitee],
        event_callback: event_data
      )
    )
  end

  def mark_as_cancelled!(callback_data = {})
    update!(
      status: :cancelled,
      payload: payload.merge(
        cancelled_at: Time.current.iso8601,
        cancel_callback: callback_data
      )
    )
  end

  def mark_as_completed!
    update!(
      status: :completed,
      payload: payload.merge(completed_at: Time.current.iso8601)
    )
  end

  def mark_as_no_show!
    update!(
      status: :no_show,
      payload: payload.merge(no_show_at: Time.current.iso8601)
    )
  end

  private

  def sync_message_status
    return if message.blank?

    message_data = message.content_attributes[:data] || {}
    updated_data = message_data.merge(status: status, scheduled_at: scheduled_at&.iso8601)

    message.update!(
      content_attributes: message.content_attributes.merge(data: updated_data)
    )
  end
end
