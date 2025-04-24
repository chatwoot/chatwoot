class TestData::ConversationGenerator
  def initialize(account:, contact_inboxes:, labels:, display_id_tracker:)
    @account = account
    @contact_inboxes = contact_inboxes
    @labels = labels
    @display_id_tracker = display_id_tracker
    @conversations = []
  end

  def generate!
    Rails.logger.info { "Creating conversations for account ##{@account.id}" }
    start_time = Time.current

    conversations_data, conversation_labels = build_conversations_data
    count = bulk_insert_conversations(conversations_data)

    # TODO: This is slow process, we should find a better way to do this
    Rails.logger.info { 'Applying labels to conversations' }
    process_conversations_in_batches(conversations_data, conversation_labels)

    # Store all conversations for later use
    @conversations = Conversation.where(
      account_id: @account.id,
      display_id: conversations_data.pluck(:display_id)
    ).order(:created_at)

    Rails.logger.info { "Created #{count} conversations in #{Time.current - start_time}s" }
    @conversations
  end

  private

  def build_conversations_data
    data = []
    labels = {}

    @contact_inboxes.each do |ci|
      num_convos = rand(1..TestData::Constants::MAX_CONVERSATIONS_PER_CONTACT)
      num_convos.times do
        conversation_data, conversation_labels = build_conversation(ci)
        data << conversation_data
        labels[conversation_data[:display_id]] = conversation_labels
      end
    end

    [data, labels]
  end

  def build_conversation(contact_inbox)
    created_at = Faker::Time.between(from: contact_inbox.created_at, to: Time.current)
    conversation_data = {
      account_id: @account.id,
      inbox_id: contact_inbox.inbox_id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      status: TestData::Constants::STATUSES.sample,
      created_at: created_at,
      updated_at: created_at,
      display_id: @display_id_tracker.next_id
    }

    # Return both the conversation data and the labels
    labels_to_add = @labels.sample(rand(2..10)).map(&:title)
    [conversation_data, labels_to_add]
  end

  # rubocop:disable Rails/SkipsModelValidations
  def bulk_insert_conversations(conversations_data)
    count = conversations_data.size
    Rails.logger.info { "Preparing to insert #{count} conversations" }
    Conversation.insert_all!(conversations_data) if conversations_data.any?
    count
  end
  # rubocop:enable Rails/SkipsModelValidations

  def process_conversations_in_batches(conversations_data, conversation_labels)
    batch_size = 10_000
    conversations_data.each_slice(batch_size) do |batch|
      display_ids = batch.pluck(:display_id)
      conversations = fetch_conversations_with_associations(display_ids)
      inboxes = preload_inboxes(conversations)
      update_conversation_labels(conversations, conversation_labels, inboxes)
    end
  end

  def fetch_conversations_with_associations(display_ids)
    Conversation.includes(:inbox, :contact_inbox).where(
      account_id: @account.id,
      display_id: display_ids
    )
  end

  def preload_inboxes(conversations)
    inbox_ids = conversations.map(&:inbox_id).uniq
    @account.inboxes.where(id: inbox_ids).index_by(&:id)
  end

  def update_conversation_labels(conversations, conversation_labels, inboxes)
    conversations.each do |conversation|
      update_labels_for_conversation(conversation, conversation_labels, inboxes)
    end
  end

  def update_labels_for_conversation(conversation, conversation_labels, inboxes)
    return unless inboxes[conversation.inbox_id]
    return unless (labels = conversation_labels[conversation.display_id])

    conversation.update_labels(labels)
  end
end
