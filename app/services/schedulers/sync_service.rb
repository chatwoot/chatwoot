class Schedulers::SyncService
  def initialize(account)
    @account = account
  end

  def perform
    # Phase 2: Replace with actual CRM API call
    # For now, this service processes messages pushed via the API endpoint
    # or can generate mock data in development
    sync_from_mock if Rails.env.development? && @account.schedulers.enabled.any?
  end

  # Public method to process messages from CRM webhook/API
  def process_messages(messages)
    messages.each do |message_data|
      process_message(message_data)
    rescue StandardError => e
      Rails.logger.error "Failed to process scheduled message #{message_data['external_id']}: #{e.message}"
    end
  end

  private

  def process_message(data)
    scheduler = @account.schedulers.enabled.find_by(message_type: data['message_type'])
    return unless scheduler

    phone = normalize_phone(data['customer_phone'])
    contact = @account.contacts.find_by(phone_number: phone)

    message = ScheduledMessage.find_or_initialize_by(
      external_id: data['external_id'],
      message_type: data['message_type']
    )

    # Don't update already sent/failed messages
    return if %w[sent failed].include?(message.status)

    message.assign_attributes(
      account: @account,
      scheduler: scheduler,
      contact: contact,
      customer_phone: phone,
      customer_name: data['customer_name'],
      scheduled_at: Time.zone.parse(data['scheduled_at'].to_s),
      metadata: data['metadata'] || {},
      template_params: data['template_params'] || {}
    )
    message.save!
  end

  def normalize_phone(phone)
    return phone if phone&.match?(/\+[1-9]\d{1,14}\z/)

    "+#{phone.to_s.gsub(/[^0-9]/, '')}"
  end

  def sync_from_mock
    mock_messages = generate_mock_appointments
    process_messages(mock_messages)
  end

  def generate_mock_appointments
    base_time = 1.day.from_now.beginning_of_day + 10.hours
    scheduler_types = @account.schedulers.enabled.pluck(:message_type)

    scheduler_types.flat_map do |type|
      [{
        'external_id' => "mock-#{SecureRandom.hex(4)}",
        'message_type' => type,
        'customer_phone' => '+821012345678',
        'customer_name' => 'Mock Patient',
        'scheduled_at' => (base_time + rand(1..72).hours).iso8601,
        'metadata' => {
          'appointment_type' => 'Consultation',
          'location' => 'Gangnam Clinic 3F',
          'doctor' => 'Dr. Kim'
        }
      }]
    end
  end
end
