# The history half of the facade: asking a chat for what came before, and whether this
# inbox asked for it at all.
#
# Split out for the same reason the group half is: the facade is at the length the project
# allows, and this is its own subject.
module Whatsapp::Session::Facade::History
  # Asks a chat for the history behind it. Nothing here waits for it: the provider
  # acknowledges the request and the messages arrive as `history.sync` events, if the
  # phone is awake to answer at all, which is why the caller is told the request went out
  # rather than what it produced.
  # `before` is the stored message to page backwards from, or nil to start from the oldest
  # the provider knows. A message rather than an id: the anchor needs its timestamp and its
  # direction too, and the row is the one place that has all three together.
  #
  # A backend that can only page backwards from a message gets the oldest one this inbox
  # holds for the contact, across every thread it opened, which is where the phone's copy
  # and ours stop overlapping. When that one arrived live rather than out of a dump, the
  # phone will not page from it, and the key kept from the archive the import dropped is
  # asked instead (see HistoryAnchors). With nothing to page from, nothing is asked: the
  # answer is false rather than a request the provider refuses.
  def request_history(contact, count: nil, before: nil)
    raise Whatsapp::Session::Errors::NotSupported, I18n.t('errors.inboxes.channel.history_sync_unsupported') unless capability?('history_sync')

    anchor = model::Commands::HistoryAnchor.for_message(before)
    if backend.class.history_needs_anchor? && before.nil?
      anchor = anchor_for(contact)
      return false if anchor.nil?
    end

    backend.request_history(
      model::Commands::HistoryRequest.new(chat: model::Address.for_contact(contact), count: count, before: anchor)
    )
    true
  end

  # Whether this inbox asked for the history the phone already has. Off unless the
  # operator turned it on: the phone answers with everything it has, and an inbox that
  # never asked should not have a year of somebody else's conversations imported into it
  # on the first connect.
  #
  # Public because it also gates the on-demand backfill. The answer to a request arrives
  # on the webhook, and the webhook only carries history for an inbox that subscribed to
  # it, so with this off the request would go out and the reply would be dropped.
  def history_sync?
    capability?('history_sync') && ActiveModel::Type::Boolean.new.cast(channel.provider_config&.dig('history_sync')).present?
  end

  private

  # What a connect asks for, which is the setting except on a backend whose gap only ever
  # arrives inside the history dump: see Backend.history_on_every_connect?.
  def history_on_connect?
    capability?('history_sync') && (backend.class.history_on_every_connect? || history_sync?)
  end

  # The oldest imported message first, because only a dump message is an anchor the phone
  # answers, and a live row older than the dump would otherwise keep every request on the
  # same page. Then where a dropped archive ended, then whatever is oldest.
  def anchor_for(contact)
    stored = stored_messages(contact)
    oldest = stored.where(Import::IMPORTED_SQL).first
    return model::Commands::HistoryAnchor.for_message(oldest) if oldest

    Whatsapp::Session::HistoryAnchors.recall(channel.inbox, addresses_of(contact)) ||
      model::Commands::HistoryAnchor.for_message(stored.first)
  end

  # Every address the chat may have been dumped under: the dump names it the way the phone
  # holds it, which is not always the way the contact row does.
  # The other spelling of a Brazilian or Argentinian mobile number too, which is how a dump
  # can name a contact stored under the first.
  def addresses_of(contact)
    lid = model::Address.lid(contact.identifier) if contact.identifier.to_s.end_with?('@lid')
    phones = Whatsapp::Session::PhoneMatch.variants(contact.phone_number).map { |number| model::Address.phone(number) }
    [model::Address.for_contact(contact), *phones, lid].compact.uniq(&:to_jid)
  end

  def stored_messages(contact)
    Message.where(conversation_id: contact.conversations.where(inbox_id: channel.inbox.id).select(:id))
           .where.not(source_id: nil)
           .reorder(created_at: :asc, id: :asc)
  end
end
