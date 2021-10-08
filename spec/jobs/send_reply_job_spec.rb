require 'rails_helper'

RSpec.describe SendReplyJob, type: :job do
  subject(:job) { described_class.perform_later(message) }

  let(:message) { create(:message) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(message)
      .on_queue('high')
  end

  context 'when the job is triggered on a new message' do
    let(:process_service) { double }

    before do
      allow(process_service).to receive(:perform)
    end

    it 'calls Facebook::SendOnFacebookService when its facebook message' do
      facebook_channel = create(:channel_facebook_page)
      facebook_inbox = create(:inbox, channel: facebook_channel)
      message = create(:message, conversation: create(:conversation, inbox: facebook_inbox))
      allow(Facebook::SendOnFacebookService).to receive(:new).with(message: message).and_return(process_service)
      expect(Facebook::SendOnFacebookService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end

    it 'calls ::Twitter::SendOnTwitterService when its twitter message' do
      twitter_channel = create(:channel_twitter_profile)
      twitter_inbox = create(:inbox, channel: twitter_channel)
      message = create(:message, conversation: create(:conversation, inbox: twitter_inbox))
      allow(::Twitter::SendOnTwitterService).to receive(:new).with(message: message).and_return(process_service)
      expect(::Twitter::SendOnTwitterService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end

    it 'calls ::Twilio::SendOnTwilioService when its twilio message' do
      twilio_channel = create(:channel_twilio_sms)
      message = create(:message, conversation: create(:conversation, inbox: twilio_channel.inbox))
      allow(::Twilio::SendOnTwilioService).to receive(:new).with(message: message).and_return(process_service)
      expect(::Twilio::SendOnTwilioService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end

    it 'calls ::Telegram::SendOnTelegramService when its telegram message' do
      telegram_channel = create(:channel_telegram)
      message = create(:message, conversation: create(:conversation, inbox: telegram_channel.inbox))
      allow(::Telegram::SendOnTelegramService).to receive(:new).with(message: message).and_return(process_service)
      expect(::Telegram::SendOnTelegramService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end

    it 'calls ::Line:SendOnLineService when its line message' do
      line_channel = create(:channel_line)
      message = create(:message, conversation: create(:conversation, inbox: line_channel.inbox))
      allow(::Line::SendOnLineService).to receive(:new).with(message: message).and_return(process_service)
      expect(::Line::SendOnLineService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end

    it 'calls ::Whatsapp:SendOnWhatsappService when its line message' do
      whatsapp_channel = create(:channel_whatsapp)
      message = create(:message, conversation: create(:conversation, inbox: whatsapp_channel.inbox))
      allow(::Whatsapp::SendOnWhatsappService).to receive(:new).with(message: message).and_return(process_service)
      expect(::Whatsapp::SendOnWhatsappService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end
  end
end
