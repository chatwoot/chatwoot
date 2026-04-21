require 'rails_helper'
describe HookListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
  let(:contact_event) { Events::Base.new('contact.updated', Time.zone.now, contact: conversation.contact) }
  let(:conversation_event) { Events::Base.new('conversation.created', Time.zone.now, conversation: conversation) }

  describe '#message_created' do
    let(:event_name) { 'message.created' }

    context 'when hook is not configured' do
      it 'does not trigger hook job' do
        expect(HookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(event)
      end
    end

    context 'when hook is configured' do
      it 'triggers hook job' do
        hook = create(:integrations_hook, account: account)
        expect(HookJob).to receive(:perform_later).with(hook, 'message.created', message: message).once
        listener.message_created(event)
      end
    end
  end

  describe '#message_updated' do
    let(:event_name) { 'message.updated' }

    context 'when hook is not configured' do
      it 'does not trigger hook job' do
        expect(HookJob).to receive(:perform_later).exactly(0).times
        listener.message_updated(event)
      end
    end

    context 'when hook is configured' do
      it 'triggers hook job' do
        hook = create(:integrations_hook, :dialogflow, account: account, inbox: inbox)
        expect(HookJob).to receive(:perform_later).with(hook, 'message.updated', message: message).once
        listener.message_updated(event)
      end
    end
  end

  describe 'hook job enqueuing behavior' do
    let(:event_name) { 'message.created' }

    context 'when app_id is not in the allowed list' do
      it 'does not enqueue the job' do
        create(:integrations_hook, account: account, app_id: 'unsupported_app')
        expect(HookJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'when hook is enabled and app_id is supported' do
      it 'enqueues the job for slack' do
        hook = create(:integrations_hook, account: account)
        expect(HookJob).to receive(:perform_later).with(hook, event_name, message: message)

        listener.message_created(event)
      end

      it 'enqueues the job for dialogflow' do
        hook = create(:integrations_hook, :dialogflow, account: account, inbox: inbox)
        expect(HookJob).to receive(:perform_later).with(hook, event_name, message: message)

        listener.message_created(event)
      end

      it 'enqueues the job for google_translate' do
        hook = create(:integrations_hook, :google_translate, account: account)
        expect(HookJob).to receive(:perform_later).with(hook, event_name, message: message)

        listener.message_created(event)
      end
    end

    context 'with disabled hook' do
      it 'does not enqueue job for disabled hooks' do
        create(:integrations_hook, account: account, status: 'disabled', app_id: 'slack')
        expect(HookJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'with unsupported app_id and event combination' do
      it 'does not enqueue job for unsupported app_id' do
        create(:integrations_hook, account: account, app_id: 'unsupported_app')
        expect(HookJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'with leadsquared hook' do
      let(:hook) { create(:integrations_hook, :leadsquared, account: account) }

      before do
        account.enable_features(:crm_integration)
      end

      it 'enqueues the job for conversation.created' do
        expect(HookJob)
          .to receive(:perform_later)
          .with(hook, 'conversation.created', { conversation: conversation })

        listener.conversation_created(conversation_event)
      end

      it 'enqueues the job for contact.updated' do
        expect(HookJob)
          .to receive(:perform_later)
          .with(hook, 'contact.updated', { contact: conversation.contact })

        listener.contact_updated(contact_event)
      end
    end
  end
end
