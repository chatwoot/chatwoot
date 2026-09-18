class Seeders::WhatsappHistorySyncSeeder
  HISTORY_SOURCE = 'whatsapp_history_sync'.freeze
  INBOX_NAME = 'WhatsApp History Sync Test'.freeze
  MAX_CONVERSATIONS = 10
  DELIVERY_COUNTS = [3, 4].freeze

  Result = Data.define(:inbox, :sync, :events)

  def initialize(account:, conversation_count: MAX_CONVERSATIONS, delivery_count: 4)
    raise 'WhatsApp history sync seeding is only available in development.' unless Rails.env.development?

    @account = account
    @conversation_count = Integer(conversation_count)
    @delivery_count = Integer(delivery_count)
    validate_options!
  end

  def perform!
    inbox = find_or_create_inbox
    reset_history!(inbox)
    @sync = create_sync(inbox.channel)
    payloads = history_payloads

    payloads.each { |payload| deliver(payload) }
    deliver(payloads.first) # Meta retries are expected; this must remain idempotent.

    Result.new(inbox: inbox, sync: sync.reload, events: sync.events.order(:id).to_a)
  end

  private

  attr_reader :account, :conversation_count, :delivery_count, :sync

  def validate_options!
    raise ArgumentError, "CONVERSATIONS must be between 1 and #{MAX_CONVERSATIONS}" unless conversation_count.between?(1, MAX_CONVERSATIONS)
    raise ArgumentError, 'DELIVERIES must be 3 or 4' unless DELIVERY_COUNTS.include?(delivery_count)
  end

  def find_or_create_inbox
    inbox = account.inboxes.find_by(name: INBOX_NAME)
    return verify_test_inbox!(inbox) if inbox

    channel = create_channel
    account.inboxes.create!(name: INBOX_NAME, channel: channel).tap do |created_inbox|
      created_inbox.add_members(account.users.ids) if account.users.exists?
    end
  end

  def verify_test_inbox!(inbox)
    channel = inbox.channel
    marker = channel.is_a?(Channel::Whatsapp) && channel.provider_config['history_sync_test_setup']
    raise "Inbox named #{INBOX_NAME.inspect} already exists but was not created by this setup" unless marker

    inbox
  end

  def create_channel
    existing = Channel::Whatsapp.find_by(phone_number: business_phone_number)
    raise "Phone number #{business_phone_number} already belongs to another inbox" if existing

    result = Channel::Whatsapp.insert_all!([channel_attributes], returning: %w[id]) # rubocop:disable Rails/SkipsModelValidations
    Channel::Whatsapp.find(result.rows.first.first)
  end

  def channel_attributes
    now = Time.current
    {
      account_id: account.id,
      phone_number: business_phone_number,
      provider: 'whatsapp_cloud',
      provider_config: {
        'api_key' => 'whatsapp-history-sync-test-token',
        'business_account_id' => "history-sync-test-waba-#{account.id}",
        'phone_number_id' => phone_number_id,
        'source' => 'embedded_signup',
        'webhook_verify_token' => SecureRandom.hex(16),
        'history_sync_test_setup' => true
      },
      message_templates: [],
      phone_number_health: {},
      created_at: now,
      updated_at: now
    }
  end

  def reset_history!(inbox)
    conversation_ids = inbox.conversations
                            .where("additional_attributes ->> 'source' = ?", HISTORY_SOURCE)
                            .ids

    Message.where(conversation_id: conversation_ids).delete_all if conversation_ids.any?
    Conversation.where(id: conversation_ids).delete_all if conversation_ids.any?

    sync = inbox.channel.whatsapp_history_sync
    return unless sync

    WhatsappHistorySyncEvent.where(whatsapp_history_sync_id: sync.id).delete_all
    sync.destroy!
  end

  def create_sync(channel)
    sync = channel.create_whatsapp_history_sync!(status: :requested, started_at: Time.current)
    sync.update!(request_id: "history-sync-test-request-#{sync.id}")
    sync
  end

  def history_payloads
    specs = delivery_specs
    groups = (1..conversation_count).to_a.in_groups(specs.size, false)

    payloads = specs.zip(groups).map do |spec, conversation_indexes|
      threads = conversation_indexes.map { |index| history_thread(index, spec[:phase]) }
      history_payload(spec, threads)
    end

    payloads.values_at(*delivery_order)
  end

  def delivery_specs
    return three_delivery_specs if delivery_count == 3

    [
      { phase: 0, chunk_order: 1, progress: 25 },
      { phase: 1, chunk_order: 1, progress: 50 },
      { phase: 1, chunk_order: 2, progress: 75 },
      { phase: 2, chunk_order: 1, progress: 100 }
    ]
  end

  def three_delivery_specs
    [
      { phase: 0, chunk_order: 1, progress: 33 },
      { phase: 1, chunk_order: 1, progress: 66 },
      { phase: 2, chunk_order: 1, progress: 100 }
    ]
  end

  def delivery_order
    delivery_count == 4 ? [2, 0, 1, 3] : [1, 0, 2]
  end

  def history_payload(spec, threads)
    {
      object: 'whatsapp_business_account',
      entry: [{
        id: "history-sync-test-waba-#{account.id}",
        changes: [{
          field: 'history',
          value: {
            messaging_product: 'whatsapp',
            metadata: {
              display_phone_number: business_phone_number,
              phone_number_id: phone_number_id
            },
            history: [{ metadata: spec, threads: threads }]
          }
        }]
      }]
    }
  end

  def history_thread(index, phase)
    contact_number = format('1415555%04d', index)
    timestamp = history_timestamp(index, phase)

    {
      id: contact_number,
      messages: [
        history_message(id: "#{index}.1", sender: contact_number, timestamp: timestamp,
                        body: 'I need help with a previous order.', status: 'READ'),
        history_message(id: "#{index}.2", sender: business_phone_number.delete_prefix('+'), timestamp: timestamp + 5.minutes,
                        body: 'I found it and updated the order.', status: 'DELIVERED'),
        history_message(id: "#{index}.3", sender: contact_number, timestamp: timestamp + 10.minutes,
                        body: 'Perfect, thank you!', status: 'READ')
      ]
    }
  end

  def history_message(id:, sender:, timestamp:, body:, status:)
    {
      from: sender,
      id: "wamid.history-sync-test.#{sync.id}.#{id}",
      timestamp: timestamp.to_i.to_s,
      type: 'text',
      text: { body: body },
      history_context: { status: status }
    }
  end

  def history_timestamp(index, phase)
    age = { 0 => 12.hours, 1 => 30.days, 2 => 120.days }.fetch(phase)
    Time.current - age - index.minutes
  end

  def deliver(payload)
    event = Webhooks::WhatsappEventsJob.perform_now(payload.deep_symbolize_keys)
    Whatsapp::HistorySyncEventJob.perform_now(event.id)
  end

  def business_phone_number
    @business_phone_number ||= "+1555#{format('%07d', account.id % 10_000_000)}"
  end

  def phone_number_id
    @phone_number_id ||= "history-sync-test-phone-#{account.id}"
  end
end
