require 'rails_helper'

RSpec.describe SendReplyJob do
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

    def expect_mapped_service_to_perform(message, service_class_name)
      channel_name = message.conversation.inbox.channel.class.name
      mapped_class_name = described_class::CHANNEL_SERVICES.fetch(channel_name)

      expect(mapped_class_name).to eq("::#{service_class_name}")
      expect(mapped_class_name.constantize).to receive(:new).with(message: message).and_return(process_service)
      expect(process_service).to receive(:perform)

      described_class.perform_now(message.id)
    end

    it 'calls Facebook::SendOnFacebookService when its facebook message' do
      stub_request(:post, /graph.facebook.com/)
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
      expect_mapped_service_to_perform(message, 'Twitter::SendOnTwitterService')
    end

    it 'calls ::Twilio::SendOnTwilioService when its twilio message' do
      twilio_channel = create(:channel_twilio_sms)
      message = create(:message, conversation: create(:conversation, inbox: twilio_channel.inbox))
      expect_mapped_service_to_perform(message, 'Twilio::SendOnTwilioService')
    end

    it 'calls ::Telegram::SendOnTelegramService when its telegram message' do
      telegram_channel = create(:channel_telegram)
      message = create(:message, conversation: create(:conversation, inbox: telegram_channel.inbox))
      expect_mapped_service_to_perform(message, 'Telegram::SendOnTelegramService')
    end

    it 'calls ::Line:SendOnLineService when its line message' do
      line_channel = create(:channel_line)
      message = create(:message, conversation: create(:conversation, inbox: line_channel.inbox))
      expect_mapped_service_to_perform(message, 'Line::SendOnLineService')
    end

    it 'calls ::Whatsapp:SendOnWhatsappService when its whatsapp message' do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      whatsapp_channel = create(:channel_whatsapp, sync_templates: false)
      message = create(:message, conversation: create(:conversation, inbox: whatsapp_channel.inbox))
      expect_mapped_service_to_perform(message, 'Whatsapp::SendOnWhatsappService')
    end

    it 'calls ::Sms::SendOnSmsService when its sms message' do
      sms_channel = create(:channel_sms)
      message = create(:message, conversation: create(:conversation, inbox: sms_channel.inbox))
      expect_mapped_service_to_perform(message, 'Sms::SendOnSmsService')
    end

    it 'calls ::Instagram::Direct::SendOnInstagramService when its instagram message' do
      instagram_channel = create(:channel_instagram)
      message = create(:message, conversation: create(:conversation, inbox: instagram_channel.inbox))
      expect_mapped_service_to_perform(message, 'Instagram::SendOnInstagramService')
    end

    it 'calls ::Instagram::Messenger::SendOnInstagramService when its an instagram_direct_message from facebook channel' do
      stub_request(:post, /graph.facebook.com/)
      facebook_channel = create(:channel_facebook_page)
      facebook_inbox = create(:inbox, channel: facebook_channel)
      conversation = create(:conversation,
                            inbox: facebook_inbox,
                            additional_attributes: { 'type' => 'instagram_direct_message' })
      message = create(:message, conversation: conversation)

      allow(Instagram::Messenger::SendOnInstagramService).to receive(:new).with(message: message).and_return(process_service)
      expect(Instagram::Messenger::SendOnInstagramService).to receive(:new).with(message: message)
      expect(process_service).to receive(:perform)
      described_class.perform_now(message.id)
    end

    it 'calls ::Email::SendOnEmailService when its email message' do
      email_channel = create(:channel_email)
      message = create(:message, conversation: create(:conversation, inbox: email_channel.inbox))
      expect_mapped_service_to_perform(message, 'Email::SendOnEmailService')
    end

    it 'calls ::Messages::SendEmailNotificationService when its webwidget message' do
      webwidget_channel = create(:channel_widget)
      message = create(:message, conversation: create(:conversation, inbox: webwidget_channel.inbox))
      expect_mapped_service_to_perform(message, 'Messages::SendEmailNotificationService')
    end

    it 'calls ::Messages::SendEmailNotificationService when its api channel message' do
      api_channel = create(:channel_api)
      message = create(:message, conversation: create(:conversation, inbox: api_channel.inbox))
      expect_mapped_service_to_perform(message, 'Messages::SendEmailNotificationService')
    end

    it 'calls ::Tiktok::SendOnTiktokService when its tiktok message' do
      tiktok_channel = create(:channel_tiktok)
      message = create(:message, conversation: create(:conversation, inbox: tiktok_channel.inbox))
      expect_mapped_service_to_perform(message, 'Tiktok::SendOnTiktokService')
    end
  end

  # Until this existed an exhausted job died in the dead set in silence, leaving the
  # bubble on "sent" with a clock next to it. SidekiqDeathHandler now marks whatever
  # reaches that set, but these blocks name the actual error and run for a job that never
  # gets there, since returning normally from retry_on handles the exception.
  describe 'when retries run out' do
    # A channel this job actually delivers on. The default factory inbox is a widget,
    # where it only queues the email notification and none of these errors can be raised.
    let(:inbox) { create(:channel_line).inbox }
    let(:message) do
      create(:message, message_type: :outgoing, inbox: inbox, conversation: create(:conversation, inbox: inbox))
    end

    it 'marks the message failed with the reason' do
      described_class.fail_message(message.id, 'the provider never answered')

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to eq('the provider never answered')
    end

    it 'does not overwrite a reason already recorded on the message' do
      message.update_under_lock!(status: :failed, external_error: 'already recorded')

      described_class.fail_message(message.id, 'the later reason')

      expect(message.reload.external_error).to eq('already recorded')
    end

    it 'ignores a message that no longer exists' do
      expect { described_class.fail_message(-1, 'gone') }.not_to raise_error
    end

    # Returning normally from a retry_on block tells ActiveJob the original exception was
    # handled, so Sidekiq neither retries nor buries the job — and the message stays on
    # `sent` with a clock next to it, which is the exact silence this handler exists to
    # end. If the write fails, the send is still unaccounted for and the job has to die
    # loudly enough to reach the dead-set handler.
    it 'raises when the failure could not be recorded' do
      allow(Whatsapp::Session::Inbound::StatusTransition)
        .to receive(:fail_send).and_raise(ActiveRecord::StatementInvalid, 'db down')
      allow(Rails.logger).to receive(:error)

      expect { described_class.fail_message(message.id, 'retries exhausted') }
        .to raise_error(ActiveRecord::StatementInvalid)
      expect(Rails.logger).to have_received(:error).with(/could not mark message #{message.id} as failed/)
    end

    # source_id is only ever written by the provider — the send response, or the echo
    # promoting a reservation — so it is proof the message exists on WhatsApp even while
    # the status is still 'sent'. A send WE could not confirm has nothing to say about
    # one the provider already did.
    it 'leaves a message the provider already echoed back alone' do
      message.update_under_lock!(source_id: 'wa_msg_123')

      described_class.fail_message(message.id, 'retries exhausted')

      expect(message.reload.status).not_to eq('failed')
      expect(message.external_error).to be_blank
    end

    # A send that timed out may still have reached WhatsApp, so a receipt can mark this
    # message delivered while its retries are running out. Either status is proof it
    # arrived, and walking one back to failed is what puts a duplicate in front of the
    # customer.
    %w[delivered read].each do |terminal|
      it "leaves a message already marked #{terminal} alone" do
        message.update_under_lock!(status: terminal.to_sym)

        described_class.fail_message(message.id, 'retries exhausted')

        expect(message.reload.status).to eq(terminal)
        expect(message.external_error).to be_blank
      end
    end

    # The idempotency lock clears in about the time a bounded send takes; the default
    # backoff burned all three retries well before that, so the conflict alone was enough
    # to kill the job every time.
    #
    # Asserted on the scheduled retry rather than on the handler list, because being
    # registered is not the same as being reached: retry_on is built on rescue_from,
    # which matches with reverse_each, so the broad Errors::Error handler shadows this
    # one unless it is declared first. A membership check passes either way.
    it 'gives a processing conflict its own, longer backoff' do
      whatsapp_channel = create(:channel_whatsapp, sync_templates: false, validate_provider_config: false)
      whatsapp_message = create(
        :message,
        message_type: :outgoing,
        conversation: create(:conversation, inbox: whatsapp_channel.inbox)
      )
      service = instance_double(Whatsapp::SendOnWhatsappService)
      allow(Whatsapp::SendOnWhatsappService).to receive(:new).and_return(service)
      allow(service).to receive(:perform)
        .and_raise(Whatsapp::Providers::WhatsappBaileysService::MessageAlreadyProcessingError)

      expect { described_class.perform_now(whatsapp_message.id) }
        .to have_enqueued_job(described_class)

      # Asserted as a floor rather than a window: what this catches is the broad handler
      # shadowing this one, which schedules the first retry ~3s out. Pinning the exact 60
      # would only add flake from suite timing.
      scheduled_in = enqueued_jobs.last[:at] - Time.zone.now.to_f
      expect(scheduled_in).to be > 30
    end
  end

  # Email has no delivery receipt, so a 4xx or a timeout surfaces only as an exception on
  # the send. Before this, any of them marked the message failed on the first try and
  # nothing ever resent it, which is how a temporary throttle from the mail server became
  # a customer who got no reply at all.
  describe 'transient email delivery' do
    let(:email_channel) { create(:channel_email) }
    let(:email_message) do
      create(:message, message_type: :outgoing, conversation: create(:conversation, inbox: email_channel.inbox))
    end

    # Asserted on the scheduled retry rather than on the handler list: retry_on is built
    # on rescue_from, which matches with reverse_each, so a handler declared later for a
    # broader class would shadow this one while a membership check still passed.
    it 'retries instead of failing the message on the first attempt' do
      # Realised before the expect block on purpose: creating an outgoing message enqueues
      # a SendReplyJob of its own, and inside the block that one would be counted as the
      # retry this example is asserting on.
      message_id = email_message.id
      service = instance_double(Email::SendOnEmailService)
      allow(Email::SendOnEmailService).to receive(:new).and_return(service)
      allow(service).to receive(:perform).and_raise(Email::SendOnEmailService::TransientDeliveryError, 'boom')

      expect { described_class.perform_now(message_id) }.to have_enqueued_job(described_class)
      expect(email_message.reload.status).not_to eq('failed')
    end

    it 'marks the message failed once the retries run out' do
      described_class.fail_message(email_message.id, 'mail server kept rejecting')

      expect(email_message.reload.status).to eq('failed')
      expect(email_message.external_error).to eq('mail server kept rejecting')
    end

    # source_id is written only after a successful deliver_now, so its presence is the one
    # proof the mail left. A send that timed out may still have been accepted, and marking
    # it failed here is what would put a duplicate in front of the customer on a resend.
    it 'leaves a message that already has a source_id alone' do
      email_message.update!(source_id: 'conversation/abc/messages/1@example.com')

      described_class.fail_message(email_message.id, 'retries exhausted')

      expect(email_message.reload.status).not_to eq('failed')
      expect(email_message.external_error).to be_blank
    end

    # The WhatsApp path goes through StatusTransition, which knows nothing about email.
    it 'does not route an email failure through the WhatsApp status transition' do
      allow(Whatsapp::Session::Inbound::StatusTransition).to receive(:fail_send)

      described_class.fail_message(email_message.id, 'mail server kept rejecting')

      expect(Whatsapp::Session::Inbound::StatusTransition).not_to have_received(:fail_send)
    end

    # The service skips the tracker on every attempt, and a retry_on block that returns
    # normally never reaches the dead set. Without this report an SMTP outage lasting all
    # five attempts would leave no trace in Sentry at all.
    context 'when the retries are exhausted' do
      let(:error) { Email::SendOnEmailService::TransientDeliveryError.new('mail server kept rejecting') }
      let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

      before { allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker) }

      it 'reports the final failure once, with the account attached' do
        described_class.report_exhausted_email_failure(email_message.id, error)

        expect(ChatwootExceptionTracker).to have_received(:new).with(error, account: email_message.account)
        expect(exception_tracker).to have_received(:capture_exception)
      end

      it 'still lets the message be marked failed when the tracker itself blows up' do
        allow(ChatwootExceptionTracker).to receive(:new).and_raise(StandardError, 'sentry down')

        expect { described_class.report_exhausted_email_failure(email_message.id, error) }.not_to raise_error

        described_class.fail_message(email_message.id, error.message)
        expect(email_message.reload.status).to eq('failed')
      end
    end
  end
end
