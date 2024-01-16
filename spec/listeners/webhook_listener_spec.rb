require 'rails_helper'
describe WebhookListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:report_identity) { Reports::UpdateAccountIdentity.new(account, Time.zone.now) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:message_created_event) { Events::Base.new(event_name, Time.zone.now, message: message) }
  let!(:conversation_created_event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }
  let!(:contact_event) { Events::Base.new(event_name, Time.zone.now, contact: contact) }

  describe '#message_created' do
    let(:event_name) { :'message.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(message_created_event)
      end
    end

    context 'when webhook is configured and event is subscribed' do
      it 'triggers the webhook event' do
        webhook = create(:webhook, inbox: inbox, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, message.webhook_data.merge(event: 'message_created')).once
        listener.message_created(message_created_event)
      end
    end

    context 'when webhook is configured and event is not subscribed' do
      it 'does not trigger the webhook event' do
        create(:webhook, subscriptions: ['conversation_created'], inbox: inbox, account: account)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.message_created(message_created_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: api_inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url, api_message.webhook_data.merge(event: 'message_created'),
                                                           :api_inbox_webhook).once
        listener.message_created(api_event)
      end

      it 'does not trigger webhook if webhook_url is not present' do
        channel_api = create(:channel_api, webhook_url: nil, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: channel_api.inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.message_created(api_event)
      end
    end
  end

  describe '#conversation_created' do
    let(:event_name) { :'conversation.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.conversation_created(conversation_created_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, conversation.webhook_data.merge(event: 'conversation_created')).once
        listener.conversation_created(conversation_created_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation)
        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url,
                                                           api_conversation.webhook_data.merge(event: 'conversation_created'),
                                                           :api_inbox_webhook).once
        listener.conversation_created(api_event)
      end

      it 'does not trigger webhook if webhook_url is not present' do
        channel_api = create(:channel_api, webhook_url: nil, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.conversation_created(api_event)
      end
    end
  end

  describe '#conversation_updated' do
    let(:custom_attributes) { { test: nil } }
    let!(:conversation_updated_event) do
      Events::Base.new(
        event_name, Time.zone.now,
        conversation: conversation.reload,
        changed_attributes: {
          custom_attributes: [{ test: nil }, { test: 'testing custom attri webhook' }]
        }
      )
    end
    let(:event_name) { :'conversation.updated' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.conversation_updated(conversation_updated_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)

        conversation.update(custom_attributes: { test: 'testing custom attri webhook' })

        expect(WebhookJob).to receive(:perform_later).with(
          webhook.url,
          conversation.webhook_data.merge(
            event: 'conversation_updated',
            changed_attributes: [
              {
                custom_attributes: {
                  previous_value: { test: nil },
                  current_value: { test: 'testing custom attri webhook' }
                }
              }
            ]
          )
        ).once

        listener.conversation_updated(conversation_updated_event)
      end
    end
  end

  describe '#contact_created' do
    let(:event_name) { :'contact.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.contact_created(contact_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, contact.webhook_data.merge(event: 'contact_created')).once
        listener.contact_created(contact_event)
      end
    end
  end

  describe '#contact_updated' do
    let(:event_name) { :'contact.updated' }
    let!(:contact_updated_event) { Events::Base.new(event_name, Time.zone.now, contact: contact, changed_attributes: changed_attributes) }
    let(:changed_attributes) { { 'name' => ['Jane', 'Jane Doe'] } }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.contact_updated(contact_updated_event)
      end
    end

    context 'when webhook is configured and there is no changed attributes' do
      let(:changed_attributes) { {} }

      it 'triggers webhook' do
        create(:webhook, account: account)
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.contact_updated(contact_updated_event)
      end
    end

    context 'when webhook is configured and there are changed attributes' do
      it 'triggers webhook' do
        webhook = create(:webhook, account: account)
        expect(WebhookJob).to receive(:perform_later).with(
          webhook.url,
          contact.webhook_data.merge(
            event: 'contact_updated',
            changed_attributes: [{ 'name' => { :current_value => 'Jane Doe', :previous_value => 'Jane' } }]
          )
        ).once
        listener.contact_updated(contact_updated_event)
      end
    end
  end

  describe '#inbox_created' do
    let(:event_name) { :'inbox.created' }
    let!(:inbox_created_event) { Events::Base.new(event_name, Time.zone.now, inbox: inbox) }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.inbox_created(inbox_created_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        inbox_data = Inbox::EventDataPresenter.new(inbox).push_data
        webhook = create(:webhook, account: account, subscriptions: ['inbox_created'])
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, inbox_data.merge(event: 'inbox_created')).once
        listener.inbox_created(inbox_created_event)
      end
    end
  end

  describe '#inbox_updated' do
    let(:event_name) { :'inbox.updated' }
    let!(:inbox_updated_event) { Events::Base.new(event_name, Time.zone.now, inbox: inbox, changed_attributes: changed_attributes) }
    let(:changed_attributes) { {} }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.inbox_updated(inbox_updated_event)
      end
    end

    context 'when webhook is configured and there are no changed attributes' do
      it 'triggers webhook' do
        create(:webhook, account: account, subscriptions: ['inbox_updated'])
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.inbox_updated(inbox_updated_event)
      end
    end

    context 'when webhook is configured' do
      let(:changed_attributes) { { 'name' => ['Inbox 1', inbox.name] } }

      it 'triggers webhook' do
        webhook = create(:webhook, account: account, subscriptions: ['inbox_updated'])

        inbox_data = Inbox::EventDataPresenter.new(inbox).push_data
        changed_attributes_data = [{ 'name' => { 'previous_value': 'Inbox 1', 'current_value': inbox.name } }]

        expect(WebhookJob).to receive(:perform_later).with(
          webhook.url,
          inbox_data.merge(event: 'inbox_updated', changed_attributes: changed_attributes_data)
        ).once

        listener.inbox_updated(inbox_updated_event)
      end
    end
  end
end
