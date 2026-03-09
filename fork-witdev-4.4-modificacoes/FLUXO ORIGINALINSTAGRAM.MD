No Chatwoot, o processamento dos eventos de botões/quick replies do Instagram segue este fluxo principal:

1. Recebimento do Webhook
   Arquivo: app/controllers/webhooks/instagram_controller.rb
   Método: events
   Recebe o POST do Instagram com o evento do botão.
2. Disparo do Job para Processar o Evento
   Arquivo: app/jobs/webhooks/instagram_events_job.rb
   Método: perform
   Chama o processamento assíncrono do evento recebido.
3. Processamento dos Eventos
   Arquivo: app/jobs/webhooks/instagram_events_job.rb
   Métodos: process_entries, process_single_entry, process_messages
   Identifica o tipo de evento e chama o serviço correto.
4. Criação da Mensagem
   Arquivo: app/services/instagram/message_text.rb
   Método: perform (herdado de Instagram::BaseMessageText)
   Cria a mensagem no banco, usando o texto e o payload do botão.
   Arquivo: app/builders/messages/instagram/base_message_builder.rb
   Método: build_message
   Constrói a mensagem na conversa, usando os dados do evento.
   Resumo do fluxo
   Controller recebe o webhook.
   Job processa o evento.
   Service interpreta o evento e cria a mensagem.
   Builder salva a mensagem na conversa.

//CHATWOOT_ORIGINAL:app\controllers\webhooks\instagram_controller.rb

class Webhooks::InstagramController < ActionController::API
include MetaTokenVerifyConcern

def events
Rails.logger.info('Instagram webhook received events')
if params['object'].casecmp('instagram').zero?
entry_params = params.to_unsafe_hash[:entry]

      if contains_echo_event?(entry_params)
        # Add delay to prevent race condition where echo arrives before send message API completes
        # This avoids duplicate messages when echo comes early during API processing
        ::Webhooks::InstagramEventsJob.set(wait: 2.seconds).perform_later(entry_params)
      else
        ::Webhooks::InstagramEventsJob.perform_later(entry_params)
      end

      render json: :ok
    else
      Rails.logger.warn("Message is not received from the instagram webhook event: #{params['object']}")
      head :unprocessable_entity
    end

end

private

def contains_echo_event?(entry_params)
return false unless entry_params.is_a?(Array)

    entry_params.any? do |entry|
      # Check messaging array for echo events
      messaging_events = entry[:messaging] || []
      messaging_events.any? { |messaging| messaging.dig(:message, :is_echo).present? }
    end

end

def valid_token?(token) # Validates against both IG_VERIFY_TOKEN (Instagram channel via Facebook page) and # INSTAGRAM_VERIFY_TOKEN (Instagram channel via direct Instagram login)
token == GlobalConfigService.load('IG_VERIFY_TOKEN', '') ||
token == GlobalConfigService.load('INSTAGRAM_VERIFY_TOKEN', '')
end
end

//CHATWOOT_ORIGINAL:app\jobs\webhooks\instagram_events_job.rb
class Webhooks::InstagramEventsJob < MutexApplicationJob
queue_as :default
retry_on LockAcquisitionError, wait: 1.second, attempts: 8

# @return [Array] We will support further events like reaction or seen in future

SUPPORTED_EVENTS = [:message, :read].freeze

def perform(entries)
@entries = entries

    key = format(::Redis::Alfred::IG_MESSAGE_MUTEX, sender_id: sender_id, ig_account_id: ig_account_id)
    with_lock(key) do
      process_entries(entries)
    end

end

# https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook

def process_entries(entries)
entries.each do |entry|
process_single_entry(entry.with_indifferent_access)
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

      instagram_id = instagram_id(messaging)
      channel = find_channel(instagram_id)

      next if channel.blank?

      if (event_name = event_name(messaging))
        send(event_name, messaging, channel)
      end
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
@entries&.first&.dig(:id)
end

def sender_id
@entries&.dig(0, :messaging, 0, :sender, :id)
end

def find_channel(instagram_id) # There will be chances for the instagram account to be connected to a facebook page, # so we need to check for both instagram and facebook page channels # priority is for instagram channel which created via instagram login
channel = Channel::Instagram.find_by(instagram_id: instagram_id) # If not found, fallback to the facebook page channel
channel ||= Channel::FacebookPage.find_by(instagram_id: instagram_id)

    channel

end

def event_name(messaging)
@event_name ||= SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
end

def message(messaging, channel)
if channel.is_a?(Channel::Instagram)
::Instagram::MessageText.new(messaging, channel).perform
else
::Instagram::Messenger::MessageText.new(messaging, channel).perform
end
end

def read(messaging, channel) # Use a single service to handle read status for both channel types since the params are same
::Instagram::ReadStatusService.new(params: messaging, channel: channel).perform
end

def messages(entry)
(entry[:messaging].presence || entry[:standby] || [])
end
end

# Actual response from Instagram webhook (both via Facebook page and Instagram direct)

# [

# {

# "time": <timestamp>,

# "id": <INSTAGRAM_USER_ID>,

# "messaging": [

# {

# "sender": {

# "id": <INSTAGRAM_USER_ID>

# },

# "recipient": {

# "id": <INSTAGRAM_USER_ID>

# },

