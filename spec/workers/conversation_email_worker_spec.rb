require 'rails_helper'

Sidekiq::Testing.fake!
RSpec.describe ConversationEmailWorker, type: :worker do
  let(:perform_at) { (Time.zone.today + 6.hours).to_datetime }
  let(:scheduled_job) { described_class.perform_at(perform_at, 1, Time.zone.now) }
  let(:conversation) { build(:conversation, display_id: nil) }

  describe 'testing ConversationEmailWorker' do
    before do
      conversation.save!
      allow(Conversation).to receive(:find).and_return(conversation)
      mailer = double
      allow(ConversationMailer).to receive(:new_message).and_return(mailer)
      allow(mailer).to receive(:deliver_later).and_return(true)
    end

    it 'worker jobs are enqueued in the mailers queue' do
      described_class.perform_async
      assert_equal :mailers, described_class.queue
    end

    it 'goes into the jobs array for testing environment' do
      expect do
        described_class.perform_async
      end.to change(described_class.jobs, :size).by(1)
      described_class.new.perform(1, Time.zone.now)
    end

    context 'with actions performed by the worker' do
      it 'calls ConversationMailer' do
        described_class.new.perform(1, Time.zone.now)
        expect(ConversationMailer).to have_received(:new_message)
      end
    end
  end
end
