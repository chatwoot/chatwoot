# frozen_string_literal: true

class Appointment < ApplicationRecord
  include Discard::Model

  # Associations
  belongs_to :contact
  belongs_to :account
  belongs_to :owner, class_name: 'User'
  belongs_to :inbox, optional: true
  belongs_to :conversation, optional: true

  has_one_attached :qr_code

  # Enums
  enum appointment_type: {
    physical_visit: 0,
    digital_meeting: 1,
    phone_call: 2
  }

  enum status: {
    scheduled: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3,
    no_show: 4
  }

  # Validations
  validates :scheduled_at, presence: true
  validates :appointment_type, presence: true
  validates :status, presence: true
  validates :owner_id, presence: true
  validate :ended_at_after_scheduled_at
  validate :type_specific_fields
  validate :appointment_type_enabled
  validate :no_overlapping_appointments
  validate :within_owner_working_hours

  # Callbacks
  before_create :generate_access_token
  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event
  after_discard :dispatch_discard_event

  # Scopes
  scope :upcoming, -> { where('scheduled_at > ?', Time.current).where(status: :scheduled) }
  scope :past, -> { where('scheduled_at <= ?', Time.current) }
  scope :for_owner, ->(user_id) { where(owner_id: user_id) }
  scope :by_type, ->(type) { where(appointment_type: type) }
  scope :by_status, ->(status) { where(status: status) }

  # Instance methods
  def participant_agents
    User.where(id: participants['agent_ids'] || [])
  end

  def participant_contacts
    Contact.where(id: participants['contact_ids'] || [])
  end

  def duration
    return nil unless started_at && ended_at

    ((ended_at - started_at) / 60).to_i # En minutos
  end

  def start!
    update!(status: :in_progress, started_at: Time.current)
  end

  def complete!
    update!(
      status: :completed,
      ended_at: Time.current,
      duration_minutes: duration
    )
  end

  def cancel!
    update!(status: :cancelled)
  end

  def mark_no_show!
    update!(status: :no_show)
  end

  def external_id_for(provider)
    external_ids[provider.to_s]
  end

  def store_external_id(provider, external_id)
    self.external_ids ||= {}
    self.external_ids[provider.to_s] = external_id
    save!
  end

  private

  def ended_at_after_scheduled_at
    return if ended_at.blank? || scheduled_at.blank?

    errors.add(:ended_at, 'must be after scheduled time') if ended_at <= scheduled_at
  end

  def type_specific_fields
    case appointment_type
    when 'digital_meeting'
      errors.add(:meeting_url, 'is required for digital meetings') if meeting_url.blank?
    when 'phone_call'
      errors.add(:phone_number, 'is required for phone calls') if phone_number.blank?
    when 'physical_visit'
      errors.add(:location, 'is required for physical visits') if location.blank?
    end
  end

  def appointment_type_enabled
    return if appointment_type.blank? || account.blank?

    unless account.appointment_type_enabled?(appointment_type)
      errors.add(:appointment_type, "#{appointment_type} is not enabled for this account")
    end
  end

  def generate_access_token
    self.access_token = SecureRandom.urlsafe_base64(32)
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(
      'appointment.created',
      Time.zone.now,
      appointment: self
    )
  end

  def dispatch_update_event
    return unless saved_change_to_status?

    event_name = case status
                 when 'in_progress'
                   'appointment.started'
                 when 'completed'
                   'appointment.completed'
                 when 'cancelled'
                   'appointment.cancelled'
                 else
                   'appointment.updated'
                 end

    Rails.configuration.dispatcher.dispatch(
      event_name,
      Time.zone.now,
      appointment: self
    )
  end

  def dispatch_discard_event
    Rails.configuration.dispatcher.dispatch(
      'appointment.discarded',
      Time.zone.now,
      appointment: self
    )
  end

  def no_overlapping_appointments
    return if scheduled_at.blank? || owner_id.blank?

    appt_end = ended_at.presence || scheduled_at

    conflicting = Appointment
      .kept
      .where(owner_id: owner_id, status: [:scheduled, :in_progress])
      .where.not(id: id)
      .where('scheduled_at <= ? AND COALESCE(ended_at, scheduled_at) >= ?', appt_end, scheduled_at)
      .exists?

    errors.add(:scheduled_at, 'the advisor already has an appointment scheduled at this time') if conflicting
  end

  def within_owner_working_hours
    return if scheduled_at.blank? || owner_id.blank? || account.blank?

    account_user = account.account_users.find_by(user_id: owner_id)
    return unless account_user

    tz = account.business_hours_timezone.presence || account_user.timezone.presence || 'UTC'
    local_time = scheduled_at.in_time_zone(tz)
    working_hour = account_user.working_hours.find_by(day_of_week: local_time.wday)
    return unless working_hour
    return if working_hour.open_all_day?

    if working_hour.closed_all_day?
      errors.add(:scheduled_at, 'the advisor does not work on this day')
      return
    end

    open_time  = local_time.change(hour: working_hour.open_hour,  min: working_hour.open_minutes,  sec: 0)
    close_time = local_time.change(hour: working_hour.close_hour, min: working_hour.close_minutes, sec: 0)

    errors.add(:scheduled_at, 'the appointment time is outside the advisor working hours') unless local_time.between?(open_time, close_time)
  end
end
