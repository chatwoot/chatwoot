require 'rails_helper'

RSpec.describe ConversationReplyEmailJob, type: :job do
  let(:conversation) { create(:conversation) }
  let(:mailer) { double }
  let(:mailer_action) { double }

  before do
    allow(Conversation).to receive(:find).and_return(conversation)
    allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:reply_with_summary).and_return(mailer_action)
    allow(mailer).to receive(:reply_without_summary).and_return(mailer_action)
    allow(mailer_action).to receive(:deliver_later).and_return(true)
  end

  it 'enqueues on mailers queue' do
    ActiveJob::Base.queue_adapter = :test
    expect do
      described_class.perform_later(conversation.id, 123)
    end.to have_enqueued_job(described_class).on_queue('mailers')
  end

  it 'calls reply_with_summary when last incoming message was not email' do
    described_class.perform_now(conversation.id, 123)
    expect(mailer).to have_received(:reply_with_summary)
  end

  it 'calls reply_without_summary when last incoming message was email' do
    create(:message, conversation: conversation, message_type: :incoming, content_type: 'incoming_email')
    described_class.perform_now(conversation.id, 123)
    expect(mailer).to have_received(:reply_without_summary)
  end
end
