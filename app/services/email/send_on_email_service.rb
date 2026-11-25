class Email::SendOnEmailService < Base::SendOnChannelService
  # Raised when delivery failed for a reason that says nothing about the recipient:
  # a 4xx from the SMTP server, a timeout, a dropped connection. Wrapped in a type of
  # our own instead of retrying the underlying errors directly, because those classes
  # also surface from other channels' HTTP clients, and a `retry_on` on them would
  # silently change how every other channel behaves on a network blip.
  class TransientDeliveryError < StandardError; end

  # Only failures that carry a verdict belong here, because a retry re-sends the email
  # and `source_id` -- the one proof a copy already left -- is written after delivery
  # returns. So the test is not "is this error temporary?" but "does it prove the
  # server did NOT take the message?".
  #
  # Each entry below is here because it can only be raised before the server could have
  # taken the message, and that was checked against net-smtp 0.3.4, not assumed:
  #
  #   Net::SMTPServerBusy  a 4xx to a command is the server refusing that command in
  #                        words (RFC 5321). It is also the class Gmail's 451 throttling
  #                        raises, the failure that motivated all of this. It only stays
  #                        unambiguous because of the QUIT patch in
  #                        config/initializers/monkey_patches/net_smtp_quit.rb: without
  #                        it, a 4xx answered to QUIT -- which arrives after the message
  #                        was accepted -- raises this very class. Do not drop that patch.
  #   Net::OpenTimeout     raised only from tcp_socket (smtp.rb:645) and
  #                        ssl_socket_connect (smtp.rb:690). Connection setup, nothing else.
  #   Errno::ECONNREFUSED  connect() only.
  #   SocketError          getaddrinfo. The name did not even resolve.
  #
  # Everything else that looks transient is deliberately absent, and the reason is always
  # the same one: Net::ReadTimeout, Errno::ECONNRESET, OpenSSL::SSL::SSLError,
  # Errno::EHOSTUNREACH and Errno::ENETUNREACH can all also surface on the read of the 250
  # that follows the DATA terminator. There the message is already queued at the server and
  # only the answer was lost -- a route can disappear mid-session just as easily as at
  # connect time. Ruby's Net::SMTP does not say which command was in flight, so the
  # ambiguity cannot be resolved from here. They fall through to the handler below and mark
  # the message failed: visible in the UI and recoverable by a human, unlike a duplicate
  # already sitting in the customer's inbox.
  TRANSIENT_ERRORS = [
    Net::SMTPServerBusy,
    Net::OpenTimeout,
    Errno::ECONNREFUSED,
    SocketError
  ].freeze

  private

  def channel_class
    Channel::Email
  end

  def perform_reply # rubocop:disable Metrics/AbcSize
    return unless message.email_notifiable_message?

    mail = ConversationReplyMailer.with(account: message.account).email_reply(message)
    raise "Email could not be prepared for message #{message.id}" if mail.nil?

    reply_mail = mail.deliver_now
    raise "Email delivery returned nil for message #{message.id}" if reply_mail.nil?
    # ApplicationMailer rescues ExceptionList::SMTP_EXCEPTIONS (a 50x reply, e.g. a recipient
    # address the server rejects), and ActionMailer then returns the rescued exception from
    # `deliver_now` instead of raising it. Re-raise so the message fails with the server's
    # reply rather than a NoMethodError on `message_id`.
    raise reply_mail if reply_mail.is_a?(Exception)

    Rails.logger.info("Email message #{message.id} sent with source_id: #{reply_mail.message_id}")
    message.update!(source_id: reply_mail.message_id)
  rescue *TRANSIENT_ERRORS => e
    # Deliberately not marked failed and not reported here: the job retries, and only
    # the exhausted-retries handler decides the message is really lost. Reporting on
    # every attempt would page us for a blip the retry already absorbed.
    Rails.logger.warn("Transient email delivery failure for message #{message.id}: #{e.class}: #{e.message}")
    raise TransientDeliveryError, "#{e.class}: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end
end
