# Mail the IMAP fetch picks up from the inbox's own address is the business replying from
# the mailbox itself (the Gmail web UI of the same address), not the customer writing again.
# Upstream stores every fetched mail as incoming from the conversation's contact, so the
# human's reply showed under the customer's name, counted as customer traffic in reports,
# and had an AI agent on the inbox answer on top of the human (#861).
#
# Prepended rather than edited in place: `Imap::ImapMailbox`, `MailboxHelper` and
# `MailboxSanitizer` are upstream files, and every line changed there conflicts on each sync.
module ImapOwnAddressReply
  # Sweeps a mail citing an unknown thread is retried for, in case the customer mail it answers
  # is still on its way in, before the fetch leaves it alone.
  THREAD_ATTEMPTS = 3

  def process(mail, channel)
    return super unless own_address_reply?(mail, channel)

    @inbound_mail = mail
    @channel = channel
    @own_address_reply = true
    load_account
    load_inbox
    decorate_mail
    return unless incoming_email_from_valid_email?

    ActiveRecord::Base.transaction do
      next if duplicate_email?

      # Threaded by its headers only. The contact fallbacks upstream uses would make the
      # inbox its own customer, which is what opened conversations with the inbox address.
      @conversation = conversation_by_in_reply_to || find_conversation_by_reference_ids
      next skip_own_mail('threads into no conversation', retry_later: threaded?) if @conversation.nil?
      # A mail in the thread sent only to somebody else (a supplier) would become the latest
      # email, and the reply box would address the next answer to them.
      next skip_own_mail('does not reach the customer') unless reaches_the_customer?

      create_message
      add_attachments_to_message
    end
  end

  private

  # Nothing is stored for a skipped mail, so the fetch would pick it up again on every sweep,
  # and enough of them fill the per-sync cap ahead of new mail. It goes into the tracker the
  # fetch already checks for deleted conversations, at once or after a few sweeps.
  def skip_own_mail(reason, retry_later: false)
    message_id = sanitize_mailbox_value(@processed_mail.message_id)
    Rails.logger.info("[IMAP] Skipping mail from the inbox's own address that #{reason}: inbox #{@inbox.id} message_id #{message_id}")
    return if retry_later && retry_again?(message_id)

    Imap::DeletedMessageTracker.new(inbox: @inbox).record([message_id])
  end

  def threaded?
    in_reply_to.present? || @processed_mail.references.present?
  end

  def retry_again?(message_id)
    key = "IMAP_OWN_ADDRESS_THREAD_ATTEMPTS::#{@inbox.id}::#{Digest::SHA256.hexdigest(message_id)}"
    attempts = Redis::Alfred.incr(key)
    Redis::Alfred.expire(key, Imap::DeletedMessageTracker::TTL)
    attempts < THREAD_ATTEMPTS
  end

  def reaches_the_customer?
    customer = @conversation.contact.email.to_s
    customer.present? && (Array(processed_mail.to) + Array(processed_mail.cc)).any? { |address| customer.casecmp?(address.to_s) }
  end

  # Written by the inbox (From; MailPresenter#original_sender prefers Reply-To, which says where
  # answers go, not who wrote it), with answers coming back to the inbox. A contact form also
  # posts as the inbox, whether to the inbox, to an alias or with the inbox in Cc, but with the
  # customer in Reply-To: that is the customer writing in, and goes the upstream way.
  def own_address_reply?(mail, channel)
    inbox_address = ->(address) { channel.email.casecmp?(address.to_s) }

    inbox_address.call(Array(mail.from).first) && Array(mail.reply_to).all?(&inbox_address)
  end

  # The mail already went out as written. As an outgoing message it would go through the
  # Liquid rendering meant for replies typed in Chatwoot, and `{{ ... }}` in its text, or in
  # the customer's quoted text, would be evaluated and stored rewritten.
  def create_message
    return super unless @own_address_reply

    source_id = sanitize_mailbox_value(processed_mail.message_id)
    return if @conversation.messages.find_by(source_id: source_id).present?

    @message = @conversation.messages.new(sanitized_message_attributes(source_id))
    @message.instance_variable_set(:@liquid_content_processed, true)
    @message.save!
  end

  def conversation_by_in_reply_to
    return if in_reply_to.blank?

    message = @inbox.messages.find_by(source_id: in_reply_to)
    message.conversation if message.present? && !message.forwarded?
  end

  # Outgoing with no sender: nobody sent it through Chatwoot. `external_echo` is how the app
  # already marks a human reply written outside it (WhatsApp Business, Instagram), so the reply
  # clears the conversation's waiting time and counts as its human response. The source id it
  # keeps is what dedups the next fetch and what tells the send path the mail already left, so
  # it is never sent to the customer a second time.
  def sanitized_message_attributes(source_id)
    return super unless @own_address_reply

    attributes = super
    attributes.merge(message_type: 'outgoing', sender: nil, content_attributes: outgoing_content_attributes(attributes[:content_attributes]))
  end

  # Recipients in the shape an outgoing email has, which is where the reply box takes the next
  # reply's To/Cc/Bcc from. `email.to` goes: for an outgoing email the dashboard reads it as the
  # inbox's own address when quoting, and here it holds the customer's.
  def outgoing_content_attributes(content_attributes)
    content_attributes.merge(
      email: content_attributes[:email].except(:to),
      to_emails: processed_mail.to,
      cc_emails: processed_mail.cc,
      bcc_emails: processed_mail.bcc,
      # An automatic reply (a vacation responder on the mailbox) is nobody answering.
      external_echo: (true unless processed_mail.auto_reply?)
    ).compact
  end
end

Rails.application.config.to_prepare do
  Imap::ImapMailbox.prepend(ImapOwnAddressReply)
end
