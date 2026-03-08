class Appointments::CreateService
  attr_reader :conversation, :user, :event_type_uri, :event_type_name, :account

  def initialize(conversation:, event_type_uri:, event_type_name:, user: Current.user)
    @conversation = conversation
    @user = user
    @event_type_uri = event_type_uri
    @event_type_name = event_type_name
    @account = conversation.account
  end

  def perform
    validate_calendly_configuration!

    appointment = create_appointment_record
    begin
      link_data = create_calendly_scheduling_link
      update_with_scheduling_link(appointment, link_data)
      message = create_message(appointment)
      appointment.update!(message: message)

      Rails.logger.info("Appointment created successfully: #{appointment.id} via calendly")
      appointment
    rescue StandardError => e
      Rails.logger.error("Appointment creation failed: #{e.message}")
      appointment.update!(
        status: :cancelled,
        payload: appointment.payload.merge(error: e.message, failed_at: Time.current.iso8601)
      )
      raise
    end
  end

  private

  def validate_calendly_configuration!
    return if calendly_hook.present?

    raise ArgumentError, 'Calendly is not connected for this account. ' \
                         'Please connect Calendly in Settings → Integrations → Calendly.'
  end

  def calendly_hook
    @calendly_hook ||= account.hooks.find_by(app_id: 'calendly', status: 'enabled')
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(calendly_hook)
  end

  def create_appointment_record
    Appointment.create!(
      account: account,
      conversation: conversation,
      contact: conversation.contact,
      created_by: user,
      provider: 'calendly',
      status: :initiated,
      event_type_uri: event_type_uri,
      event_type_name: event_type_name,
      payload: { initiated_at: Time.current.iso8601 }
    )
  end

  def create_calendly_scheduling_link
    api_client.create_scheduling_link(event_type_uri, max_event_count: 1)
  end

  def update_with_scheduling_link(appointment, link_data)
    appointment.update!(
      scheduling_url: link_data['booking_url'],
      status: :pending,
      payload: appointment.payload.merge(
        calendly_link_data: link_data,
        link_created_at: Time.current.iso8601
      )
    )
  end

  def create_message(appointment)
    Messages::MessageBuilder.new(user, conversation, {
                                   content: "Book your appointment: #{appointment.scheduling_url}",
                                   message_type: :outgoing,
                                   content_type: :appointment,
                                   private: false,
                                   content_attributes: {
                                     data: {
                                       appointment_id: appointment.id,
                                       scheduling_url: appointment.scheduling_url,
                                       event_type_name: event_type_name,
                                       event_type_uri: event_type_uri,
                                       status: appointment.status,
                                       provider: 'calendly'
                                     }
                                   }
                                 }).perform
  end
end
