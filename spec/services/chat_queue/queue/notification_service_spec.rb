require 'rails_helper'

RSpec.describe ChatQueue::Queue::NotificationService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(conversation: conversation) }

  let(:queue_text) { I18n.t('queue.notifications.queue_message') }
  let(:assigned_text) { I18n.t('queue.notifications.assigned_message') }

  describe '#send_queue_notification' do
    it 'creates a queue template message with correct attributes' do
      expect do
        service.send_queue_notification
      end.to change { conversation.messages.count }.by(1)

      message = conversation.messages.last
      expect(message.message_type).to eq('template')
      expect(message.content).to eq(queue_text)
      expect(message.account_id).to eq(account.id)
      expect(message.inbox_id).to eq(inbox.id)
    end

    it 'creates message for the correct conversation' do
      other_conversation = create(:conversation, account: account, inbox: inbox)

      service.send_queue_notification

      expect(conversation.messages.template.count).to eq(1)
      expect(other_conversation.messages.template.count).to eq(0)
    end
  end

  describe '#send_assigned_notification' do
    it 'creates an assigned template message with correct attributes' do
      expect do
        service.send_assigned_notification
      end.to change { conversation.messages.count }.by(1)

      message = conversation.messages.last
      expect(message.message_type).to eq('template')
      expect(message.content).to eq(assigned_text)
      expect(message.account_id).to eq(account.id)
      expect(message.inbox_id).to eq(inbox.id)
    end

    it 'can be called multiple times' do
      expect do
        2.times { service.send_assigned_notification }
      end.to change { conversation.messages.count }.by(2)

      messages = conversation.messages.template.last(2)
      expect(messages.map(&:content)).to all(eq(assigned_text))
    end
  end

  describe 'error handling' do
    let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

    before do
      allow(conversation).to receive(:account_id).and_return(nil)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
    end

    it 'captures exception when queue notification fails' do
      service.send_queue_notification

      expect(ChatwootExceptionTracker).to have_received(:new).with(
        an_instance_of(ActiveRecord::RecordInvalid),
        account: conversation.account
      )
      expect(exception_tracker).to have_received(:capture_exception)
    end

    it 'captures exception when assigned notification fails' do
      service.send_assigned_notification

      expect(ChatwootExceptionTracker).to have_received(:new).with(
        an_instance_of(ActiveRecord::RecordInvalid),
        account: conversation.account
      )
      expect(exception_tracker).to have_received(:capture_exception)
    end

    it 'does not raise error when message creation fails' do
      expect { service.send_queue_notification }.not_to raise_error
      expect { service.send_assigned_notification }.not_to raise_error
    end

    it 'does not create message when error occurs' do
      expect do
        service.send_queue_notification
      end.not_to(change(Message, :count))

      expect do
        service.send_assigned_notification
      end.not_to(change(Message, :count))
    end
  end

  describe 'integration with multiple conversations' do
    let(:conversation2) { create(:conversation, account: account, inbox: inbox) }
    let(:service2) { described_class.new(conversation: conversation2) }

    it 'creates messages in separate conversations' do
      service.send_queue_notification
      service2.send_assigned_notification

      expect(conversation.messages.template.count).to eq(1)
      expect(conversation2.messages.template.count).to eq(1)

      expect(conversation.messages.last.content).to eq(queue_text)
      expect(conversation2.messages.last.content).to eq(assigned_text)
    end
  end
end
