require 'rails_helper'
describe ActionCableListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    Current.user = nil
    Current.account = nil
  end

  # The roster arrives twice: once from the REST fetch and again on every sync. Both have
  # to answer "which row is us" the same way, or the second undoes the first -- which is
  # what happened while each carried its own phone-only query and only the fetch knew
  # about LIDs.
  describe '#contact_group_synced' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'uazapi', phone_number: '+5541999990000',
                                validate_provider_config: false, sync_templates: false)
    end
    let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: '1203630001@g.us') }

    it 'broadcasts the same ownership the roster endpoint reports' do
      channel.update!(provider_connection: { 'connection' => 'open', 'lid' => '900000100000000' })
      create(:contact_inbox, inbox: channel.inbox, contact: group_contact)
      own = create(:contact, account: account, phone_number: nil, identifier: '900000100000000@lid')
      own_member = create(:group_member, group_contact: group_contact, contact: own, role: 'admin')
      event = Events::Base.new(:'contact.group_synced', Time.zone.now, contact: group_contact)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        anything, 'contact.group_synced',
        hash_including(own_member_id: own_member.id, is_inbox_admin: true)
      )

      listener.contact_group_synced(event)
    end

    # The panel decides what the agent may do from this payload, so it has to answer for
    # the inbox the sync ran as. `Contact#group_channel` is the group contact's first
    # contact inbox, which is another number entirely as soon as the group is in two.
    it 'answers for the inbox the event names, not for whichever came first' do
      other = create(:channel_whatsapp, account: account, provider: 'uazapi', phone_number: '+5541988887777',
                                        validate_provider_config: false, sync_templates: false)
      create(:contact_inbox, inbox: other.inbox, contact: group_contact)
      create(:contact_inbox, inbox: channel.inbox, contact: group_contact)
      event = Events::Base.new(:'contact.group_synced', Time.zone.now, contact: group_contact, channel: channel)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        anything, 'contact.group_synced',
        hash_including(inbox_id: channel.inbox.id, inbox_phone_number: '+5541999990000')
      )

      listener.contact_group_synced(event)
    end
  end

  describe '#conversation_bot_handoff' do
    let(:event) { Events::Base.new(:'conversation.bot_handoff', Time.zone.now, conversation: conversation) }

    it 'broadcasts the handoff to inbox agents and account admins only' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        'conversation.bot_handoff',
        conversation.push_event_data.merge(account_id: account.id)
      )

      listener.conversation_bot_handoff(event)
    end

    it 'includes the performer so dashboards can distinguish human takeovers' do
      Current.user = agent
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        'conversation.bot_handoff',
        conversation.push_event_data.merge(account_id: account.id, performer: agent.push_event_data)
      )

      listener.conversation_bot_handoff(event)
    end
  end

  describe '#account_cache_invalidated' do
    let!(:event) do
      Events::Base.new(
        :'account.cache_invalidated',
        Time.zone.now,
        account: account,
        cache_keys: account.cache_keys
      )
    end

    it 'sends cache invalidation to account agents and admins' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        'account.cache_invalidated',
        {
          cache_keys: account.cache_keys,
          account_id: account.id
        }
      )

      listener.account_cache_invalidated(event)
    end
  end

  describe '#message_created' do
    let(:event_name) { :'message.created' }
    let!(:message) do
      create(:message, message_type: 'incoming', sender: conversation.contact,
                       account: account, inbox: inbox, conversation: conversation)
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

    it 'sends the full message to agents and the widget payload to the web widget session in one job' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.message_created(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        'message.created',
        message.push_event_data.merge(account_id: account.id),
        widget_members: [conversation.contact_inbox.pubsub_token],
        widget_data: message.widget_push_event_data.merge(account_id: account.id)
      )
    end

    it 'sends the widget payload to all hmac verified contact inboxes' do
      conversation.contact_inbox.update!(hmac_verified: true)
      # creating a non verified contact inbox to ensure the events are not sent to it
      create(:contact_inbox, contact: conversation.contact, inbox: inbox)
      verified_contact_inbox = create(:contact_inbox, contact: conversation.contact, inbox: inbox, hmac_verified: true)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.message_created(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
        anything,
        'message.created',
        anything,
        widget_members: a_collection_containing_exactly(conversation.contact_inbox.pubsub_token, verified_contact_inbox.pubsub_token),
        widget_data: message.widget_push_event_data.merge(account_id: account.id)
      )
    end

    it 'sends each verified session the payload of its own inbox' do
      conversation.contact_inbox.update!(hmac_verified: true)
      api_inbox = create(:inbox, account: account, channel: create(:channel_api, account: account))
      api_session = create(:contact_inbox, contact: conversation.contact, inbox: api_inbox, hmac_verified: true)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.message_created(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token, api_session.pubsub_token),
        'message.created',
        message.push_event_data.merge(account_id: account.id),
        widget_members: [conversation.contact_inbox.pubsub_token],
        widget_data: message.widget_push_event_data.merge(account_id: account.id)
      )
    end

    it 'skips a verified session whose inbox no longer exists' do
      conversation.contact_inbox.update!(hmac_verified: true)
      orphan = create(:contact_inbox, contact: conversation.contact, inbox: create(:inbox, account: account), hmac_verified: true)
      orphan.update_column(:inbox_id, 0) # rubocop:disable Rails/SkipsModelValidations
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.message_created(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
        anything, 'message.created', anything, widget_members: [conversation.contact_inbox.pubsub_token], widget_data: anything
      )
    end

    it 'sends a Client API session the full message in the agents job' do
      api_inbox = create(:inbox, account: account, channel: create(:channel_api, account: account))
      api_conversation = create(:conversation, account: account, inbox: api_inbox)
      api_message = create(:message, message_type: 'incoming', sender: api_conversation.contact,
                                     account: account, inbox: api_inbox, conversation: api_conversation)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.message_created(Events::Base.new(event_name, Time.zone.now, message: api_message))

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        a_collection_containing_exactly(admin.pubsub_token, api_conversation.contact_inbox.pubsub_token),
        'message.created',
        api_message.push_event_data.merge(account_id: account.id)
      )
    end

    it 'does not send a private note to the contact' do
      note = create(:message, message_type: 'outgoing', private: true, account: account, inbox: inbox, conversation: conversation)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.message_created(Events::Base.new(event_name, Time.zone.now, message: note))

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once
    end
  end

  describe '#typing_on' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    it 'sends the full event to other agents and the widget payload to the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.conversation_typing_on(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        [admin.pubsub_token],
        'conversation.typing_on',
        { conversation: conversation.push_event_data, user: agent.push_event_data, account_id: account.id, is_private: false },
        widget_members: [conversation.contact_inbox.pubsub_token],
        widget_data: { conversation: conversation.widget_push_event_data, user: agent.push_event_data, account_id: account.id, is_private: false }
      )
    end
  end

  describe '#typing_on with contact' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: conversation.contact, is_private: false) }

    it 'sends the event to account admins and inbox agents only' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).once.with(
        a_collection_containing_exactly(admin.pubsub_token, agent.pubsub_token),
        'conversation.typing_on', { conversation: conversation.push_event_data,
                                    user: conversation.contact.push_event_data,
                                    account_id: account.id,
                                    is_private: false }
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_on with agent bot' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:agent_bot) { create(:agent_bot, account: account) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent_bot, is_private: false) }

    it 'sends the event to account admins, inbox agents and the contact' do
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.conversation_typing_on(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        a_collection_containing_exactly(admin.pubsub_token, agent.pubsub_token),
        'conversation.typing_on',
        { conversation: conversation.push_event_data, user: agent_bot.push_event_data, account_id: account.id, is_private: false },
        widget_members: [conversation.contact_inbox.pubsub_token],
        widget_data: { conversation: conversation.widget_push_event_data, user: agent_bot.push_event_data, account_id: account.id, is_private: false }
      )
    end
  end

  describe '#typing_off' do
    let(:event_name) { :'conversation.typing_off' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    it 'sends the full event to other agents and the widget payload to the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.conversation_typing_off(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        [admin.pubsub_token],
        'conversation.typing_off',
        { conversation: conversation.push_event_data, user: agent.push_event_data, account_id: account.id, is_private: false },
        widget_members: [conversation.contact_inbox.pubsub_token],
        widget_data: { conversation: conversation.widget_push_event_data, user: agent.push_event_data, account_id: account.id, is_private: false }
      )
    end
  end

  describe '#contact_deleted' do
    let(:event_name) { :'contact.deleted' }
    let!(:contact) { create(:contact, account: account) }
    let(:contact_data) { contact.push_event_data.merge(account_id: contact.account_id) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, contact_data: contact_data) }

    it 'sends message to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        ["account_#{account.id}"],
        'contact.deleted',
        contact_data
      )
      listener.contact_deleted(event)
    end
  end

  describe '#conversation_pinned' do
    let(:pinned_at) { Time.zone.now.to_f }
    let(:pin_data) do
      {
        account_id: account.id,
        user_id: agent.id,
        conversation_id: conversation.display_id,
        pinned_at: pinned_at
      }
    end
    let!(:event) { Events::Base.new(:'conversation.pinned', Time.zone.now, conversation_pin: pin_data) }

    it 'sends the message only to the agent who pinned the conversation' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'conversation.pinned',
        {
          account_id: account.id,
          conversation_id: conversation.display_id,
          pinned_at: pinned_at
        }
      )

      listener.conversation_pinned(event)
    end

    it 'does not broadcast when the user is gone' do
      event = Events::Base.new(:'conversation.pinned', Time.zone.now, conversation_pin: pin_data.merge(user_id: 0))

      expect(ActionCableBroadcastJob).not_to receive(:perform_later)

      listener.conversation_pinned(event)
    end
  end

  describe '#conversation_unpinned' do
    let(:pin_data) do
      {
        account_id: account.id,
        user_id: agent.id,
        conversation_id: conversation.display_id,
        pinned_at: Time.zone.now.to_f
      }
    end
    let!(:event) { Events::Base.new(:'conversation.unpinned', Time.zone.now, conversation_pin: pin_data) }

    it 'sends the message only to the agent who unpinned the conversation' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'conversation.unpinned',
        {
          account_id: account.id,
          conversation_id: conversation.display_id,
          pinned_at: pin_data[:pinned_at]
        }
      )

      listener.conversation_unpinned(event)
    end
  end

  describe '#notification_deleted' do
    let(:event_name) { :'notification.deleted' }
    let!(:notification) { create(:notification, account: account, user: agent) }
    let(:notification_data) do
      {
        id: notification.id,
        user_id: agent.id,
        account_id: account.id
      }
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification_data: notification_data) }

    it 'sends message to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.deleted',
        {
          account_id: notification.account_id,
          notification: {
            id: notification.id
          },
          unread_count: 1,
          count: 1
        }
      )

      listener.notification_deleted(event)
    end
  end

  describe '#notification_updated' do
    let(:event_name) { :'notification.updated' }
    let!(:notification) { create(:notification, account: account, user: agent) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, notification: notification) }

    it 'sends notification to account admins, inbox agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'notification.updated',
        {
          account_id: notification.account_id,
          notification: notification.push_event_data,
          unread_count: 1,
          count: 1
        }
      )

      listener.notification_updated(event)
    end
  end

  describe '#conversation_updated' do
    let(:event_name) { :'conversation.updated' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent, is_private: false) }

    before do
      conversation.add_labels(['support'])
      # Agents and the contact now get one broadcast each. Every example below
      # pins exactly one of the two, so the other still has to be allowed
      # through or it trips the constrained expectation.
      allow(ActionCableBroadcastJob).to receive(:perform_later)
    end

    it 'sends the full conversation with label data to inbox members' do
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(conversation.reload.push_event_data[:labels]).to eq(conversation.labels.pluck(:name))
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.conversation_updated(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token],
        'conversation.updated',
        conversation.push_event_data.merge(account_id: account.id)
      )
    end

    it 'does not send the update to the web widget session, which has no handler for it' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).once.with(
        [agent.pubsub_token, admin.pubsub_token], 'conversation.updated', anything
      )

      listener.conversation_updated(event)
    end

    it 'merges broadcast_metadata into the payload as event_metadata' do
      metadata = { source: 'reaction_toggle' }
      tagged_event = Events::Base.new(event_name, Time.zone.now, conversation: conversation, broadcast_metadata: metadata)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token],
        'conversation.updated',
        conversation.push_event_data.merge(account_id: account.id, event_metadata: metadata)
      )
      listener.conversation_updated(tagged_event)
    end
  end

  # The bug this guards: `last_non_activity_message` filters `message_type` but not `private`, so a
  # trailing private note is exactly what it resolves to. A web widget session gets upstream's widget
  # payload (`widget_data`), and a Client API session gets the contact allowlist instead of the
  # agents' payload. Assert on the note's literal content so the example fails loudly if either copy
  # is ever re-unified with the agents' one, whatever key the content ends up under.
  #
  # The allowlist example is the general guard: the private note is only the leak that was found
  # first, and asserting on the shape catches the next field someone adds to `push_data`.
  describe 'private note leakage to the contact' do
    let(:secret) { 'Internal only: customer has an overdue invoice' }

    def contact_bound_payloads(token)
      payloads = []
      allow(ActionCableBroadcastJob).to receive(:perform_later) do |tokens, _event, payload, **options|
        payloads << payload if tokens.include?(token)
        payloads << options[:widget_data] if options[:widget_members].to_a.include?(token)
      end
      yield
      payloads
    end

    def broadcast_every_conversation_event(conversation)
      listener.conversation_created(Events::Base.new(:'conversation.created', Time.zone.now, conversation: conversation))
      listener.conversation_status_changed(Events::Base.new(:'conversation.status_changed', Time.zone.now, conversation: conversation))
      listener.conversation_updated(Events::Base.new(:'conversation.updated', Time.zone.now, conversation: conversation))
      # The typing events are the highest-frequency vector, firing per keystroke rather than per status change.
      %i[conversation_typing_on conversation_recording conversation_typing_off].each do |method_name|
        listener.public_send(method_name, Events::Base.new(method_name, Time.zone.now, conversation: conversation, user: agent, is_private: true))
      end
    end

    context 'with a web widget session' do
      before do
        create(:message, conversation: conversation, account: account, inbox: inbox,
                         message_type: :outgoing, private: true, content: secret)
      end

      it 'keeps the private note out of every payload the widget gets' do
        payloads = contact_bound_payloads(conversation.contact_inbox.pubsub_token) { broadcast_every_conversation_event(conversation) }

        # conversation.updated does not reach the widget, which has no handler for it.
        expect(payloads.size).to eq(5)
        expect(payloads.to_s).not_to include(secret)
      end
    end

    context 'with a Client API session' do
      let(:api_inbox) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }
      let(:api_conversation) { create(:conversation, account: account, inbox: api_inbox, assignee: agent) }
      let(:client_token) { api_conversation.contact_inbox.pubsub_token }

      before do
        create(:inbox_member, inbox: api_inbox, user: agent)
        create(:message, conversation: api_conversation, account: account, inbox: api_inbox,
                         message_type: :outgoing, private: true, content: secret)
      end

      it 'keeps the private note out of every payload the session gets' do
        payloads = contact_bound_payloads(client_token) { broadcast_every_conversation_event(api_conversation) }

        expect(payloads.size).to eq(6)
        expect(payloads.to_s).not_to include(secret)
      end

      # Asserts on the SHAPE of the contact payload instead of on any one field, so the next key added
      # to `push_data` (CE, Enterprise or Pro) fails here rather than shipping to the contact's browser.
      it 'never sends the session a conversation key outside the allowlist' do
        payloads = contact_bound_payloads(client_token) do
          listener.conversation_created(Events::Base.new(:'conversation.created', Time.zone.now, conversation: api_conversation))
          listener.conversation_status_changed(Events::Base.new(:'conversation.status_changed', Time.zone.now, conversation: api_conversation))
          listener.conversation_updated(Events::Base.new(:'conversation.updated', Time.zone.now, conversation: api_conversation))
        end

        allowed = Conversations::EventDataPresenter::CONTACT_PUSH_KEYS +
                  Conversations::EventDataPresenter::CONTACT_SAFE_EVENT_KEYS +
                  %i[account_id]
        expect(payloads.size).to eq(3)
        expect(payloads.flat_map(&:keys).uniq - allowed).to be_empty
      end

      it 'keeps the operational fields agents work with out of the session copy' do
        api_conversation.update!(custom_attributes: { internal_score: 'high risk' }, priority: 'urgent')
        api_conversation.add_labels(['inadimplente'])

        payloads = contact_bound_payloads(client_token) do
          listener.conversation_updated(Events::Base.new(:'conversation.updated', Time.zone.now, conversation: api_conversation))
        end

        expect(payloads.first.keys).not_to include(:labels, :custom_attributes, :priority, :meta, :additional_attributes, :performer)
        expect(payloads.to_s).not_to include('inadimplente', 'high risk')
      end
    end

    it 'still gives the agents the private note as the chat list preview' do
      create(:message, conversation: conversation, account: account, inbox: inbox,
                       message_type: :outgoing, private: true, content: secret)
      allow(ActionCableBroadcastJob).to receive(:perform_later)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_including(agent.pubsub_token),
        'conversation.updated',
        hash_including(last_non_activity_message: hash_including(content: secret))
      )

      listener.conversation_updated(Events::Base.new(:'conversation.updated', Time.zone.now, conversation: conversation))
    end
  end

  shared_examples 'scheduled message event broadcast' do |method_name, event_name|
    it 'broadcasts to account admins and inbox members' do
      scheduled_message = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: agent)
      event = Events::Base.new(event_name, Time.zone.now, scheduled_message: scheduled_message)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        event_name,
        scheduled_message.push_event_data.merge(account_id: account.id)
      )

      listener.public_send(method_name, event)
    end
  end

  describe '#scheduled_message_created' do
    it_behaves_like 'scheduled message event broadcast', :scheduled_message_created, 'scheduled_message.created'
  end

  describe '#scheduled_message_updated' do
    it_behaves_like 'scheduled message event broadcast', :scheduled_message_updated, 'scheduled_message.updated'
  end

  describe '#scheduled_message_deleted' do
    it_behaves_like 'scheduled message event broadcast', :scheduled_message_deleted, 'scheduled_message.deleted'
  end

  describe '#inbox_provider_connection_updated' do
    # Only Channel::Whatsapp emits this event, and only it knows how to present the
    # admin half of the payload. The generic inbox the rest of this file uses would be
    # testing a combination that cannot happen.
    let!(:inbox) { create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false).inbox }
    let(:event_name) { :'inbox.provider_connection_updated' }
    let(:provider_connection) do
      { 'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,qr', 'error' => nil }
    end
    let(:event) { Events::Base.new(event_name, Time.zone.now, inbox: inbox, provider_connection: provider_connection) }

    it 'sends only the connection status to non-admin agents' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token],
        'inbox.provider_connection_updated',
        { inbox_id: inbox.id, provider_connection: { connection: 'connecting' }, account_id: account.id }
      )
      allow(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], anything, anything)

      listener.inbox_provider_connection_updated(event)
    end

    it 'sends the QR code and error only to administrators' do
      allow(ActionCableBroadcastJob).to receive(:perform_later).with([agent.pubsub_token], anything, anything)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [admin.pubsub_token],
        'inbox.provider_connection_updated',
        {
          inbox_id: inbox.id,
          provider_connection: { connection: 'connecting', qr_data_url: 'data:image/png;base64,qr', error: nil },
          account_id: account.id
        }
      )

      listener.inbox_provider_connection_updated(event)
    end

    # The push and the REST payload are built by the same presenter now. Before that they
    # were built separately, so a live update dropped the pairing code until something
    # refetched the inbox. `error` is already a sentence by this point: the key is
    # resolved when the state is persisted, because a broadcast has no single reader
    # whose locale could be used.
    context 'when the inbox is on a session provider' do
      let!(:inbox) do
        create(:channel_whatsapp, account: account, provider: 'uazapi',
                                  validate_provider_config: false, sync_templates: false).inbox
      end
      let(:provider_connection) do
        { 'connection' => 'close', 'error' => I18n.t('errors.inboxes.channel.provider_connection.logged_out'),
          'pairing_code' => 'K7QP-2M4X' }
      end

      it 'pushes the error and the pairing details to administrators' do
        allow(ActionCableBroadcastJob).to receive(:perform_later).with([agent.pubsub_token], anything, anything)
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [admin.pubsub_token],
          'inbox.provider_connection_updated',
          {
            inbox_id: inbox.id,
            provider_connection: {
              connection: 'close', qr_data_url: nil, pairing_code: 'K7QP-2M4X',
              error: I18n.t('errors.inboxes.channel.provider_connection.logged_out')
            },
            account_id: account.id
          }
        )

        listener.inbox_provider_connection_updated(event)
      end

      it 'still tells agents nothing but the connection status' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token],
          'inbox.provider_connection_updated',
          { inbox_id: inbox.id, provider_connection: { connection: 'close' }, account_id: account.id }
        )
        allow(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], anything, anything)

        listener.inbox_provider_connection_updated(event)
      end
    end

    context 'when a reach-out time-lock is present' do
      let(:provider_connection) do
        { 'connection' => 'connecting', 'reachout_time_lock' => { 'is_active' => true, 'time_enforcement_ends' => '2026-06-19T21:52:39.000Z' } }
      end

      it 'includes the lock in the agent broadcast (agents see the banner)' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token],
          'inbox.provider_connection_updated',
          {
            inbox_id: inbox.id,
            provider_connection: {
              connection: 'connecting',
              reachout_time_lock: { 'is_active' => true, 'time_enforcement_ends' => '2026-06-19T21:52:39.000Z' }
            },
            account_id: account.id
          }
        )
        allow(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], anything, anything)

        listener.inbox_provider_connection_updated(event)
      end
    end

    context 'when a send stall is present' do
      let(:provider_connection) do
        { 'connection' => 'open', 'send_stall' => { 'consecutive_timeouts' => 3, 'action' => 'suppressed' } }
      end

      # The push is the only thing that reaches an agent already sitting in the
      # conversation: the REST payload was fetched before the stall started.
      it 'includes the stall in the agent broadcast' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token],
          'inbox.provider_connection_updated',
          {
            inbox_id: inbox.id,
            provider_connection: {
              connection: 'open',
              send_stall: { 'consecutive_timeouts' => 3, 'action' => 'suppressed' }
            },
            account_id: account.id
          }
        )
        allow(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], anything, anything)

        listener.inbox_provider_connection_updated(event)
      end
    end

    context 'when the connection is being rerouted' do
      let(:provider_connection) { { 'connection' => 'reconnecting', 'rerouting' => true } }

      # A proxy change, which comes back on its own. The agent gets no error string, so
      # without the flag a deliberate reconnect and a real outage read the same.
      it 'tells the agent the reconnect is deliberate' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token],
          'inbox.provider_connection_updated',
          { inbox_id: inbox.id, provider_connection: { connection: 'reconnecting', rerouting: true }, account_id: account.id }
        )
        allow(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], anything, anything)

        listener.inbox_provider_connection_updated(event)
      end
    end

    context 'when a new-chat cap is present' do
      let(:provider_connection) do
        { 'connection' => 'open', 'new_chat_cap' => { 'capping_status' => 'CAPPED', 'total_quota' => 100, 'used_quota' => 100 } }
      end

      it 'includes the cap in the agent broadcast' do
        expect(ActionCableBroadcastJob).to receive(:perform_later).with(
          [agent.pubsub_token],
          'inbox.provider_connection_updated',
          {
            inbox_id: inbox.id,
            provider_connection: {
              connection: 'open',
              new_chat_cap: { 'capping_status' => 'CAPPED', 'total_quota' => 100, 'used_quota' => 100 }
            },
            account_id: account.id
          }
        )
        allow(ActionCableBroadcastJob).to receive(:perform_later).with([admin.pubsub_token], anything, anything)

        listener.inbox_provider_connection_updated(event)
      end
    end
  end

  describe '#conversation_status_changed' do
    let!(:event) { Events::Base.new(:'conversation.status_changed', Time.zone.now, conversation: conversation) }

    it 'sends the full conversation to agents and the widget payload to the web widget session in one job' do
      allow(ActionCableBroadcastJob).to receive(:perform_later)

      listener.conversation_status_changed(event)

      expect(ActionCableBroadcastJob).to have_received(:perform_later).once.with(
        [agent.pubsub_token, admin.pubsub_token],
        'conversation.status_changed',
        conversation.push_event_data.merge(account_id: account.id),
        widget_members: [conversation.contact_inbox.pubsub_token],
        widget_data: conversation.widget_push_event_data.merge(account_id: account.id)
      )
    end
  end

  describe '#conversation_unread_count_changed' do
    let(:event_name) { :'conversation.unread_count_changed' }
    let!(:agent_without_inbox_access) { create(:user, account: account, role: :agent) }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

    before do
      account.enable_features!(:conversation_unread_counts)
    end

    it 'sends a lightweight refresh event to inbox agents and admins' do
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        'conversation.unread_count_changed',
        {
          account_id: account.id
        }
      )

      listener.conversation_unread_count_changed(event)
    end

    it 'does not broadcast unread count refresh to agents outside the inbox' do
      expect(ActionCableBroadcastJob).not_to receive(:perform_later).with(
        array_including(agent_without_inbox_access.pubsub_token),
        anything,
        anything
      )

      listener.conversation_unread_count_changed(event)
    end

    it 'does not broadcast when conversation unread counts feature is disabled' do
      account.disable_features!(:conversation_unread_counts)

      expect(ActionCableBroadcastJob).not_to receive(:perform_later)

      listener.conversation_unread_count_changed(event)
    end

    it 'supports deleted conversation data' do
      event = Events::Base.new(
        event_name,
        Time.zone.now,
        conversation_data: {
          id: conversation.id,
          account_id: account.id,
          inbox_id: conversation.inbox_id
        }
      )

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        a_collection_containing_exactly(agent.pubsub_token, admin.pubsub_token),
        'conversation.unread_count_changed',
        {
          account_id: account.id
        }
      )

      listener.conversation_unread_count_changed(event)
    end
  end

  describe 'internal chat notifications of a member without internal_chat.access' do
    let(:channel) { create(:internal_chat_channel, :dm, account: account) }
    let(:message) { create(:internal_chat_message, account: account, channel: channel, sender: admin) }
    let(:notification) do
      create(:notification, account: account, user: agent, notification_type: 'internal_chat_new_message',
                            primary_actor: channel, secondary_actor: message)
    end

    before do
      notification
      stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })
      allow(ActionCableBroadcastJob).to receive(:perform_later)
    end

    it 'does not deliver their update' do
      listener.notification_updated(Events::Base.new(:'notification.updated', Time.zone.now, notification: notification))

      expect(ActionCableBroadcastJob).not_to have_received(:perform_later)
    end
  end
end
