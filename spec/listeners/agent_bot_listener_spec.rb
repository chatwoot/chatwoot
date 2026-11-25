require 'rails_helper'
describe AgentBotListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent_bot) { create(:agent_bot) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  describe '#message_created' do
    let(:event_name) { 'message.created' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
    let!(:message) do
      create(:message, message_type: 'outgoing',
                       account: account, inbox: inbox, conversation: conversation)
    end

    context 'when agent bot is not configured' do
      it 'does not send message to agent bot' do
        expect(AgentBots::WebhookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(event)
      end
    end

    context 'when agent bot is configured' do
      it 'sends message to agent bot' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url, message.webhook_data.merge(event: 'message_created'),
          :agent_bot_webhook, secret: agent_bot.secret, delivery_id: instance_of(String)
        ).once
        listener.message_created(event)
      end

      it 'does not send message to agent bot if url is empty' do
        agent_bot = create(:agent_bot, outgoing_url: '')
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.message_created(event)
      end

      context 'when conversation has a different assignee agent bot' do
        let!(:conversation_bot) { create(:agent_bot) }

        before do
          create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
          conversation.update!(ai_assignee: conversation_bot, assignee: nil)
        end

        it 'sends message to both bots exactly once' do
          payload = message.webhook_data.merge(event: 'message_created')

          expect(AgentBots::WebhookJob).to receive(:perform_later).with(
            agent_bot.outgoing_url, payload, :agent_bot_webhook,
            secret: agent_bot.secret, delivery_id: instance_of(String)
          ).once
          expect(AgentBots::WebhookJob).to receive(:perform_later).with(
            conversation_bot.outgoing_url, payload, :agent_bot_webhook,
            secret: conversation_bot.secret, delivery_id: instance_of(String)
          ).once

          listener.message_created(event)
        end
      end
    end
  end

  describe '#conversation_status_changed' do
    let(:event_name) { 'conversation.status_changed' }
    let(:changed_attributes) { { status: %w[open pending] } }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, changed_attributes: changed_attributes) }

    context 'when agent bot is not configured' do
      it 'does not send webhook' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.conversation_status_changed(event)
      end
    end

    context 'when agent bot is configured on inbox' do
      it 'sends webhook with changed_attributes' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url,
          hash_including(event: 'conversation_status_changed', account: account.webhook_data, changed_attributes: anything),
          :agent_bot_webhook,
          hash_including(secret: agent_bot.secret)
        ).once
        listener.conversation_status_changed(event)
      end
    end

    context 'when conversation is assigned to an agent bot' do
      before do
        conversation.update!(ai_assignee: agent_bot, assignee: nil)
      end

      it 'sends webhook to the assigned agent bot' do
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url,
          hash_including(event: 'conversation_status_changed', changed_attributes: anything),
          :agent_bot_webhook,
          hash_including(secret: agent_bot.secret)
        ).once
        listener.conversation_status_changed(event)
      end
    end
  end

  describe '#conversation_updated' do
    let(:event_name) { 'conversation.updated' }

    context 'when agent bot is not configured' do
      let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

      it 'does not send webhook' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.conversation_updated(event)
      end
    end

    context 'when agent bot is configured on inbox' do
      let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

      it 'sends webhook to the inbox agent bot with changed_attributes' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url,
          conversation.webhook_data.merge(event: 'conversation_updated', changed_attributes: nil),
          :agent_bot_webhook, secret: agent_bot.secret, delivery_id: instance_of(String)
        ).once
        listener.conversation_updated(event)
      end
    end

    context 'when conversation is assigned to an agent bot' do
      let!(:event) do
        Events::Base.new(event_name, Time.zone.now, conversation: conversation,
                                                    changed_attributes: { 'assignee_agent_bot_id' => [nil, agent_bot.id] })
      end

      before do
        conversation.update!(ai_assignee: agent_bot, assignee: nil)
      end

      it 'sends webhook with changed_attributes to the assigned agent bot' do
        expected_changed_attributes = [{ 'assignee_agent_bot_id' => { previous_value: nil, current_value: agent_bot.id } }]
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url,
          conversation.webhook_data.merge(
            event: 'conversation_updated',
            changed_attributes: expected_changed_attributes
          ),
          :agent_bot_webhook, secret: agent_bot.secret, delivery_id: instance_of(String)
        ).once
        listener.conversation_updated(event)
      end
    end
  end

  describe '#conversation_resolved' do
    let(:event_name) { 'conversation.resolved' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

    context 'when agent bot is configured' do
      it 'sends account details in the conversation payload' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url,
          hash_including(event: 'conversation_resolved', account: account.webhook_data),
          :agent_bot_webhook,
          hash_including(secret: agent_bot.secret)
        ).once
        listener.conversation_resolved(event)
      end
    end
  end

  describe '#webwidget_triggered' do
    let(:event_name) { 'webwidget.triggered' }

    context 'when agent bot is configured' do
      it 'send message to agent bot URL' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        event = double
        allow(event).to receive(:data)
          .and_return(
            {
              contact_inbox: conversation.contact_inbox,
              event_info: { country: 'US' }
            }
          )
        expect(AgentBots::WebhookJob).to receive(:perform_later)
          .with(
            agent_bot.outgoing_url,
            conversation.contact_inbox.webhook_data.merge(event: 'webwidget_triggered', event_info: { country: 'US' }),
            :agent_bot_webhook, secret: agent_bot.secret, delivery_id: instance_of(String)
          ).once

        listener.webwidget_triggered(event)
      end
    end
  end

  describe 'observers' do
    let!(:observer_bot) { create(:agent_bot, outgoing_url: 'https://observer.example') }
    let(:event_name) { 'message.created' }
    let!(:message) do
      create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation)
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
    let(:payload) { message.webhook_data.merge(event: 'message_created') }

    before { create(:agent_bot_observer, inbox: inbox, agent_bot: observer_bot) }

    it 'delivers a message on a conversation a human holds, under the observer webhook type' do
      expect(conversation.status).to eq('open')
      expect(conversation.assignee).to eq(user)
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        observer_bot.outgoing_url, payload, :agent_bot_observer_webhook,
        secret: observer_bot.secret, delivery_id: instance_of(String)
      ).once

      listener.message_created(event)
    end

    it 'delivers to the responder and to the observer, each under its own type' do
      create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        agent_bot.outgoing_url, payload, :agent_bot_webhook,
        secret: agent_bot.secret, delivery_id: instance_of(String)
      ).once
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        observer_bot.outgoing_url, payload, :agent_bot_observer_webhook,
        secret: observer_bot.secret, delivery_id: instance_of(String)
      ).once

      listener.message_created(event)
    end

    it 'delivers once, as the responder, to a bot that both answers and observes the inbox' do
      create(:agent_bot_inbox, inbox: inbox, agent_bot: observer_bot)
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        observer_bot.outgoing_url, payload, :agent_bot_webhook,
        secret: observer_bot.secret, delivery_id: instance_of(String)
      ).once

      listener.message_created(event)
    end

    it 'skips an observer whose bot was deleted and not yet cleaned up' do
      observer_bot.delete
      expect(AgentBots::WebhookJob).not_to receive(:perform_later)

      expect { listener.message_created(event) }.not_to raise_error
    end

    it 'delivers conversation events too' do
      resolved_event = Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation)
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        observer_bot.outgoing_url, conversation.webhook_data.merge(event: 'conversation_resolved'),
        :agent_bot_observer_webhook, secret: observer_bot.secret, delivery_id: instance_of(String)
      ).once

      listener.conversation_resolved(resolved_event)
    end
  end

  describe '#inbox_provider_connection_updated' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false)
    end
    let(:whatsapp_inbox) { channel.inbox }
    let(:connection) { { 'connection' => 'close', 'qr_data_url' => 'data:image/png;base64,QR', 'error' => 'logged out' } }
    let(:changed_at) { Time.zone.parse('2026-10-15T12:34:56.123456Z') }
    let(:event) do
      Events::Base.new('inbox.provider_connection_updated', changed_at,
                       inbox: whatsapp_inbox, provider_connection: connection, previous_connection: 'open')
    end
    let(:payload) do
      {
        event: 'inbox_provider_connection_updated',
        account: { id: account.id },
        inbox: { id: whatsapp_inbox.id, name: whatsapp_inbox.name, channel_type: 'Channel::Whatsapp', provider: 'baileys' },
        provider_connection: { connection: 'close' },
        previous_connection: 'open',
        changed_at: '2026-10-15T12:34:56.123456Z'
      }
    end

    it 'delivers the change to the responder bot without the QR or the error' do
      create(:agent_bot_inbox, inbox: whatsapp_inbox, agent_bot: agent_bot)
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        agent_bot.outgoing_url, payload, :agent_bot_webhook, secret: agent_bot.secret, delivery_id: instance_of(String)
      ).once

      listener.inbox_provider_connection_updated(event)
    end

    it 'delivers to an observer of the inbox under the observer type' do
      observer_bot = create(:agent_bot, outgoing_url: 'https://observer.example')
      create(:agent_bot_observer, inbox: whatsapp_inbox, agent_bot: observer_bot)
      expect(AgentBots::WebhookJob).to receive(:perform_later).with(
        observer_bot.outgoing_url, payload, :agent_bot_observer_webhook, secret: observer_bot.secret, delivery_id: instance_of(String)
      ).once

      listener.inbox_provider_connection_updated(event)
    end

    it 'delivers nothing when the write left the connection as it was' do
      create(:agent_bot_inbox, inbox: whatsapp_inbox, agent_bot: agent_bot)
      unchanged = Events::Base.new('inbox.provider_connection_updated', Time.zone.now,
                                   inbox: whatsapp_inbox, provider_connection: { 'connection' => 'connecting', 'qr_data_url' => 'QR2' },
                                   previous_connection: 'connecting')
      expect(AgentBots::WebhookJob).not_to receive(:perform_later)

      listener.inbox_provider_connection_updated(unchanged)
    end

    it 'is reached from the channel write, once per change of connection' do
      create(:agent_bot_inbox, inbox: whatsapp_inbox, agent_bot: agent_bot)
      channel.update_provider_connection!(connection: 'open')
      allow(AgentBots::WebhookJob).to receive(:perform_later)

      channel.update_provider_connection!(connection: 'open', epoch: 2)
      channel.update_provider_connection!(connection: 'close', error: 'logged out')

      expect(AgentBots::WebhookJob).to have_received(:perform_later).once
      expect(AgentBots::WebhookJob).to have_received(:perform_later).with(
        agent_bot.outgoing_url, payload.merge(changed_at: match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{6}Z\z/)),
        :agent_bot_webhook, secret: agent_bot.secret, delivery_id: instance_of(String)
      )
    end
  end
end
