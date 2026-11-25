# The namespace every importer lives in, and the one flag they all share.
#
# `content_attributes.imported` says a row was filed after the fact rather than received.
# Two things read it and they are in different layers, which is why the predicate lives
# here rather than beside either of them: Inbound::Coverage measures where an inbox stopped
# covering its channel and has to exclude backfilled rows, or the second frame of a sync
# would read the first frame's own writes as coverage; HistorySettlement asks whether a
# thread holds anything but imported traffic before it stamps the unread clock.
#
# `content_attributes` is a text column holding JSON, hence the cast, and the key is absent
# on every row written before imports existed, hence the default.
#
# `content_attributes.imported_text_only` says the row was filed from a lean fetch, with
# its attachments deliberately left in the mailbox. It exists because "this Message-ID is
# already stored" is not the same question as "this message is fully imported": without it
# a first pass under a narrow cutoff makes every later pass skip the row, and the
# attachments become unreachable on a mailbox the import exists to preserve.
module Import
  IMPORTED_SQL = "COALESCE((content_attributes#>>'{}')::jsonb->>'imported', 'false') = 'true'".freeze
  TEXT_ONLY_SQL = "COALESCE((content_attributes#>>'{}')::jsonb->>'imported_text_only', 'false') = 'true'".freeze
end
