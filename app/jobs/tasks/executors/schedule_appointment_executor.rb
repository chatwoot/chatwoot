# frozen_string_literal: true

class Tasks::Executors::ScheduleAppointmentExecutor
  def initialize(task)
    @task = task
  end

  def call
    appt_data = @task.execution_config['appointment_data'] || {}
    return if appt_data['contact_id'].blank? || appt_data['scheduled_at'].blank?

    contact = @task.account.contacts.find_by(id: appt_data['contact_id'])
    return unless contact

    contact.appointments.create!(
      account: @task.account,
      appointment_type: appt_data['appointment_type'],
      scheduled_at: appt_data['scheduled_at'],
      owner_id: appt_data['owner_id'],
      status: :scheduled,
      phone_number: appt_data['phone_number'].presence,
      meeting_url: appt_data['meeting_url'].presence,
      location: appt_data['location'].presence
    )
  end
end
