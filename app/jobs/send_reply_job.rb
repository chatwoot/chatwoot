class SendReplyJob < ApplicationJob
  queue_as :high

  # Declared BEFORE the MessageAlreadyProcessing handler below on purpose. retry_on is
  # built on rescue_from, which matches handlers with reverse_each — the LAST matching
  # declaration wins — so a broad class declared last would silently shadow every
  # specific one above it.
  #
  # Everything else retryable: when the attempts run out the message must not be left
  # sitting on "sent" with a clock next to it. SidekiqDeathHandler marks whatever reaches
  # the dead set, but this block names the actual error and runs for a job that never gets
  # there, because returning normally from retry_on tells ActiveJob the failure was
  # handled.
  retry_on Whatsapp::Session::Errors::Error, wait: :polynomially_longer, attempts: 4 do |job, error|
    Rails.logger.error "SendReplyJob exhausted retries for message #{job.arguments.first}: #{error.message}"
    fail_message(job.arguments.first, error.message)
  end

  # More specific than the handler above, so it has to come after it. A 409 from
  # baileys-api means another worker holds the idempotency lock for this
  # message. Sidekiq's default backoff (roughly 15s, 30s, 90s) used to burn all three
  # retries well before that lock could clear, so the job always died in the dead set.
  # Its own attempts, with a wait longer than a bounded send takes, keep the conflict
  # from consuming the retries the real failure modes need.
  retry_on Whatsapp::Session::Errors::MessageAlreadyProcessing,
           wait: 60.seconds,
           attempts: 3 do |job, error|
    Rails.logger.error(
      "SendReplyJob gave up on message #{job.arguments.first}: still processing elsewhere (#{error.message})"
    )
    fail_message(job.arguments.first, I18n.t('errors.inboxes.channel.outgoing.still_processing'))
  end

  # Email has no delivery receipt to reconcile against, so a transient failure is only
  # visible as an exception here. Its own retry chain, on an exception type raised solely
  # by the email service, so widening it never touches another channel. Measured on one
  # deployment: every email delivery failure in 30 days was transient, and most left the
  # customer with no reply at all, because nothing in Chatwoot resends email.
  retry_on Email::SendOnEmailService::TransientDeliveryError,
           wait: :polynomially_longer,
           attempts: 5 do |job, error|
    Rails.logger.error "SendReplyJob exhausted email retries for message #{job.arguments.first}: #{error.message}"
    # Reported exactly once, here. The service stopped reporting per attempt on purpose,
    # and returning normally from a retry_on block tells ActiveJob the exception was
    # handled, so the job never reaches the dead set either. Without this call an SMTP
    # outage lasting all five attempts would vanish from Sentry entirely -- the one
    # failure that most deserves to be seen, and the only regression this retry chain
    # introduced against the old capture-on-first-failure behaviour.
    report_exhausted_email_failure(job.arguments.first, error)
    fail_message(job.arguments.first, error.message)
  end

  # Before fail_message, because fail_message re-raises on purpose when it cannot mark the
  # message, and a raise there would skip the report. Swallows its own errors for the
  # mirror-image reason: a tracker hiccup must not stop the message from being marked
  # failed, which is what the agent actually sees.
  def self.report_exhausted_email_failure(message_id, error)
    message = Message.find_by(id: message_id)
    ChatwootExceptionTracker.new(error, account: message&.account).capture_exception
  rescue StandardError => e
    Rails.logger.error "SendReplyJob could not report exhausted email failure for #{message_id}: #{e.class}: #{e.message}"
  end

  # Marks the message failed so the agent sees it and can resend. Through
  # StatusTransition because it owns the terminal-status rule and applies it under the
  # row lock: an attempt that timed out may still have reached WhatsApp, so a receipt
  # can mark this message delivered or read while its retries are still running out.
  # Either status is proof it arrived, and walking one back to failed here is what
  # would put a duplicate in front of the customer.
  def self.fail_message(message_id, reason)
    message = Message.find_by(id: message_id)
    return if message.blank?
    return unless delivers_message?(message)

    return fail_email_message(message, reason) if message.conversation.inbox.channel.is_a?(Channel::Email)

    Whatsapp::Session::Inbound::StatusTransition.fail_send(message, reason)
  rescue StandardError => e
    # Logged AND re-raised. Returning normally from a retry_on block tells ActiveJob the
    # original exception was handled, so Sidekiq neither retries nor buries the job — and
    # the message stays on `sent` with a clock next to it, which is the exact silence this
    # handler exists to end. A transient database failure here means the send is still
    # unaccounted for, so the job has to die loudly and reach the dead-set handler.
    Rails.logger.error "SendReplyJob could not mark message #{message_id} as failed (#{reason}): #{e.class}: #{e.message}"
    raise
  end

  # Same guard as the WhatsApp path, for a different reason: `source_id` is written only
  # after a successful `deliver_now`, so its presence is the one proof the mail left. A
  # send that timed out may still have been accepted, and walking it back to failed here
  # is what would put a duplicate in front of the customer on the next resend.
  def self.fail_email_message(message, reason)
    message.with_lock do
      next if message.source_id.present?

      Messages::StatusUpdateService.new(message, 'failed', reason).perform
    end
  end

  # Whether this job was what would have put this message in front of the contact. Two ways
  # it was not, and in both a "failed to send" is a lie about a row nobody was sending.
  #
  # The channel: the widget broadcasts the reply over the cable and the API channel fires a
  # webhook, both when the message is created, so all this job does on those two is queue
  # the email-continuity notification. Its failure there is a failure to notify, not to
  # deliver, and marking the message would tell the agent to resend one the customer is
  # reading on screen. Asked of the routing table rather than a list of our own, which
  # would be a second place to keep in sync.
  #
  # The message: `perform` runs for every message that gets created -- the customer's own,
  # private notes, activity lines, bubbles for a voice call -- and it is
  # Base::SendOnChannelService that decides there is nothing to send, well after this job
  # has started. Its rule is mirrored here, deliberately and not delegated to: the service
  # is upstream's, its predicates are private, and instantiating one needs the concrete
  # channel class this job resolves. A job that died before reaching that decision never
  # got to find out, and those are the failures that fill the dead set: a database in
  # trouble takes out `Message.find` on the first line of `perform`.
  #
  # Mirrored whole, including the removed-reaction exception: that row is deleted on
  # purpose and its empty content is the payload that clears the emoji on the contact's
  # phone, so it is a send like any other and a send that failed has to say so.
  def self.delivers_message?(message)
    return false if CHANNEL_SERVICES[message.conversation.inbox.channel.class.to_s] == NOTIFICATION_ONLY_SERVICE

    (message.outgoing? || message.template?) && !message.private? &&
      message.content_type != 'voice_call' && !(message.deleted? && !message.removed_reaction?)
  end

  CHANNEL_SERVICES = {
    'Channel::TwitterProfile' => '::Twitter::SendOnTwitterService',
    'Channel::TwilioSms' => '::Twilio::SendOnTwilioService',
    'Channel::Line' => '::Line::SendOnLineService',
    'Channel::Telegram' => '::Telegram::SendOnTelegramService',
    'Channel::Whatsapp' => '::Whatsapp::SendOnWhatsappService',
    'Channel::Sms' => '::Sms::SendOnSmsService',
    'Channel::Instagram' => '::Instagram::SendOnInstagramService',
    'Channel::Tiktok' => '::Tiktok::SendOnTiktokService',
    'Channel::Email' => '::Email::SendOnEmailService',
    'Channel::WebWidget' => '::Messages::SendEmailNotificationService',
    'Channel::Api' => '::Messages::SendEmailNotificationService'
  }.freeze

  # The value the two notification-only channels above share, named so delivers_message?
  # can ask the table about them instead of keeping a second list of channels.
  NOTIFICATION_ONLY_SERVICE = '::Messages::SendEmailNotificationService'.freeze

  def perform(message_id)
    message = Message.find(message_id)
    channel_name = message.conversation.inbox.channel.class.to_s

    Captain::Conversation::AgentMessageTranslationService.new(message: message).perform if message.content_attributes['translation_pending']

    return send_on_facebook_page(message) if channel_name == 'Channel::FacebookPage'

    service_class_name = CHANNEL_SERVICES[channel_name]
    return unless service_class_name

    service_class_name.constantize.new(message: message).perform
  end

  private

  def send_on_facebook_page(message)
    if message.conversation.additional_attributes['type'] == 'instagram_direct_message'
      ::Instagram::Messenger::SendOnInstagramService.new(message: message).perform
    else
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end
