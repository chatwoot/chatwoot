# When this inbox was last known to be receiving.
#
# History arrives as one undifferentiated pile, and the two halves of it want opposite
# treatment. Messages that piled up while the connection was down were never seen by
# anybody, because the system that would have shown them was off: those belong in the
# queue on Monday morning. Everything older was lived somewhere else and is being filed
# here for reference, so it belongs in the archive.
#
# The boundary is not age. A conversation from two hours ago that an agent already
# answered is history; a message from Saturday that nobody saw is work. What separates
# them is whether the inbox was covering the channel when it arrived, and the inbox knows
# that: the newest message it holds is the last moment it can prove it was listening.
#
# WhatsApp draws the same line itself, incidentally. Its history sync is typed, and
# `RECENT` means exactly "what arrived while this device was offline" as opposed to the
# bootstrap dump. Uazapi does not pass the type through (the frames carry `messages`,
# `chats` or `labels` and nothing else), so the line is redrawn here from what we hold.
module Whatsapp::Session::Inbound::Coverage
  module_function

  # Nil when the inbox has never stored a provider message, which is a first connection:
  # nothing predates coverage that has not also predated the inbox, so the whole import is
  # archive. That is also what keeps a freshly paired inbox from opening a year of threads.
  #
  # Only messages that came from the provider count. An agent's private note or a status
  # activity says the *dashboard* was in use, not that the channel was up, and a note
  # typed on Monday would otherwise date the coverage past the weekend that was missed.
  #
  # `created_at` rather than the provider timestamp in `content_attributes`: an imported
  # message is written with its original date, so the column stays the same clock for both
  # kinds of row, and it is a column rather than a jsonb key. Live traffic puts the two
  # within seconds of each other, which is the precision this boundary needs.
  #
  # Imported rows are excluded, and that is what makes the boundary hold still. They are
  # dated to when they were sent, so a gap message from Saturday is newer than the line it
  # was just measured against: with them counted, the second frame of the same sync reads
  # the first frame's own writes as coverage and files the rest of the weekend as archive.
  # It is also the truer reading. The column says when this inbox was covering the
  # channel, and a message filed after the fact is evidence of an import, not of an inbox
  # that was listening.
  def watermark(inbox)
    inbox.messages
         .where.not(source_id: nil)
         .where.not(Import::IMPORTED_SQL)
         .maximum(:created_at)
  end

  # True when the message arrived after the inbox stopped covering the channel: nobody
  # has had the chance to read it, so it is late mail rather than history.
  def gap?(message, watermark)
    return false if watermark.blank?

    message.sent_at > watermark
  end
end
