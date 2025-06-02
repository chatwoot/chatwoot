## Class to generate sample conversations for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with conversations
#   Seeders::ConversationSeeder.new(account: Account.find(1), contact_data: []).perform!
#
#
############################################################

class Seeders::ConversationSeeder
  def initialize(account:, contact_data:)
    raise 'Conversation Seeding is not allowed in production.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
    @contact_data = contact_data
  end

  def perform!
    seed_conversations
  end

  private

  def seed_conversations
    @contact_data.each do |contact_data|
      contact = @account.contacts.find_by(email: contact_data['email'])
      next unless contact

      contact_data['conversations'].each do |conversation_data|
        inbox = @account.inboxes.find_by(channel_type: conversation_data['channel'])
        contact_inbox = inbox.contact_inboxes.create_or_find_by!(
          contact: contact,
          source_id: (conversation_data['source_id'] || SecureRandom.hex)
        )
        create_conversation(contact_inbox: contact_inbox, conversation_data: conversation_data)
      end
    end
  end

  def create_conversation(contact_inbox:, conversation_data:)
    assignee = determine_assignee(conversation_data, contact_inbox.inbox)
    conversation = build_conversation(contact_inbox, assignee)

    create_messages(conversation: conversation, messages: conversation_data['messages'])
    apply_conversation_attributes(conversation, conversation_data)
    resolve_conversation_if_needed(conversation, assignee)
  end

  def determine_assignee(conversation_data, inbox)
    assignee = User.from_email(conversation_data['assignee']) if conversation_data['assignee'].present?
    assignee ||= @account.agents.sample if inbox.csat_survey_enabled
    assignee
  end

  def build_conversation(contact_inbox, assignee)
    contact_inbox.conversations.create!(
      account: contact_inbox.inbox.account,
      contact: contact_inbox.contact,
      inbox: contact_inbox.inbox,
      assignee: assignee
    )
  end

  def apply_conversation_attributes(conversation, conversation_data)
    conversation.update_labels(conversation_data[:labels]) if conversation_data[:labels].present?
    conversation.update!(priority: conversation_data[:priority]) if conversation_data[:priority].present?
  end

  def resolve_conversation_if_needed(conversation, assignee)
    return unless assignee.present? && rand > 0.4

    conversation.update!(status: :resolved)
  end

  def create_messages(conversation:, messages:)
    messages.each do |message_data|
      sender = find_message_sender(conversation, message_data)
      conversation.messages.create!(
        message_data.slice('content', 'message_type').merge(
          account: conversation.inbox.account, sender: sender, inbox: conversation.inbox
        )
      )
    end
  end

  def find_message_sender(conversation, message_data)
    if message_data['message_type'] == 'incoming'
      conversation.contact
    elsif message_data['sender'].present?
      User.from_email(message_data['sender'])
    end
  end
end