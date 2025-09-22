class Webhooks::InstagramEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 1.second, attempts: 8

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message, :read].freeze

  def perform(entries)

    # Step 1: Parse JSON string if needed
    parsed_entries = entries.is_a?(String) ? JSON.parse(entries) : entries

    # Step 2: Normalize to array of hashes
    parsed_entries = [parsed_entries] if parsed_entries.is_a?(Hash)

    # Step 3: Allow indifferent access to keys
    @entries = parsed_entries.map(&:with_indifferent_access)

    # Step 4: Normalize each entry to have :messaging key if it looks like a direct message payload
    @entries = @entries.map do |entry|
      if entry[:messaging].blank? && (entry[:sender].present? || entry[:message].present?)
        # Wrap the entry itself inside :messaging array for consistent processing downstream
        { messaging: [entry] }.with_indifferent_access
      else
        entry
      end
    end


    return if @entries.blank?


    # Step 5: Build a Redis mutex key (fallback to 'unknown' if sender_id or ig_account_id nil)
    key = format(::Redis::Alfred::IG_MESSAGE_MUTEX, sender_id: sender_id || 'unknown', ig_account_id: ig_account_id || 'unknown')

    with_lock(key) do
      process_entries(@entries)
    end
  end

  def process_entries(entries)
    entries.each do |entry|
      process_single_entry(entry)
    end
  end

  private

  def process_single_entry(entry)
    if test_event?(entry)
      process_test_event(entry)
      return
    end

    process_messages(entry)
  end

  def process_messages(entry)
    messages(entry).each do |messaging|
      Rails.logger.info("Instagram Events Job Messaging: #{messaging}")

      instagram_id_val = instagram_id(messaging)
      channel = find_channel(instagram_id_val)

      next if channel.blank?

      if (event_name_val = event_name(messaging))
        send(event_name_val, messaging, channel)
      end
    end
  end

  def messages(entry)
    # Return the messaging array if present
    return entry[:messaging] if entry[:messaging].present?

    # If no messaging but it looks like a single message payload, wrap it in array
    if entry[:message].present? || entry[:sender].present?
      [entry]
    else
      entry[:standby] || []
    end
  end

  def agent_message_via_echo?(messaging)
    messaging[:message].present? && messaging[:message][:is_echo].present?
  end

  def test_event?(entry)
    entry[:changes].present?
  end

  def process_test_event(entry)
    messaging = extract_messaging_from_test_event(entry)

    Instagram::TestEventService.new(messaging).perform if messaging.present?
  end

  def extract_messaging_from_test_event(entry)
    entry[:changes].first&.dig(:value) if entry[:changes].present?
  end

  def instagram_id(messaging)
    if agent_message_via_echo?(messaging)
      messaging[:sender][:id]
    else
      messaging[:recipient][:id]
    end
  end

  def ig_account_id
    # Try normal key
    id = @entries.dig(0, :id)
    return id if id.present?

    # fallback - no id available
    nil
  end

  def sender_id
    # Try extracting sender id from messaging array if present
    id = @entries.dig(0, :messaging, 0, :sender, :id)
    return id if id.present?

    # fallback to top-level sender id if messaging not present
    id = @entries.dig(0, :sender, :id)
    return id if id.present?

    nil
  end

  def find_channel(instagram_id)
    # Priority: Instagram channel (via Instagram login)
    channel = Channel::Instagram.find_by(instagram_id: instagram_id)

    # Fallback: Facebook Page channel (linked Instagram)
    channel = Channel::FacebookPage.find_by(instagram_id: instagram_id) if !channel.present?

    channel
  end

  def event_name(messaging)
    SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging, channel)
    if channel.is_a?(Channel::Instagram)
      ::Instagram::MessageText.new(messaging, channel).perform
    else
      ::Instagram::Messenger::MessageText.new(messaging, channel).perform
    end
  end

  def read(messaging, channel)
    ::Instagram::ReadStatusService.new(params: messaging, channel: channel).perform
  end
end
