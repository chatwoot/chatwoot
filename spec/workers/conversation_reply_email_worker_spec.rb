require 'rails_helper'

Sidekiq::Testing.fake!
RSpec.describe ConversationReplyEmailWorker, type: :worker do
  let(:conversation) { build(:conversation, display_id: nil) }
  let(:message) { build(:message, conversation: conversation, content_type: 'incoming_email', inbox: conversation.inbox) }
  let(:mailer) { double }
  let(:mailer_action) { double }

  describe 'testing ConversationSummaryEmailWorker' do
    before do
      conversation.save!
      allow(Conversation).to receive(:find).and_return(conversation)
      allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
      allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:reply_with_summary).and_return(mailer_action)
      allow(mailer).to receive(:reply_without_summary).and_return(mailer_action)
      allow(mailer_action).to receive(:deliver_later).and_return(true)
    end

    it 'worker jobs are enqueued in the mailers queue' do
      described_class.perform_async
      expect(described_class.queue).to eq(:mailers)
    end

    it 'goes into the jobs array for testing environment' do
      expect do
        described_class.perform_async
      end.to change(described_class.jobs, :size).by(1)
      described_class.new.perform(1, message.id)
    end

    context 'with actions performed by the worker' do
      it 'calls ConversationSummaryMailer#reply_with_summary when last incoming message was not email' do
        described_class.new.perform(1, message.id)
        expect(mailer).to have_received(:reply_with_summary)
      end

      it 'calls ConversationSummaryMailer#reply_without_summary when last incoming message was from email' do
        message.save!
        described_class.new.perform(1, message.id)
        expect(mailer).to have_received(:reply_without_summary)
      end
    end
  end
end
