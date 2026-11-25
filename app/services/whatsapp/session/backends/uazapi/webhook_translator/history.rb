# The history half of the translator: the initial dump the phone sends after pairing and
# the answer to every on-demand request, which arrive as the same event under a
# discriminator of their own.
#
# Split out because the translator is at the length the project allows, and because these
# frames are the live ones minus three fields rather than a shape of their own.
module Whatsapp::Session::Backends::Uazapi::WebhookTranslator::History
  private

  # Only the messages are translated: `chats` is the provider's own CRM object for a
  # conversation and `labels` is the account's WhatsApp labels, neither of which this
  # layer imports.
  #
  # A batch carries up to 200 messages and one request can produce several, so the whole
  # batch becomes a single event: putting each message through the live path instead would
  # notify, automate and broadcast a year of history as if it had just arrived.
  def history
    return unless body[:event] == 'messages'

    messages = Array(body[:messages]).filter_map { |raw| historical(raw) }
    return if messages.empty?

    event(events::HistorySync.new(kind: 'messages', data: { 'messages' => messages.map(&:to_h) }))
  end

  # The history shape is the live one minus `type`, `mediaType` and `groupName`, so the
  # same builder reads it. What it cannot read is the media kind behind an audio, which is
  # what `mediaType` carries: a voice note imported from history arrives as an audio file
  # and the bubble says so, rather than guessing which of the two it was.
  def historical(raw)
    payload = raw.to_h.with_indifferent_access
    return if payload[:messageid].blank?

    inbound_message(payload, timestamp_ms(payload[:messageTimestamp]))
  end
end