# "timestamp": <timestamp>,

# "message": {

# "mid": <MESSAGE_ID>,

# "text": <MESSAGE_TEXT>

# }

# }

# ]

# }

# ]

# Instagram's webhook via Instagram direct testing quirk: Test payloads vs Actual payloads

# When testing in Facebook's developer dashboard, you'll get a Page-style

# payload with a "changes" object. But don't be fooled! Real Instagram DMs

# arrive in the familiar Messenger format with a "messaging" array.

# This apparent inconsistency is actually by design - Instagram's webhooks

# use different formats for testing vs production to maintain compatibility

# with both Instagram Direct and Facebook Page integrations.

# See: https://developers.facebook.com/docs/instagram-platform/webhooks#event-notifications

# Test response from via Instagram direct

# [

# {

# "id": "0",

# "time": <timestamp>,

# "changes": [

# {

# "field": "messages",

# "value": {

# "sender": {

# "id": "12334"

# },

# "recipient": {

# "id": "23245"

# },

# "timestamp": "1527459824",

# "message": {

# "mid": "random_mid",

# "text": "random_text"

# }

# }

# }

# ]

# }

# ]

# Test response via Facebook page

# [

# {

# "time": <timestamp>,,

# "id": "0",

# "messaging": [

# {

# "sender": {

# "id": "12334"

# },

# "recipient": {

# "id": "23245"

# },

# "timestamp": <timestamp>,

# "message": {

# "mid": "random_mid",

# "text": "random_text"

# }

# }

# ]

# }

# ]

//CHATWOOT_ORIGINAL:app\builders\messages\instagram\base_message_builder.rb
class Messages::Instagram::BaseMessageBuilder < Messages::Messenger::MessageBuilder
attr_reader :messaging

def initialize(messaging, inbox, outgoing_echo: false)
super()
@messaging = messaging
@inbox = inbox
@outgoing_echo = outgoing_echo
end

def perform
return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_message
    end

rescue StandardError => e
handle_error(e)
end

private

def attachments
@messaging[:message][:attachments] || {}
end

def message_type
@outgoing_echo ? :outgoing : :incoming
end

def message_identifier
message[:mid]
end

def message_source_id
@outgoing_echo ? recipient_id : sender_id
end

def message_is_unsupported?
message[:is_unsupported].present? && @messaging[:message][:is_unsupported] == true
end

def sender_id
@messaging[:sender][:id]
end

def recipient_id
@messaging[:recipient][:id]
end

def message
@messaging[:message]
end

def contact
@contact ||= @inbox.contact_inboxes.find_by(source_id: message_source_id)&.contact
end

def conversation
@conversation ||= set_conversation_based_on_inbox_config
end

def set_conversation_based_on_inbox_config
if @inbox.lock_to_single_conversation
find_conversation_scope.order(created_at: :desc).first || build_conversation
else
find_or_build_for_multiple_conversations
end
end

def find_conversation_scope
Conversation.where(conversation_params)
end

def find_or_build_for_multiple_conversations
last_conversation = find_conversation_scope.where.not(status: :resolved).order(created_at: :desc).first
return build_conversation if last_conversation.nil?

    last_conversation

end

def message_content
@messaging[:message][:text]
end

def story_reply_attributes
message[:reply_to][:story] if message[:reply_to].present? && message[:reply_to][:story].present?
end

def message_reply_attributes
message[:reply_to][:mid] if message[:reply_to].present? && message[:reply_to][:mid].present?
end

def build_message # Duplicate webhook events may be sent for the same message # when a user is connected to the Instagram account through both Messenger and Instagram login. # There is chance for echo events to be sent for the same message. # Therefore, we need to check if the message already exists before creating it.
return if message_already_exists?

    return if message_content.blank? && all_unsupported_files?

    @message = conversation.messages.create!(message_params)
    save_story_id

    attachments.each do |attachment|
      process_attachment(attachment)
    end

end

def save_story_id
return if story_reply_attributes.blank?

    @message.save_story_info(story_reply_attributes)

end

def build_conversation
@contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)
Conversation.create!(conversation_params.merge(
contact_inbox_id: @contact_inbox.id,
additional_attributes: additional_conversation_attributes
))
end

def additional_conversation_attributes
{}
end

def conversation_params
{
account_id: @inbox.account_id,
inbox_id: @inbox.id,
contact_id: contact.id
}
end

def message_params
params = {
account_id: conversation.account_id,
inbox_id: conversation.inbox_id,
message_type: message_type,
source_id: message_identifier,
content: message_content,
sender: @outgoing_echo ? nil : contact,
content_attributes: {
in_reply_to_external_id: message_reply_attributes
}
}

    params[:content_attributes][:is_unsupported] = true if message_is_unsupported?
    params

end

def message_already_exists?
find_message_by_source_id(@messaging[:message][:mid]).present?
end

def find_message_by_source_id(source_id)
return unless source_id

    @message = Message.find_by(source_id: source_id)

end

def all_unsupported_files?
return if attachments.empty?

    attachments_type = attachments.pluck(:type).uniq.first
    unsupported_file_type?(attachments_type)

end

def handle_error(error)
ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
true
end

# Abstract methods to be implemented by subclasses

def get_story_object_from_source_id(source_id)
raise NotImplementedError
end
end
