# The provider service of a session channel.
#
# Channel::Whatsapp talks to its provider in the shape the legacy providers established:
# a recipient id that is a phone number or a JID, a Chatwoot message, a group JID. This
# translates all of it into the canonical commands the backend takes, so the channel
# model, the group controllers and the presence services keep working untouched.
#
# Session-internal code does not come through here: it asks the channel for
# `session_backend` and speaks the canonical API directly.
class Whatsapp::Session::Facade
  include Whatsapp::Session::Facade::Groups
  include Whatsapp::Session::Facade::History
  include Whatsapp::Session::Facade::Presence

  attr_reader :channel, :backend, :provider, :instance

  # Resolved on every call, never held in a constant: `Whatsapp::Session::Model` is an
  # implicit namespace (there is no model.rb), so a constant here captures a module
  # object that a reload strips of its autoloads, and every lookup through it then
  # raises `uninitialized constant`.
  def model = Whatsapp::Session::Model

  def initialize(channel)
    @channel = channel
    @backend = Whatsapp::Session::Registry.backend_for(channel)
    # The provider this backend was resolved for, and the instance it was pointed at. An
    # inbox converted while a connect is in flight has an empty connection record belonging
    # to another provider; one re-pointed at another instance of the same provider keeps
    # its key and changes nothing the provider fence can see, while the answer in flight
    # can name a different phone, which reads as a wrong-number quarantine and ends the
    # session that just replaced it. Every write below is fenced against landing there.
    @provider = channel.provider
    @instance = Whatsapp::Session::Registry.instance_fingerprint(channel)
  end

  # --- session lifecycle ---------------------------------------------------------

  # "Make sure this session is up": resumes an existing pairing, or starts a new one.
  def setup_channel_provider
    start_pairing(pairing_mode)
  end

  # The operator saying they cannot scan the QR. `setup_channel_provider` picks QR for a
  # session that has never paired because that is the mode needing nothing from them;
  # this is the other way into the same pairing, and asking again is how a code that
  # expired gets replaced.
  #
  # It pairs the inbox's own number, never one the request carries. Pairing links
  # whatever phone the code is typed on, and this layer quarantines a session whose
  # account is not the inbox's: letting the caller name a different number would spend a
  # pairing to arrive at that quarantine.
  def request_pairing_code
    raise Whatsapp::Session::Errors::NotSupported, I18n.t('errors.inboxes.channel.code_pairing_unsupported') unless capability?('code_pairing')

    start_pairing('code')
  end

  def import_session(session:, candidate_index: 0)
    backend.import_session(session: session, candidate_index: candidate_index)
  end

  # Says again that this account should be connected, without touching what the dashboard
  # shows. It exists for the one-time re-assert after a connector upgrade
  # (fazer-ai/whatsapp-connector#194), where the point is the record the connector keeps of
  # having been asked, and not a new pairing.
  #
  # Deliberately NOT `setup_channel_provider`. That one claims a pairing attempt, which writes
  # `connecting` over the stored state, and turns a refusal into `close` with `connect_failure`.
  # For a bulk re-assert those writes are the wrong shape twice over: the inbox this asked for
  # is the one that was recorded as `open`, so erasing that on a failure makes the retry skip
  # exactly the inboxes that still need it, and a fleet being re-asserted has nothing to fence,
  # because there is no QR on anybody's screen to go stale.
  #
  # What the dashboard ends up showing is the connector's own doing, which is the arrangement
  # this backend already relies on: it pushes every transition it sees, which is why it declares
  # no state polling.
  #
  # Always `resume`: this is only ever asked of an account that is already paired. One that is
  # not gets the provider's own refusal, which the caller reports rather than turning into a QR
  # nobody is watching.
  def reassert_desired_state
    backend.connect(
      model::Commands::SessionConnect.new(
        pairing: 'resume', phone: channel.phone_number.to_s.delete('+'),
        groups: capability?('groups'), history_sync: history_on_connect?, proxy: proxy
      )
    )
  end

  # The channel calls this when an inbox is destroyed or converted to another provider,
  # so it is a teardown, not a pause: the Baileys service answers it with
  # `DELETE /connections/<phone>`. Merely disconnecting would leave the pairing and its
  # credentials alive on the provider under a session id Chatwoot no longer has.
  #
  # A refusal is said out loud rather than swallowed. What the fallback can do is end the
  # connection, and a session whose pairing outlived the inbox that owned it is exactly the
  # kind of thing an installation log has to carry: nothing else in this path leaves any
  # trace, and the operator sees the inbox disappear and concludes it is over.
  def disconnect_channel_provider
    backend.delete_session
  rescue Whatsapp::Session::Errors::NotSupported => e
    Rails.logger.warn(
      "[WHATSAPP] #{provider} cannot tear down its session (#{e.message}); disconnecting instead, " \
      "which leaves the pairing alive on the provider for inbox #{channel.inbox&.id}"
    )
    backend.disconnect
  end

  # The operator's Disconnect, which keeps the inbox and therefore its session id. A logout
  # and not the teardown above: deleting the session has the connector forget it, epoch
  # counter included, so the pairing after it would start again at epoch 1 under the epoch
  # and position Chatwoot kept for the old session, and every event of it, the QR first,
  # would be dropped (fazer-ai/chatwoot#852). The contract keeps the counter across a logout
  # for exactly this: the account can be paired again under the same id.
  def logout_channel_provider
    backend.logout
  end

  # Session providers pair a real phone: there is no template catalog to sync and no
  # template to send.
  def sync_templates
    true
  end

  def send_template(_recipient_id, _template_info, _message = nil)
    raise Whatsapp::Session::Errors::NotSupported, 'templates are a cloud API feature'
  end

  # --- messages ------------------------------------------------------------------

  def send_message(_recipient_id, message)
    Whatsapp::Session::Outbound::MessageSender.new(message).perform
  end

  def edit_message(recipient_id, message, new_content)
    backend.edit_message(
      model::Commands::MessageEdit.new(
        message_id: Whatsapp::Session::Outbound::SourceIdReservation.generate,
        target_id: message.source_id, to: address(recipient_id),
        content: model::Content::Text.new(body: new_content)
      )
    )
  end

  def delete_message(recipient_id, message)
    return if message.source_id.blank?

    to = address(recipient_id)
    backend.revoke_message(
      model::Commands::MessageRevoke.new(
        target_id: message.source_id, to: to,
        participant: (model::Address.for_contact(message.sender) if to.group? && message.incoming?)
      )
    )
  end

  # One command per participant in a group. A receipt on WhatsApp is addressed by the
  # message key, and in a group that key includes who sent it, so a single command
  # covering several senders cannot be acknowledged. In a 1:1 chat the peer is the chat
  # itself and the field stays empty.
  def read_messages(messages, recipient_id:, **)
    return unless capability?('read_receipts')

    chat = address(recipient_id)
    readable = Array(messages).select { |message| message.source_id.present? }
    readable.group_by { |message| chat.group? ? message.sender : nil }.each do |sender, group|
      backend.mark_read(
        model::Commands::MessageMarkRead.new(
          chat: chat, message_ids: group.map(&:source_id), sender: participant_address(group.first, sender)
        )
      )
    end
  end

  # Addressed from the conversation's contact rather than from `recipient_id`: the
  # channel always hands this one `contact.phone_number`, which for a LID contact is not
  # the id WhatsApp knows the chat by, and for a LID-only contact is nothing at all.
  def unread_message(recipient_id, message)
    return unless capability?('mark_unread')

    contact = message.conversation&.contact
    chat = contact.present? ? model::Address.for_contact(contact) : address(recipient_id)

    backend.mark_unread(
      model::Commands::MessageMarkUnread.new(
        chat: chat, last_message_id: message.source_id, from_me: message.outgoing?
      )
    )
  end

  # The provider acknowledges delivery itself as it takes the message off WhatsApp;
  # there is nothing for Chatwoot to send back.
  def received_messages(_recipient_id, _messages)
    true
  end

  # --- contacts --------------------------------------------------------------------

  # Answered in the shape the contact builder and the inbox controller already read:
  # `exists` plus the phone JID WhatsApp actually knows the number by, which is what the
  # ninth-digit normalization needs.
  #
  # The phone, never the LID, even when the provider volunteers one. Both callers take
  # the digits off this JID and write them to `contacts.phone_number` (and to the contact
  # inbox's source id), so answering with a LID renames the contact after an opaque
  # internal id and then addresses it at `<lid>@s.whatsapp.net`, which reaches nobody.
  #
  # Takes `deadline:` like Baileys; each backend's number check already has a short ceiling of
  # its own.
  def on_whatsapp(recipient_id, **)
    digits = recipient_id.to_s.split('@').first.to_s.delete('+')
    check = backend.check_numbers(model::Commands::ContactCheck.new(phones: [digits])).first
    return { 'jid' => "#{digits}@s.whatsapp.net", 'exists' => false } if check.blank?

    { 'jid' => model::Address.phone(check.phone.presence || digits).to_jid, 'exists' => check.exists }
  end

  private

  def capability?(capability)
    channel.session_capabilities.include?(capability)
  end

  # Both ways in share every step but the mode: the disowned-session guard, the claim
  # that orders two clicks by the click, the write and the poll.
  def start_pairing(mode)
    end_disowned_session
    attempt = claim_pairing_attempt
    # The inbox was converted while this was running, so it is not this backend's to
    # connect: asking the old provider anyway leaves a session behind that no inbox owns.
    return if attempt.nil?

    state = connect(mode, attempt)
    # The connect answer is the first state the dashboard has to show (it carries the QR,
    # or the code, for a provider that returns one), and for a polled backend it is also
    # what starts the pairing poll: nothing else would refresh either as it rotates. A
    # resume that answers `open` has nothing left to poll, and a chain started over one
    # would write `connect_failure` over a healthy connection the first time a request
    # failed.
    writer.apply(state.with_attempt(attempt), reset: true, attempt: attempt, provider: provider, instance: instance, answering: true)
    start_pairing_poll(mode, attempt) if state.connecting? && backend.class.state_polling?
    state
  end

  # What the inbox names as its way out, in the shape the connector takes. Nothing is a
  # request to go out directly: every connect states the whole request, so a connect that
  # left the proxy out would take a session off the one it had.
  def proxy
    url = channel.provider_config['proxy_url'].presence
    { 'url' => url } if url
  end

  def writer
    Whatsapp::Session::ConnectionStateWriter.new(channel)
  end

  # Identifies this attempt, and claims it before the provider is asked rather than after
  # it answers. Two connects for the same inbox produce two polling chains, and without a
  # token the older one cannot tell that the QR on screen is no longer the one it was
  # following: it would time out over a live pairing. Claiming first also orders the two
  # by the click rather than by which provider call happens to answer first, which is what
  # the fence in the writer then enforces: the older answer, and its dead QR, is refused.
  def claim_pairing_attempt
    attempt = SecureRandom.uuid
    result = writer.apply(
      model::ConnectionState.new(connection: 'connecting', pairing_attempt: attempt), reset: true, provider: provider,
                                                                                      instance: instance
    )
    attempt if result == :written
  end

  # The claim above already moved the dashboard to "connecting". Leaving it there when the
  # provider refuses the connection parks the operator on a pairing that never started,
  # which is the same dead screen the poll's ceiling exists to prevent.
  def connect(mode, attempt)
    backend.connect(
      model::Commands::SessionConnect.new(
        pairing: mode, phone: channel.phone_number.to_s.delete('+'),
        groups: capability?('groups'), history_sync: history_on_connect?, proxy: proxy
      )
    )
  rescue Whatsapp::Session::Errors::Error
    writer.apply(
      model::ConnectionState.new(connection: 'close', error: 'connect_failure'), attempt: attempt, provider: provider,
                                                                                 instance: instance
    )
    raise
  end

  # With the deadline resolved here, not by the worker. It is a ceiling on the attempt,
  # and a busy queue would otherwise hand a QR that expired while the job waited its own
  # two full minutes of polling on top of the wait.
  def start_pairing_poll(mode, attempt)
    Whatsapp::Session::PairingPollJob.perform_later(
      channel,
      pairing: mode, deadline_at: Whatsapp::Session::PairingPollJob.deadline_for(mode),
      fence: { provider: channel.provider, instance: instance, attempt: attempt }
    )
  end

  # Connecting again is the way out of a wrong-number quarantine, and the connect below
  # is what lifts it. The rejected account is still on the provider until its logout
  # lands, though, and that marker is the only thing keeping its chats out of this inbox:
  # lifting it first and pairing second would file somebody else's messages here for as
  # long as the new QR is on screen. So the wrong account goes before the marker does,
  # which also stands the asynchronous retry down before there is a new session for it to
  # kill. A provider that cannot be reached raises, and nothing was cleared or connected.
  #
  # None of which holds where a logout does not unpair. Uazapi answers 405 on
  # `/instance/logout`, so the strongest thing available is a disconnect, and the account's
  # credentials stay on the instance: connecting again resumes that same account, and this
  # would have lifted the marker for an account that never left, filing its chats here
  # until the next state quarantined the inbox all over again. The exits there are the
  # real ones, and the operator is told so: reset the instance on the provider, point the
  # inbox at another one, or correct the number on the inbox, which the next state the
  # provider reports then lifts the marker for.
  def end_disowned_session
    return unless Whatsapp::Session::ConnectionStateWriter.disowned?(channel)

    end_wrong_account
    raise Whatsapp::Session::Errors::NotSupported, I18n.t('errors.inboxes.channel.cannot_unpair') unless backend.class.unpairs?

    writer.apply(model::ConnectionState.new(connection: 'close'), reset: true, provider: provider, instance: instance)
  end

  # Best effort, and worth asking even of a provider that cannot unpair: a disconnected
  # instance stops sending, which takes the wrong account's traffic off this inbox at the
  # source while the quarantine holds.
  def end_wrong_account
    backend.logout
  rescue Whatsapp::Session::Errors::NotSupported
    nil
  end

  # A session that was already paired resumes; one that never was needs a QR (a pairing
  # code is requested explicitly from the dashboard).
  def pairing_mode
    channel.provider_connection['phone_number'].present? ? 'resume' : 'qr'
  end

  # `sender_type` rather than a class check: the association can hold a User (an agent's
  # own message), and a class comparison is what a reload breaks.
  def participant_address(message, sender)
    return if sender.nil? || message.sender_type != 'Contact'

    model::Address.for_contact(sender)
  end

  # Recipient ids reach the channel as bare phone numbers or as JIDs, depending on the
  # caller and on whether the contact has a LID.
  def address(recipient_id)
    recipient_id.to_s.include?('@') ? model::Address.parse(recipient_id) : model::Address.phone(recipient_id)
  end
end
