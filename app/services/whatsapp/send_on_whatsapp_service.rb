class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  include BaileysHelper

  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    if template_params.present?
      tag_contact_info_template_request
      return send_template_message
    end
    return send_contact_info_request if contact_info_request?

    if message.conversation.can_reply?
      return channel.provider == 'baileys' ? send_baileys_session_message : send_session_message
    end

    message.update_under_lock!(status: :failed, external_error: I18n.t('errors.whatsapp.message_outside_messaging_window'))
  rescue CustomExceptions::WhatsappContactInfoRequestError => e
    message.update_under_lock!(status: :failed, external_error: e.message)
  end

  def send_contact_info_request
    Whatsapp::ContactInfoRequestEligibilityService.new(
      conversation: message.conversation, message: message, delivery_mode: :interactive
    ).ensure_available!
    message_id = channel.send_contact_info_request(message.conversation.contact_inbox.source_id, message)
    persist_source_id(message_id)
  end

  def send_template_message
    name, namespace, lang_code, processed_parameters = resolved_template

    if name.blank?
      message.update_under_lock!(status: :failed, external_error: 'Template not found or invalid template name')
      return
    end

    message_id = channel.send_template(recipient_id, {
                                         name: name,
                                         namespace: namespace,
                                         lang_code: lang_code,
                                         parameters: processed_parameters
                                       }, message)
    persist_source_id(message_id)
  rescue ArgumentError, CustomExceptions::Whatsapp::MediaUploadError => e
    # Parameter validation (media URL, coupon code, media type) rejected the template, or its sample
    # media could not be uploaded. Retrying can't fix either, so surface the reason on the message
    # instead of letting the job die silently.
    message.update_under_lock!(status: :failed, external_error: e.message)
  rescue Whatsapp::Session::Errors::Error => e
    # A template send reaches the provider the same way a session message does, so a transport
    # failure here has the same two outcomes and the same rule decides between them.
    fail_unless_retryable(e)
  end

  def resolved_template
    Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params,
      message: message
    ).call
  end

  def send_baileys_session_message
    validate_announcement_mode!
    with_baileys_channel_lock_on_outgoing_message(channel.id) do
      # Waiting on the channel lock can take minutes when the inbox is busy, so re-check right before
      # hitting the provider: the agent may have deleted the message while this job was queued.
      next if deleted_in_database?

      send_session_message
    end
  rescue Whatsapp::Session::Errors::Error => e
    fail_unless_retryable(e)
  end

  # Through StatusTransition, which owns the rule and applies it under the row lock.
  # Writing status/external_error directly here would be the third copy of that rule,
  # and the two that already existed had drifted apart — but more concretely: a send
  # that timed out may still have reached WhatsApp, so a receipt can mark this message
  # delivered or read while we are deciding it failed. delivered/read are terminal, and
  # walking one back to failed invites the agent to send a duplicate.
  def fail_message(error)
    message.reload
    # error.message, not the exception: StatusTransition appends the wire code when it
    # is handed an exception, and external_error is the sentence the agent reads on the
    # bubble. The code is already in the logs.
    Whatsapp::Session::Inbound::StatusTransition.fail_send(message, error.message)
    nil
  end

  def validate_announcement_mode!
    return unless conversation.contact.group_type_group?
    return unless conversation.contact.additional_attributes&.dig('announce') == true
    return if inbox_admin_in_group?

    message.update_under_lock!(status: :failed, external_error: 'Only administrators are allowed to send messages in this group')
    raise StandardError, 'Only admins can send messages in this group'
  end

  def inbox_admin_in_group?
    inbox_phone = channel.phone_number&.gsub(/[^\d]/, '')
    return false if inbox_phone.blank?

    admin_phones = conversation.contact.group_memberships.active.where(role: :admin)
                               .includes(:contact).filter_map { |m| m.contact.phone_number&.gsub(/[^\d]/, '') }

    admin_phones.any? { |phone| phones_match?(inbox_phone, phone) }
  end

  def phones_match?(phone_a, phone_b)
    return false if phone_a.blank? || phone_b.blank?

    phone_a == phone_b || (phone_a.length >= 8 && phone_b.length >= 8 && phone_a[-8..] == phone_b[-8..])
  end

  # The same rule the Baileys path has had since #391, now that the other three providers raise
  # something it can read. Before this a transport failure escaped as whatever the HTTP stack
  # raised, matched no `retry_on` in SendReplyJob, and left Sidekiq re-sending the message three
  # more times with the bubble still on "sent" (fazer-ai/chatwoot#605).
  #
  # The session providers reach this too, and it costs them nothing: their own MessageSender
  # already applies this rule, so what arrives here is only what it chose to re-raise.
  def send_session_message
    message_id = channel.send_message(recipient_id, message)
    persist_source_id(message_id)
  rescue Whatsapp::Session::Errors::Error => e
    fail_unless_retryable(e)
  end

  # A refusal the provider will repeat, or a send whose outcome nobody can determine. Letting it
  # escape leaves the bubble reading "sent" while the job retries something that cannot work and
  # then dies in the dead set, so the reason goes on the message instead — the agent sees it and
  # can act. Only an error that might answer differently next time is worth raising for. Mirrors
  # Whatsapp::Session::Outbound::MessageSender, which already does this for the session providers.
  def fail_unless_retryable(error)
    raise error if error.retryable?
    # A processing conflict is not retryable by the definition retryable? uses — the same command
    # is not going to answer differently, because we are not the one running it. But the MESSAGE
    # is still on its way out through the worker holding the lock, so failing it here would be a
    # lie, and it would swallow the dedicated backoff SendReplyJob has for exactly this conflict.
    raise error if error.code == Whatsapp::Session::Errors::MessageAlreadyProcessing::CODE

    fail_message(error)
  end

  # The message may have been deleted while this send was in flight — the DELETE endpoint found no
  # `source_id` to revoke and skipped the provider, so it is on us to revoke it now that we have one.
  # The flag is read from the same locked read the write took, which is also where the DELETE endpoint
  # reads the `source_id`: whoever enters that critical section first leaves the revocation to the
  # other side, so the provider delete is enqueued exactly once.
  def persist_source_id(message_id)
    return if message_id.blank?

    # Only whoever assigns the id owns the revoke: a session inbox has a second writer of
    # this column, the echo of our own send, and both of them seeing `deleted` would ask
    # the provider to revoke the same message twice. The assignment and that decision
    # share one row lock, which is what makes the answer unambiguous.
    return unless Whatsapp::Session::Outbound::SourceIdReservation.assign(message, { source_id: message_id }) == :revoke

    ::Messages::DeleteOnChannelJob.perform_later(message.id)
  end

  # Reads the flag straight from the database: a full `message.reload` would also drop the cached
  # conversation/inbox/channel chain this service leans on.
  def deleted_in_database?
    stored = Message.select(:id, :content_attributes).find_by(id: message.id)
    stored.present? && stored.deleted? && !stored.removed_reaction?
  end

  def recipient_id
    return message.conversation.contact_inbox.source_id unless channel.session_family?

    # NOTE: `identifier` must be in the WhatsApp LID format
    message.conversation.contact.phone_number&.gsub(/[^\d]/, '') || message.conversation.contact.identifier
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end

  def contact_info_request?
    message.content_attributes.dig('whatsapp_contact_info', 'type') == 'request'
  end

  def tag_contact_info_template_request
    eligibility = Whatsapp::ContactInfoRequestEligibilityService.new(
      conversation: message.conversation, message: message, delivery_mode: :template, template_params: template_params
    )
    return unless eligibility.request_contact_info_template?(template_params)

    message.conversation.contact_inbox.with_lock do
      eligibility.ensure_available!
      content_attributes = message.content_attributes.deep_dup
      content_attributes['whatsapp_contact_info'] = { 'type' => 'request', 'state' => 'pending', 'delivery_mode' => 'template' }
      message.update!(content_attributes: content_attributes)
    end
  end
end
