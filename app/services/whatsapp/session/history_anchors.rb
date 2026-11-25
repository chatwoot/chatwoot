# Where a chat's history can be paged back from when its archive was not filed.
#
# The phone answers a history request only when the anchor is a message it sent in the
# pairing dump; anchored on a message that arrived live afterwards, the request gets no
# answer at all (measured on the connector, fazer-ai/whatsapp-connector#349). An inbox that
# keeps its archive holds dump messages to anchor on. One that does not, which is the
# default, holds only live ones, and the button would ask a question the phone never
# answers.
#
# So when the importer drops a chat's archive it keeps the newest dropped message's key
# here, and a request for that chat pages back from it: the answer is exactly the archive
# that was dropped, less that one message. Newest rather than oldest because the answer
# is what came before the anchor.
#
# In Redis and not on a row: the chat may have no contact yet, and losing the key only
# returns the button to the anchor it would have had anyway.
module Whatsapp::Session::HistoryAnchors
  # Refreshed on every write, so an inbox that keeps pairing keeps its anchors and one that
  # was deleted stops holding the key.
  TTL = 90.days

  module_function

  # `message` is an InboundMessage from a dump. Kept only if newer than what is there, so
  # the slices of one chat can arrive in any order.
  def remember(inbox, message)
    field = message.chat.to_jid
    known = read(inbox, field)
    return if known && known['timestamp'].to_i >= message.timestamp.to_i

    anchor = { 'id' => message.id, 'timestamp' => message.timestamp.to_i, 'from_me' => message.from_me == true }
    Redis::Alfred.with do |conn|
      conn.hset(key(inbox), field, anchor.to_json)
      conn.expire(key(inbox), TTL.to_i)
    end
  end

  # The anchor kept for the first of `chats` that has one, as the command carries it.
  def recall(inbox, chats)
    chats.each do |chat|
      known = read(inbox, chat.to_jid)
      next if known.nil?

      return Whatsapp::Session::Model::Commands::HistoryAnchor.new(
        id: known['id'], timestamp: known['timestamp'].to_i, from_me: known['from_me'] == true
      )
    end
    nil
  end

  def read(inbox, field)
    raw = Redis::Alfred.with { |conn| conn.hget(key(inbox), field) }
    raw.present? ? JSON.parse(raw) : nil
  rescue JSON::ParserError
    nil
  end

  def key(inbox) = "WHATSAPP::HISTORY_ANCHORS::#{inbox.id}"
end
