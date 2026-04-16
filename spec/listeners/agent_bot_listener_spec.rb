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
          conversation.update!(assignee_agent_bot: conversation_bot, assignee: nil)
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
          hash_including(event: 'conversation_status_changed', changed_attributes: anything),
          :agent_bot_webhook,
          hash_including(secret: agent_bot.secret)
        ).once
        listener.conversation_status_changed(event)
      end
    end

    context 'when conversation is assigned to an agent bot' do
      before do
        conversation.update!(assignee_agent_bot: agent_bot, assignee: nil)
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
        conversation.update!(assignee_agent_bot: agent_bot, assignee: nil)
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
end
