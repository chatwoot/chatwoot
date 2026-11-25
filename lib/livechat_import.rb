# rubocop:disable Rails/SkipsModelValidations
# Imports the LiveChat archive downloaded by livechat_export.sh into an API inbox.
# Rows are written with insert_all so no events, notifications, webhooks or automations fire.
# Re-runnable: the LiveChat thread ids already imported are stored on each conversation.
class LivechatImport
  PROVIDER = 'livechat'.freeze
  # LiveChat agents whose Chatwoot login uses a different email
  AGENT_EMAIL_ALIASES = { 'zelik.grzegorz@gmail.com' => 'khadori@gmail.com' }.freeze
  IMPORTED_EVENT_TYPES = %w[filled_form message file].freeze

  def initialize(account:, inbox:, dir:)
    raise ArgumentError, 'Use an API inbox so imported replies are never delivered to customers' unless inbox.api?

    @account = account
    @inbox = inbox
    @dir = Pathname(dir)
    @users = account.users.index_by { |user| user.email.downcase }
    @contacts = account.contacts.where.not(email: [nil, '']).pluck(:email, :id).to_h
    @contact_inboxes = inbox.contact_inboxes.pluck(:contact_id, :id).to_h
    rows = inbox.conversations.where.not(identifier: nil).pluck(:identifier, :id, :contact_id, :additional_attributes)
    @conversations = rows.to_h do |key, id, contact_id, attrs|
      [key, { id: id, contact_id: contact_id, threads: Array(attrs&.dig('livechat_thread_ids')) }]
    end
  end

  def perform
    pages = @dir.glob('pages/*.json.gz').sort
    pages.each_with_index do |page, index|
      JSON.parse(Zlib::GzipReader.open(page, &:read))['chats'].each { |chat| import_thread(chat) }
      puts "#{index + 1}/#{pages.size} #{page.basename}"
    end
  end

  private

  def import_thread(chat)
    thread = chat['thread']
    key = "#{PROVIDER}:#{chat['id']}"
    return if @conversations[key]&.fetch(:threads)&.include?(thread['id'])

    events = thread['events'].select { |event| IMPORTED_EVENT_TYPES.include?(event['type']) }
    last_at = time(events.last&.fetch('created_at') || thread['created_at'])
    Conversation.transaction do
      conversation = @conversations[key] || create_conversation(key, chat, time(thread['created_at']))
      insert_messages(events, chat, thread['id'], conversation) if events.any?
      Conversation.find(conversation[:id]).update_columns(
        additional_attributes: { livechat_thread_ids: conversation[:threads] + [thread['id']] },
        last_activity_at: last_at, updated_at: last_at, status_changed_at: last_at,
        agent_last_seen_at: last_at, assignee_last_seen_at: last_at, contact_last_seen_at: last_at
      )
      Contact.where(id: conversation[:contact_id], last_activity_at: [nil, ...last_at]).update_all(last_activity_at: last_at)
      conversation[:threads] += [thread['id']]
      @conversations[key] = conversation
    end
  end

  def create_conversation(key, chat, at)
    contact_id = contact_id_for(chat['users'].find { |user| user['type'] == 'customer' }, at)
    @contact_inboxes[contact_id] ||= insert(ContactInbox, contact_id: contact_id, inbox_id: @inbox.id, source_id: SecureRandom.uuid,
                                                          created_at: at, updated_at: at)
    id = insert(Conversation, account_id: @account.id, inbox_id: @inbox.id, contact_id: contact_id, contact_inbox_id: @contact_inboxes[contact_id],
                              identifier: key, status: Conversation.statuses[:resolved], created_at: at, updated_at: at, last_activity_at: at)
    { id: id, contact_id: contact_id, threads: [] }
  end

  def contact_id_for(customer, at)
    email = customer['email'].to_s.strip.downcase
    email = nil unless email.match?(Devise.email_regexp)
    return @contacts[email] if @contacts[email]

    id = insert(Contact, account_id: @account.id, name: customer['name'].to_s, email: email, contact_type: Contact.contact_types[:lead],
                         additional_attributes: { source: PROVIDER, livechat_customer_id: customer['id'] },
                         created_at: at, updated_at: at, last_activity_at: at)
    @contacts[email] = id if email
    id
  end

  def insert_messages(events, chat, thread_id, conversation)
    users = chat['users'].index_by { |user| user['id'] }
    files = @dir.glob("files/#{thread_id}/*").index_by { |path| path.basename.to_s.split('__').first }
    rows = events.map { |event| message_row(event, users[event['author_id']], conversation, files[event['id']]) }
    ids = Message.insert_all!(rows, returning: %w[source_id id]).rows.to_h
    events.each { |event| attach(ids[event['id']], event, files[event['id']]) if files[event['id']] }
  end

  def message_row(event, author, conversation, file)
    at = time(event['created_at'])
    content = case event['type']
              when 'filled_form' then form_note(event)
              when 'file' then file ? nil : event['url']
              else event['text']
              end
    incoming = event['type'] != 'filled_form' && author&.dig('type') == 'customer'
    agent_author = author&.dig('type') == 'agent'
    agent = @users[AGENT_EMAIL_ALIASES.fetch(author['id'], author['id']).downcase] if agent_author
    {
      account_id: @account.id, inbox_id: @inbox.id, conversation_id: conversation[:id], source_id: event['id'],
      message_type: Message.message_types[incoming ? :incoming : :outgoing],
      private: event['type'] == 'filled_form' || event['visibility'] == 'agents',
      content: content, processed_message_content: content,
      sender_type: incoming ? 'Contact' : agent && 'User', sender_id: incoming ? conversation[:contact_id] : agent&.id,
      additional_attributes: agent_author && !agent ? { livechat_author: "#{author['name']} <#{author['id']}>" } : {},
      created_at: at, updated_at: at
    }
  end

  def form_note(event)
    answers = event['fields'].map do |field|
      answer = field['answer']
      answer = Array.wrap(answer).map { |value| value.is_a?(Hash) ? value['label'] : value }.join(', ') unless answer.is_a?(String)
      "#{field['label']} #{answer}"
    end
    (['LiveChat pre-chat form'] + answers).join("\n")
  end

  def attach(message_id, event, path)
    blob = path.open { |io| ActiveStorage::Blob.create_and_upload!(io: io, filename: event['name'], content_type: event['content_type']) }
    Attachment.new(account_id: @account.id, message_id: message_id, file_type: file_type(event['content_type']), file: blob).save!(validate: false)
  end

  def file_type(content_type)
    %w[image video audio].find { |type| content_type.to_s.start_with?("#{type}/") } || 'file'
  end

  def insert(model, attrs)
    model.insert_all!([attrs], returning: %w[id]).rows.first.first
  end

  def time(value)
    Time.zone.parse(value)
  end
end
# rubocop:enable Rails/SkipsModelValidations
