require 'rails_helper'

# Every way a WhatsApp event reaches Chatwoot, and whether it files what a contact sends.
#
# The entry points are read from the code rather than typed here: the webhook services
# (every subclass of IncomingMessageBaseService), the handler modules the Baileys and Z-API
# services include, one per event, and the session dispatcher's table. A provider, an event
# or a handler that is not classified below fails this spec, so it cannot land without
# saying which side of Whatsapp::BlockedSender it is on.
#
# The ones that file a contact's messages are then exercised through the entry point
# itself: a blocked contact's message files nothing and opens nothing, the echo of a reply
# the owner typed on the phone is still filed, and an unblocked contact gets everything.
# A string and not Whatsapp::BlockedSender: the spec is about every entry point, and it has to
# run against a tree that predates the module to show what it catches.
RSpec.describe 'WhatsApp inbound entry points and a blocked contact' do # rubocop:disable RSpec/DescribeClass
  phone = '5541999990000'
  lid = '182736451928374'

  # How each entry point that files a contact's messages is driven, and what it files.
  # `echo: false` is an event that only ever comes from the contact.
  entry_points = {
    'service:Whatsapp::IncomingMessageWhatsappCloudService' => {
      why: 'Cloud API messages and smb echoes', channel: { provider: 'whatsapp_cloud' }, source_id: phone,
      deliver: lambda do |id, from_me:|
        message = { id: id, text: { body: 'oi' }, timestamp: Time.current.to_i.to_s, type: 'text' }
        value = if from_me
                  { message_echoes: [message.merge(from: channel.phone_number.delete('+'), to: phone)] }
                else
                  { contacts: [{ profile: { name: 'Ana' }, wa_id: phone }], messages: [message.merge(from: phone)] }
                end
        params = { phone_number: channel.phone_number, object: 'whatsapp_business_account',
                   entry: [{ changes: [{ field: from_me ? 'smb_message_echoes' : 'messages', value: value }] }] }
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: inbox, params: params.with_indifferent_access, outgoing_echo: from_me).perform
      end
    },
    'service:Whatsapp::IncomingMessageService' => {
      why: '360dialog messages', channel: { provider: 'default' }, source_id: phone, echo: false,
      deliver: lambda do |id, from_me:| # rubocop:disable Lint/UnusedBlockArgument
        params = { contacts: [{ profile: { name: 'Ana' }, wa_id: phone }],
                   messages: [{ from: phone, id: id, text: { body: 'oi' }, timestamp: Time.current.to_i.to_s, type: 'text' }] }
        Whatsapp::IncomingMessageService.new(inbox: inbox, params: params.with_indifferent_access).perform
      end
    },
    'baileys:MessagesUpsert' => {
      why: 'live messages and echoes', channel: { provider: 'baileys', provider_config: { webhook_verify_token: 'token' } }, source_id: lid,
      deliver: lambda do |id, from_me:|
        raw = { key: { id: id, remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: from_me, addressingMode: 'lid' },
                pushName: 'Ana', messageTimestamp: Time.current.to_i, message: { conversation: 'oi' } }
        params = { webhookVerifyToken: 'token', event: 'messages.upsert', data: { type: 'notify', messages: [raw] } }
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
      end
    },
    'baileys:MessagingHistorySet' => {
      why: "the phone's history, filed by Baileys::HistoryImporter",
      channel: { provider: 'baileys', provider_config: { webhook_verify_token: 'token' } }, source_id: lid,
      deliver: lambda do |id, from_me:|
        raw = { key: { id: id, remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: from_me, addressingMode: 'lid' },
                pushName: 'Ana', messageTimestamp: 2.days.ago.to_i, message: { conversation: 'oi' } }
        params = { webhookVerifyToken: 'token', event: 'messaging-history.set', data: { syncType: 6, messages: [raw] } }
        perform_enqueued_jobs(only: Whatsapp::Baileys::HistoryImportJob) do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end
      end
    },
    'zapi:ReceivedCallback' => {
      why: 'live messages and echoes', channel: { provider: 'zapi' }, source_id: lid,
      deliver: lambda do |id, from_me:|
        params = { type: 'ReceivedCallback', messageId: id, momment: Time.current.to_i * 1000, phone: phone,
                   chatLid: "#{lid}@lid", fromMe: from_me, chatName: 'Ana', text: { message: 'oi' } }
        Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: params).perform
      end
    },
    'session:MessageReceived' => {
      why: 'live messages and echoes', channel: { provider: 'native' }, source_id: lid,
      deliver: lambda do |id, from_me:|
        model = Whatsapp::Session::Model
        message = model::InboundMessage.new(
          id: id, chat: model::Address.phone(phone), sender: model::Party.new(phone: phone, lid: lid, push_name: 'Ana'),
          from_me: from_me, timestamp: (Time.current.to_f * 1000).to_i, content: model::Content::Text.new(body: 'oi')
        )
        Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, model::Event.build(model::Events::MessageReceived.new(message: message)))
      end
    },
    'session:MessageReaction' => {
      why: 'a reaction is filed as a message', channel: { provider: 'native' }, source_id: lid, needs_target: true,
      deliver: lambda do |id, from_me:|
        model = Whatsapp::Session::Model
        reaction = model::Events::MessageReaction.new(
          id: id, chat: model::Address.phone(phone), sender: from_me ? nil : model::Party.new(phone: phone, lid: lid, push_name: 'Ana'),
          from_me: from_me, target_id: 'TARGET', emoji: '👍', timestamp: (Time.current.to_f * 1000).to_i
        )
        Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, model::Event.build(reaction))
      end
    },
    'session:CallOffer' => {
      why: 'a call is filed as a line in the thread', channel: { provider: 'native' }, source_id: lid, echo: false,
      deliver: lambda do |id, from_me:| # rubocop:disable Lint/UnusedBlockArgument
        model = Whatsapp::Session::Model
        offer = model::Events::CallOffer.new(call_id: id, from: model::Party.new(phone: phone, lid: lid, push_name: 'Ana'),
                                             video: false, timestamp: (Time.current.to_f * 1000).to_i)
        Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, model::Event.build(offer))
      end
    },
    'session:HistorySync' => {
      why: 'the phone\'s history, filed by Session::Inbound::HistoryImporter', channel: { provider: 'native' }, source_id: lid,
      deliver: lambda do |id, from_me:|
        model = Whatsapp::Session::Model
        message = model::InboundMessage.new(
          id: id, chat: model::Address.phone(phone), sender: model::Party.new(phone: phone, lid: lid, push_name: 'Ana'),
          from_me: from_me, timestamp: (2.days.ago.to_f * 1000).to_i, content: model::Content::Text.new(body: 'oi')
        )
        data = { 'sync' => 'on_demand', 'chat' => model::Address.phone(phone).to_h, 'messages' => [message.to_h] }
        perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob) do
          Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, model::Event.build(model::Events::HistorySync.new(kind: 'messages', data: data)))
        end
      end
    }
  }

  # What the rest file instead, and why the rule does not reach them.
  files_nothing_from_a_contact = {
    'service:Whatsapp::IncomingMessageBaileysService' => 'routes each event to a baileys: module below',
    'service:Whatsapp::IncomingMessageZapiService' => 'routes each callback to a zapi: module below',
    'service:Whatsapp::Baileys::HistoryImporter' => 'reached through baileys:MessagingHistorySet',
    'baileys:ConnectionUpdate' => 'connection state',
    'baileys:MessagesUpdate' => 'edits and statuses of a message already filed',
    'baileys:MessageReceiptUpdate' => 'read receipts',
    'baileys:GroupParticipantsUpdate' => 'groups: the rule is per contact',
    'baileys:GroupsUpdate' => 'groups: the rule is per contact',
    'baileys:GroupsActivity' => 'groups: the rule is per contact',
    'baileys:PresenceUpdate' => 'typing and online state',
    'baileys:MessageCappingUpdate' => 'account limits',
    'zapi:ConnectedCallback' => 'connection state',
    'zapi:DisconnectedCallback' => 'connection state',
    'zapi:DeliveryCallback' => 'delivery of a message we sent',
    'zapi:MessageStatusCallback' => 'statuses of a message already filed',
    'session:ConnectionState' => 'connection state',
    'session:MessageReceipt' => 'read receipts',
    'session:MessageEdited' => 'edits a message already filed',
    'session:MessageRevoked' => 'flags a message already filed',
    'session:MediaDownloadFailed' => 'media of a message already filed',
    'session:CommandFailed' => 'the outcome of a command we sent',
    'session:Presence' => 'typing and online state',
    'session:ContactPictureChanged' => 'the avatar of a contact already filed',
    'session:GroupJoined' => 'groups: the rule is per contact',
    'session:GroupUpdated' => 'groups: the rule is per contact',
    'session:GroupPictureChanged' => 'groups: the rule is per contact',
    'session:GroupActivity' => 'groups: the rule is per contact',
    'session:Raw' => 'forwards the provider event to listeners, files nothing'
  }

  it 'knows which side every inbound entry point is on' do
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/services/whatsapp').to_s)
    modules = lambda do |service, namespace|
      service.included_modules.filter_map(&:name).grep(/\A#{namespace}::\w+\z/).map { |name| name.delete_prefix("#{namespace}::") } - ['Helpers']
    end
    found = Whatsapp::IncomingMessageBaseService.descendants.map { |service| "service:#{service.name}" } +
            modules.call(Whatsapp::IncomingMessageBaileysService, 'Whatsapp::BaileysHandlers').map { |name| "baileys:#{name}" } +
            modules.call(Whatsapp::IncomingMessageZapiService, 'Whatsapp::ZapiHandlers').map { |name| "zapi:#{name}" } +
            Whatsapp::Session::Inbound::Dispatcher::HANDLERS.values.uniq.map { |name| "session:#{name}" }

    expect(entry_points.keys + files_nothing_from_a_contact.keys).to match_array(found)
    expect(entry_points.values.pluck(:why) + files_nothing_from_a_contact.values).to all(be_present)
  end

  entry_points.each do |entry_point, spec|
    context "with an event through #{entry_point}" do
      let(:channel) do
        create(:channel_whatsapp, validate_provider_config: false, sync_templates: false, received_messages: false, **spec[:channel])
      end
      let(:inbox) { channel.inbox }
      let(:contact) { create(:contact, account: inbox.account, name: 'Ana', phone_number: "+#{phone}", identifier: "#{lid}@lid") }

      before do
        stub_request(:any, /.*/).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
        create(:account_user, account: inbox.account)
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: spec[:source_id])
        if spec[:needs_target]
          conversation = create(:conversation, inbox: inbox, account: inbox.account, contact: contact, contact_inbox: contact_inbox)
          create(:message, conversation: conversation, inbox: inbox, account: inbox.account, message_type: :outgoing, source_id: 'TARGET')
        end
      end

      def deliver(spec, id, from_me: false) = instance_exec(id, from_me: from_me, &spec[:deliver])

      it 'files what an unblocked contact sends' do
        expect { deliver(spec, 'FREE-1') }.to change(inbox.messages, :count)
      end

      context 'when the contact is blocked' do
        before { contact.update!(blocked: true) }

        it 'files nothing and opens nothing' do
          expect { deliver(spec, 'BLOCKED-1') }.not_to(change { [inbox.messages.count, inbox.conversations.count] })
        end

        unless spec[:echo] == false
          it 'still files the echo of a reply typed on the phone' do
            expect { deliver(spec, 'ECHO-1', from_me: true) }.to change(inbox.messages, :count)
          end
        end
      end
    end
  end
end
