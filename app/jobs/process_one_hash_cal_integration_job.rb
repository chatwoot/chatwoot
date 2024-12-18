class ProcessOneHashCalIntegrationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(integration_hook_id)
    hook = Integrations::Hook.find_by(id: integration_hook_id)
    Rails.logger.info "__ProcessOneHashCalIntegrationJob :Hook #{hook.inspect}"

    raise StandardError, "Hook not found with id #{integration_hook_id}" unless hook

    # Check if account_user is present
    @account_user = hook.account_user

    @account = @account_user.account

    @user = @account_user.user

    @contacts = @account&.contacts || []

    Rails.logger.info "Processing integration hook for app_id: #{hook.app_id}"

    process_hook_data(hook)
  end

  private

  def process_hook_data(hook)
    Rails.logger.info "__ProcessOneHashCalIntegrationJob :Hook Inside process_hook_data with cal_user_id #{hook.settings['cal_user_id']}"
    initial_data = get_initial_data_from_cal(hook.settings['cal_user_id'])
    if initial_data
      add_cal_event_to_user(initial_data['cal_events'], hook.account_id)
      add_user_past_bookings(initial_data['bookings'])
    else
      Rails.logger.error "Failed to fetch initial data from external API for hook_id: #{hook.id}"
    end

    Rails.logger.info "Hook processed: app_id=#{hook.app_id}, user_id=#{@user.id}"
  end

  def get_initial_data_from_cal(user_id)
    # TODO: CAL
    url = "#{ENV.fetch('ONEHASH_CAL_APP_ORIGIN_URL')}/api/integrations/oh/chat"
    # url = 'http://localhost:3001/api/integrations/oh/chat'

    auth_token = ENV.fetch('ONEHASH_API_KEY', nil)
    params = {
      account_user_id: @account_user.id,
      account_name: @account.name,
      user_name: @user.name,
      user_email: @user.email,
      user_id: user_id
    }

    # Encode params as query string
    query_string = params.to_query
    begin
      response = RestClient.get("#{url}?#{query_string}", {
                                  accept: :json,
                                  Authorization: "Bearer #{auth_token}"
                                })

      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Failed to fetch data from external API (status: #{e.http_code}): #{e.response}")
      nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error while fetching data: #{e.message}")
      nil
    end
  end

  def add_cal_event_to_user(cal_events, account_id)
    @user.custom_attributes ||= {}

    @user.custom_attributes['cal_events'] ||= {}

    @user.custom_attributes['cal_events'][account_id] = cal_events

    if @user.save
      Rails.logger.info "User #{@user.id}'s calendar events updated successfully."
    else
      Rails.logger.error "Failed to update user #{@user.id}'s custom attributes."
    end
  end

  def add_user_past_bookings(bookings)
    contact_lookup = build_contact_lookup

    contact_bookings_to_create = []

    bookings.each do |booking|
      contact = nil

      contact_lookup.each do |(contact_key, contact_value)|
        contact_email, contact_phone = contact_key

        if booking['bookerEmail'] == contact_email || booking['bookerPhone'] == contact_phone
          contact = contact_value
          break # No need to check further once we find a match
        end
      end

      next unless contact

      contact_bookings_to_create << build_booking_data(booking, contact)
    end
    if contact_bookings_to_create.any?
      create_contact_bookings_in_batches(contact_bookings_to_create)
    else
      Rails.logger.warn 'No valid bookings found to create.'
    end
  end

  def build_contact_lookup
    @contacts.index_by { |contact| [contact.email, contact.phone_number] }.compact
  end

  def build_booking_data(booking, contact)
    {
      user_id: @user.id,
      account_id: @account.id,
      contact_id: contact.id,
      host_name: booking['hostName'],
      booking_location: booking['bookingLocation'],
      booking_eventtype: booking['bookingEventType'],
      booking_startTime: booking['bookingStartTime'],
      booking_endTime: booking['bookingEndTime'],
      booking_uid: booking['bookingUid']
      # booking_status: booking['bookingStatus']
    }
  end

  def create_contact_bookings_in_batches(bookings)
    ContactBooking.transaction do
      bookings.in_groups_of(100, false) do |group|
        ContactBooking.create!(group)
      end
    end

    Rails.logger.info "#{bookings.size} contact bookings were created successfully."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create contact bookings: #{e.message}"
  end
end
