require 'rails_helper'

RSpec.describe Conversations::MarkMessagesAsReadJob do
  subject(:job) { described_class.perform_later(account) }

  let!(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account, contact_last_seen_at: DateTime.now.utc) }
  let!(:message) { create(:message, conversation: conversation, message_type: 'outgoing', status: 'sent', created_at: 1.day.ago) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account)
      .on_queue('low')
  end

  context 'when called' do
    it 'marks all sent messages in a conversation as read' do
      expect do
        described_class.perform_now(conversation)
        message.reload
      end.to change(message, :status).from('sent').to('read')
    end

    it 'marks all delivered messages in a conversation as read' do
      message.update!(status: 'delivered')
      expect do
        described_class.perform_now(conversation)
        message.reload
      end.to change(message, :status).from('delivered').to('read')
    end

    it 'marks all templates messages in a conversation as read' do
      message.update!(status: 'delivered', message_type: 'template')
      expect do
        described_class.perform_now(conversation)
        message.reload
      end.to change(message, :status).from('delivered').to('read')
    end

    it 'does not mark failed messages as read' do
      message.update!(status: 'failed')
      expect do
        described_class.perform_now(conversation)
      end.not_to change(message.reload, :status)
    end

    it 'does not mark incoming messages as read' do
      message.update!(message_type: 'incoming')
      expect do
        described_class.perform_now(conversation)
      end.not_to change(message.reload, :status)
    end

    it 'does not mark messages created after the contact last seen time as read' do
      message.update!(created_at: DateTime.now.utc)
      expect do
        described_class.perform_now(conversation)
      end.not_to change(message.reload, :status)
    end
  end
end
