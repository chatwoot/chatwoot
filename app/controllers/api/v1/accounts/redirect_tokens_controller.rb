class Api::V1::Accounts::RedirectTokensController < Api::V1::Accounts::BaseController
  def create
    inbox = Current.account.inboxes.find(permitted_params[:inbox_id])
    authorize inbox, :show?
    return render(json: { error: 'not_a_web_widget' }, status: :unprocessable_entity) unless inbox.web_widget?

    payload = token_payload(inbox, origin_conversation)
    ttl = (permitted_params[:ttl_seconds].presence&.to_i || ::Widget::RedirectToken::DEFAULT_TTL).clamp(1, ::Widget::RedirectToken::DEFAULT_TTL)
    token = ::Widget::RedirectToken.generate(payload, ttl: ttl)

    render json: { token: token, expires_in: ttl, website_url: inbox.channel.website_url }
  end

  private

  # `origin_display_id` is the conversation the link is being sent ON (the WhatsApp entry thread).
  # It rides in the token because this is the only moment the two halves of a redirect episode are
  # known together: the resolve endpoint identifies the CONTACT, and a contact does not say which of
  # its conversations minted the link. Carried through to the widget conversation on resolve.
  def token_payload(inbox, origin)
    {
      inbox_id: inbox.id,
      identifier: permitted_params[:identifier],
      message: permitted_params[:message],
      origin_display_id: origin&.display_id,
      identified_contact_id: named_contact&.id
    }.compact
  end

  # WHICH CONTACT THIS LINK IS FOR, named by the caller because only the caller knows.
  #
  # `identifier` alone cannot answer it. The value the redirect funnel uses is derived from a
  # sequential contact id, so it is guessable, and it can move off the contact between the mint and a
  # click a day later. When it has moved, the resolve side finds nobody holding it and ASSIGNS it to
  # the widget visitor instead of merging onto the lead — which is how a lead ends up with two
  # contacts, one of them squatting the identifier of the other (fazer-ai/agents#286).
  #
  # This endpoint is account-authenticated, so a contact it is told to name is a fact the widget side
  # can spend, and one nothing reaching the widget can forge. It travels in a token that is
  # single-use, server-side and never readable by the widget.
  #
  # OPTIONAL, and the omission is meaningful rather than a default. A caller minting a
  # pre-authenticated deep link for an identity that has no contact yet (a CRM handing off a user
  # this account has never seen) wants the resolve to CREATE it, which is what this endpoint has
  # always done. Only a caller that names a contact is asking for the stricter rule, so an absent
  # `contact_id` leaves that flow exactly as it was.
  #
  # `find` rather than `find_by`: a caller naming a contact that does not exist in this account has a
  # bug, and a token minted with the field silently dropped would resolve as the loose flow without
  # anything saying so.
  def named_contact
    id = permitted_params[:contact_id].presence
    return if id.blank?

    Current.account.contacts.find(id)
  end

  # The mint is the earliest shared entry point for the pairing, so the caller's right to name that
  # conversation is settled here rather than downstream. A display_id is account-wide and guessable,
  # and what the consumer does with the pairing is destructive — its follow-up ladder messages and
  # RESOLVES the conversation it names. An origin the caller cannot see is refused outright instead
  # of dropped: minting without it would silently hand back a link whose episode cannot be paired,
  # which is the failure this whole field exists to remove.
  def origin_conversation
    display_id = permitted_params[:origin_display_id].presence
    return if display_id.blank?

    conversation = Current.account.conversations.find_by!(display_id: display_id)
    authorize conversation, :show?
    conversation
  end

  def permitted_params
    params.permit(:inbox_id, :identifier, :contact_id, :message, :ttl_seconds, :origin_display_id)
  end
end
