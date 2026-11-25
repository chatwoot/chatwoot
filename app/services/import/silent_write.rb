# Marks a stretch of work as "writing history", which is not the same as receiving it.
#
# An imported message goes through the same writers a live one does, and that is the
# point: what is stored must not depend on when it was imported. What must not run is
# everything a live message *sets off*. A year of history replayed through the ordinary
# path would notify every agent, fire every automation, post every outgoing webhook, wake
# the bots, reopen conversations somebody resolved months ago and send out-of-office
# replies for messages that were answered long ago.
#
# One thing does have to run, though, and it is why this has two levels rather than a
# boolean. Somebody pressed a button and is watching a screen. An unattended bulk import
# never wants this and stays `:silent` throughout; the level exists for the on-demand case. A gap thread that lands in
# the queue while the list shows the queue from before the import is a thread nobody works
# until they happen to reload, which defeats the point of importing it. So the gap half of
# a run is written in `:announce`, where the dashboard push survives and everything else
# is still suppressed, and the archive half stays `:silent`: eight hundred backdated rows
# have nothing to tell an operator now, and pushing one cable frame per row would be a
# flood aimed at every agent in the account.
#
# Which level a guard reads is the whole design, and getting it wrong is quiet in both
# directions. A guard that suppresses *fan-out* -- work aimed at the world, or at a queue,
# that a backdated row has no business doing -- belongs at `on?`, because that is true of
# history however it arrived. A guard that suppresses *routing or status* belongs at
# `archive?` alone: under `:announce` the thread is somebody's live work, recovered a
# minute late, and it has to be assigned and statused the way any other arrival would be.
# Suppressing those there leaves the gap thread sitting unrouted, which is the same "nobody
# works it until they reload" failure the level was invented to avoid.
#
# The guards, all declared in config/initializers/import_guards.rb:
#
#   AsyncDispatcher#dispatch                 the listeners that act on the world:
#                                            automations, campaigns, CSAT, webhooks,
#                                            notifications, reporting, the outgoing
#                                            channel. Never reached, at either level
#   SyncDispatcher#dispatch                  ActionCableListener (the dashboard push) and
#                                            AgentBotListener. Under `:announce` the cable
#                                            listener runs and the bot does not
#   Message#execute_after_create_commit_callbacks
#                                            the side effects that are not events: reopen,
#                                            message templates, the reply send, and the
#                                            activity stamps the importer sets itself.
#                                            Under `:announce` it re-emits `message.created`
#                                            on its own, so the thread an operator has open
#                                            fills in rather than only the list card
#   Contact#ip_lookup                        a job to resolve an address an imported contact
#                                            does not carry. Useless at either level
#   Conversation#run_auto_assignment         archive only: half a million archived threads
#                                            asking the inbox to redistribute capacity, or
#                                            landing outright in a working agent's queue
#   Conversation#set_active_bot_conversation archive only: an inbox with a bot starts its
#                                            conversations `pending` and overrides the
#                                            status the importer asked for
#   Contact#fetch_avatar_from_gravatar       archive only: one outbound request per contact
#                                            created, which is a flood only when the
#                                            contacts arrive by the hundred thousand
#   Message#hold_pending_scheduled_messages  archive only: an old incoming row satisfies
#                                            `hold_on_reply` the way a live one does, and
#                                            would hold every follow-up in the account
#   Company#fetch_favicon                    archive only, Enterprise: Gravatar's shape,
#                                            one request per company at a third party
#   Attachment#enqueue_audio_transcription   archive only, Enterprise: Captain credits per
#                                            file, spent on conversations closed before the
#                                            feature existed
#   Message#reindex_for_search               only where the writer says it indexes its own
#                                            rows, which is the second flag below
#
# Scoped to the thread rather than to a request: the importer runs inside a Sidekiq job,
# and the flag must not leak into whatever that worker picks up next.
# The second flag is orthogonal to the level and answers a different question: not "how
# loud is this write" but "who is going to index it". `Message#reindex_for_search` enqueues
# one Searchkick job per row, which a backfill cannot afford and which
# `Import::HistorySettlement` takes over in batches. So it is suppressed only for a writer
# that has said it will do that, and left alone for one that has not -- the WhatsApp
# importers, which are handed a webhook's worth of rows and thrown away. Read off the level
# instead, a batch of theirs that raised after some rows committed would lose those rows
# from the index for good: they never reach `settle`, and the retry filters them out as
# already stored.
module Import::SilentWrite
  KEY = :import_silent_write
  INDEXING_KEY = :import_indexes_its_own_rows

  module_function

  # Nested calls are safe: the previous value is restored rather than cleared, so an
  # importer running inside another silenced block does not un-silence it on the way out.
  # That restore is what lets the gap run raise the level for its own stretch and hand the
  # archive level back afterwards, inside one enclosing `wrap`.
  #
  # `archive` is for the one stretch that is both: history somebody pressed a button for,
  # which is still history. It reaches the dashboard like `:announce` and keeps every
  # archive-only guard like `:silent`, so an old row does not route a thread, start a bot
  # or hold a scheduled send just because somebody is watching it arrive.
  def wrap(announce: false, indexing: false, archive: false)
    previous = ActiveSupport::IsolatedExecutionState[KEY]
    previously_indexing = ActiveSupport::IsolatedExecutionState[INDEXING_KEY]
    ActiveSupport::IsolatedExecutionState[KEY] = level(announce, archive)
    ActiveSupport::IsolatedExecutionState[INDEXING_KEY] = true if indexing
    yield
  ensure
    ActiveSupport::IsolatedExecutionState[KEY] = previous
    ActiveSupport::IsolatedExecutionState[INDEXING_KEY] = previously_indexing
  end

  def on?
    ActiveSupport::IsolatedExecutionState[KEY].present?
  end

  # Whether this stretch may reach the dashboard. Only ever true inside `on?`, so a guard
  # that checks it still has to check `on?` first to tell "importing, announcing" from
  # "not importing at all", which is the ordinary case and must go through untouched.
  def announce?
    %i[announce announced_archive].include?(ActiveSupport::IsolatedExecutionState[KEY])
  end

  # Writing history nobody is waiting on. The level a guard should read when what it
  # suppresses would change where a conversation goes or what state it is in, rather than
  # merely stopping a side effect.
  def archive?
    %i[silent announced_archive].include?(ActiveSupport::IsolatedExecutionState[KEY])
  end

  def level(announce, archive)
    return :silent unless announce

    archive ? :announced_archive : :announce
  end

  # Whether the writer has taken the search index on itself. Only the guard on
  # `Message#reindex_for_search` reads this, and only a writer that batches sets it: an
  # importer that does not is left with the ordinary per-row callback, which is the only
  # thing that would index a row committed by a batch that then raised.
  def indexing?
    ActiveSupport::IsolatedExecutionState[INDEXING_KEY].present?
  end
end
