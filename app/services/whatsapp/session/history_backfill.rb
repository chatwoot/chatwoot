# The operator asked for history, just now.
#
# Two different things ask the phone for its history, and they are not the same decision.
# The inbox setting is standing consent: on every connect, take what the phone offers. The
# button is a single act: take it now, because a connection was down over the weekend or
# because somebody wants the context of a conversation that predates this inbox.
#
# Nothing on the wire tells the two apart. A history frame is a history frame whether the
# phone sent it on its own after pairing or in answer to a request, so the difference has
# to be held here: a mark with an expiry that says a person asked, recently.
#
# Without it the button would have to borrow the setting, and pressing it once would mean
# turning on a dump that then repeats at every future pairing. That is a bad trade for a
# one-off recovery, and it is what this exists to avoid.
module Whatsapp::Session::HistoryBackfill
  # A backstop, not the guard. What the window had to be short enough to avoid was a
  # reconnect landing inside it, because the dump that follows a pairing would then be
  # filed as if it had been asked for. `close!` removes that case by construction: the
  # session cannot come back up without having gone down first, and going down closes the
  # window. Tuning a number to make an accident unlikely is a worse answer than removing
  # the accident.
  #
  # With that gone, the only thing left for the clock to do is stop a mark from outliving
  # the request forever on a session that never drops, and the only cost of it being long
  # is nil. So it is sized for the case that remains: a phone that answers hours later,
  # once somebody unlocks it, which is exactly what the provider warns about.
  WINDOW = 6.hours

  module_function

  # Opens the window, and re-opens it while an answer is still arriving. A dump comes in
  # several frames over some stretch of time, and a window that closed between two of them
  # would drop the tail of the very import it authorised.
  def open!(channel)
    Redis::Alfred.set(key(channel), '1', ex: WINDOW)
  end

  # Called whenever the session is written as anything but open. A request travels to the
  # phone through the session, so one that ends takes any outstanding request with it, and
  # what arrives after the next pairing is the phone's own dump rather than an answer.
  def close!(channel)
    Redis::Alfred.delete(key(channel))
  end

  def pending?(channel)
    Redis::Alfred.get(key(channel)).present?
  end

  def key(channel)
    "WHATSAPP::HISTORY_BACKFILL::#{channel.id}"
  end
end
