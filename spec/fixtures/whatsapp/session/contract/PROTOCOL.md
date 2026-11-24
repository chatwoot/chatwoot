# WhatsApp session protocol v1: the normative half

This is the contract a client is held to, and it travels with the directory: the Chatwoot
side vendors it and counts it in the checksum recorded in `CONTRACT_REF`. The connector's
repository also has a `README.md` here, which is orientation for somebody reading the
directory there; it is deliberately not vendored, so a vendored copy does not contain it and
nothing in this file depends on it.

## Transport

Frames travel as Redis stream entries. Every stream field is a string on the wire;
the schema describes the **decoded** frame, where `v`, `epoch`, `seq`, `ts`,
`deadline` and `max_runtime_ms` are integers and `payload` is an object (transported
JSON-encoded).

**A command carries two different ceilings, and they answer different questions.**
`deadline` is an instant and says *do not start this after that moment*: a command that
reaches its owner late is dropped unrun, answered `expired`. `max_runtime_ms` is a
duration, measured from the moment the work begins, and says *do not let this run longer
than that*; it says nothing about arriving late. A command carrying both gets whichever
runs out first, and one carrying neither is bounded by something the caller did not
choose, which the next paragraph names.

The distinction exists because a teardown needs one without the other: a `session.logout`
dropped for arriving late is a device left linked on somebody's phone with nothing saying
so, while the same command parked on a socket write holds every other command for that
account behind it. With one field a client had to choose, and chose neither.

**A command with neither field is still bounded, and mostly not by this connector.** Most of what this connector sends carries a ceiling that is the WhatsApp library's and not this connector's, seventy five seconds, which covers a message send and an information query alike, and several paths are held to something tighter that this connector chooses. What comes back when one of those runs out is `timeout`, the same word a caller's own `max_runtime_ms` produces and with the same meaning: nobody here knows the outcome and nothing afterwards will. But some paths escape every ceiling, named below, and this contract does not claim the list is complete or count them. So a client that has a deadline of its own enforces it on the reply rather than inferring one from this paragraph.

**A client may resend such a command, and what the identifier buys depends on which command it is.** For most of them the connector records only what succeeded, so a resend under the same `idempotency_key` after a failure finds nothing to answer from and runs the work again. That is what a resend is for, and it is what a send needs: the resend carries the `message_id` the first attempt used and every client downstream discards a repeat of an id it already has, so the work happening twice costs nobody anything. A frame redelivered after the first attempt *succeeded* is answered from the record instead of being run twice, which is the narrow thing the identifier has always been good for.

**For the commands that set a value or apply a delta, the connector also writes down that the command is about to run, and a resend is answered rather than repeated.** Those are a participant added or removed, a join request answered, a chat marked read or unread, a group's name, description, photo or settings, an invite link rotated, a presence, and a call placed. Repeating one of those is not repeating a message: it writes a value on top of state that has since moved, or rings the callee's phone a second time, and nothing downstream discards it. So a resend of one whose first attempt succeeded is answered from its result, and one whose write went out and whose answer never came back (the connection dropped, or WhatsApp's own wait for the answer ran out) is answered `timeout` again rather than run a second time. One stopped by its own deadline is not held that way: the deadline can end it before the write as easily as after, and nothing here can tell which, so a resend runs it again. Only a write that may have reached WhatsApp holds the key that way: a failure that left nothing standing there -- the refusals the connector makes before writing anything, and the writes it can tell never went out -- leaves no record either way, so that retry does the whole thing. What this costs a client is that the same key stops being a way to force the work to happen: a command that ran and lost its answer will not run again under it, and no answer from here will ever say what it did. A client that cannot afford that reads the state back before resending rather than resending blind.

**`group.create` is the exception, and keeping the key is what makes the recovery work.** It writes down what it is about to do before it asks WhatsApp, so a record exists whether or not the attempt succeeded, and a retry under the same `idempotency_key` consults that record: it returns the group the first attempt made, or answers `not_settled` while WhatsApp's notification is still deciding which request made which group. Retrying with a fresh key instead makes a second group. It is the one command whose outcome settles itself, which is why `not_settled` exists for it and for nothing else: everywhere else an attempt nobody can speak for stays that way, and `timeout` is what a resend of one is answered with.

**Four commands now carry a ceiling of this connector's, and what is left unbounded is a different shape.** The retry that used to wait with no timer of its own is bounded here, so a `message.send` whose caller named nothing still ends. The gate that ceiling sits on is the one `message.edit`, `message.revoke` and `message.react` leave by as well, so those three carry it too, and they are safe to resend for the reason the send is: each one goes out under the id of the message it acts on, or under the `idempotency_key` or the command's own id when it names no message, so a redelivery repeats an identifier the receiving side already holds and discards. What no ceiling reaches is a wait that does not look at the context at all, and a send's way out holds more than one: the node already being written to the socket, the lock the library takes to keep one send per connection at a time, and the read lock on the socket, which a reconnection holds for as long as its dial and handshake take. A command held by any of those does not come back when a ceiling runs out, and it does not end the commands queued behind it either: `max_runtime_ms` is measured from the moment a command begins, so one that waited its turn starts a full budget with the waiting already over. What a ceiling does for the queue is narrower than that. The held call returns the instant it is released, instead of spending what is left of a reply nobody is bringing, and the queue moves from there. A client that would rather a queued command be dropped than run late names a `deadline`, which is the field checked before the work starts. So `max_runtime_ms` is worth setting, and it is worth knowing what it buys: it bounds every wait that watches the context, and says nothing about a wait of that other kind. **A client that cannot wait indefinitely needs its own timeout on the reply**, not a field on the command: this connector will answer, and what no field here can promise is when.

**Neither ceiling reaches `session.wake`, and a client should not expect `expired` for one.**
It is carried out before any session is involved, and nothing on that path reads `deadline`.
That is the whole point for a wake: it is the only thing that starts a session with no entry
yet in the connector's own record of what each session should be, so retiring one for
arriving late leaves an account paired, owned by nobody and silent. What paces a wake that
keeps coming back is instead the fleet's own backoff described under `wa:quarantine:<sid>`
below: not a count of deliveries and not a clock, but the connector declining to make the
same attempt again for a minute, then two, up to an hour.

`admin.ping` goes the other way, and the difference is what refusing costs. A ping asks what
this instance is running *now*, so one answered after its deadline is a true sentence about
the wrong instant, sent to a caller that stopped waiting; refusing starts nothing and tears
nothing down. A late ping is answered `expired`, and a client that sent one without a
`reply_to` sees nothing at all: the refusal is recorded as
`wac_command_duration_seconds{type="admin.ping",outcome="expired"}` on the instance and
nowhere else, with no line in its log.

`session.delete` is the exception among the three, and it is the one that costs a client
something. It travels the control stream but it is not carried out there: the connector
adopts the account so that the account's own executor can tear it down, which puts the
teardown under both ceilings like any other command. **A client should not put a `deadline`
on a teardown** -- `session.delete` or `session.logout` -- and should bound it with
`max_runtime_ms` alone. One that arrives after its deadline is answered `expired` and the
account is not torn down, which is the device left linked on somebody's phone that the two
fields exist to keep apart, and it is the whole of what the refusal costs. The adoption
behind it costs nothing further: an account opened so that a teardown can reach its
executor is never connected, and one whose teardown was then refused for arriving late is
given back, by a heartbeat rather than by the answer, so a refused teardown does not
leave the account owned by the instance that refused it. A client that sends another
command for that account in between is talking to the instance that still owns it, and one
that arrives while the lease is going back is left pending for whoever takes the account
next, which is what every hand-back does.

**A teardown that ran out of time answers `not_attempted` when nothing was sent, and a
client should retry that one.** The two ways a teardown fails on time are not the same
fact and the connector tells them apart. `timeout` is the ordinary one: the request was
on its way and how far it got is not known here, so a retry may be repeating something
that already happened. `not_attempted` is the connector saying it is certain nothing was
written to WhatsApp -- the socket was being dialled and its lock was never free, so the
unlink was never called. The account is exactly as it was, the device is still linked on
somebody's phone, and a retry does the whole thing rather than the half that is left.
Retrying with the same `idempotency_key` is correct: a command that failed is not
recorded, so the key answers nothing and the retry runs. The same word answers a
`session.logout` in the same state, because it is the same fact about the socket; a
logout whose request did reach WhatsApp and whose answer was lost is the other case and
keeps `timeout`. A client that treats `not_attempted` as final leaves a device linked
that no later command can remove, because the credentials that would sign the unlink are
the ones the teardown would have thrown away.

**A `group.create` whose outcome is not decided yet answers `not_settled`, and a client
should ask again in a moment.** Two requests for a group of the same name, both still
open, make a group on WhatsApp that is evidence for either and proof for neither.
Answering one of them with it would hand that request the other's conversation and skip
the creation it asked for, so the connector refuses until WhatsApp's own notification
names which request made which group, which ordinarily arrives within seconds. This is
the third answer about time and it is not either of the other two: `timeout` says nobody
here can tell and nothing afterwards will, `not_attempted` says the request never went
out, and `not_settled` says it did and the connector expects to know which shortly.
Retrying with the same `idempotency_key` is correct and is the point: a command that
failed is not recorded, so the key answers nothing and the retry runs, and the retry is
what collects the group the first attempt made rather than making a second one. A client
that treats it as final leaves the operator with a group nobody's conversation points at;
a client that treats it as `internal` pages somebody for a case that settles itself.

**`not_settled` is not a promise that asking again will settle it soon, and a client bounds its retries.** The word says the outcome is undecided here, not that a decision is coming. One state does not resolve by asking: an attempt whose intent was recorded and whose request never reached WhatsApp. Two things leave it that way, and neither is rare enough to leave unsaid. The process can die between the two. Or the connector's own ceiling on that write can run out after the database has committed the row and before this side learned that it had, a race nobody here can see the winner of: the row is on record, nothing was ever asked of WhatsApp, and the connector has already answered that it could not record the intent. No group was made, so no notification will ever name one, and every redelivery gets `not_settled` again. So a client retries a few times over seconds, and a `not_settled` that survives that is most likely a stranded intent: stop sending that key, and tell somebody. The connector drops an attempt that has not learned which group it made 24 hours after its first delivery, however often it was asked about since, and a delivery of the same key after that creates the group as if for the first time. The cost is the other direction: if the request did go out and WhatsApp's notification naming the group arrives later than those 24 hours, the notification finds no attempt to name, and that later delivery makes a second group.

**Both ceilings bound the wait on WhatsApp, not the bookkeeping that follows it.** Once a
teardown's unlink has been answered, the connector finishes deleting the credentials, the
device mapping and the session's epoch counter on a bound of its own, and a ceiling that
ran out during the unlink does not cancel any of it: an account whose remote half is gone
and whose local half survived is one the connector would go on adopting and resuming over
credentials WhatsApp has already revoked. So a client may set the ceiling to how long it
is willing to wait for an answer, not to how long the teardown is allowed to take in all.

| Stream / key | Direction | Frame |
|---|---|---|
| `wa:events:<shard>` | connector → client | `event` |
| `wa:cmd:<sid>` | client → connector | `command` |
| `wa:control` | client → any connector | `command` (`session.wake`, `admin.ping`, `session.delete`). A connector also writes a `session.wake` here, putting back one it acknowledged for an account whose owner then gave it back (see `wa:owed-wake:<sid>`) |
| `wa:reply:<command_id>` (LIST) | connector → client | `reply` |

`seq` is monotonic per `(sid, epoch)` and, together with the per-session shard
assignment, is what lets the consumer drop out-of-order redeliveries.

**A client must read the number of event streams from `wa:meta`, and consume every one of
them.** The count is the `event_shards` field of the `wa:meta` hash, and the streams are
`wa:events:0` up to `wa:events:<event_shards - 1>`. A session's events all land on one of
them, and which one is `fnv1a32(sid) % event_shards`: the 32-bit FNV-1a hash of the sid's
UTF-8 bytes, taken modulo the count. A client that reads every stream does not need the
hash; one that wants to locate a single session's stream does, and it is half of the
agreement, so it is spelled out here with vectors below. A client that assumes a count
instead of reading one is wrong for a fraction of its sessions and silently so: with 8
streams read against 16 published, every session on streams 8 to 15 never receives an
event, and everything else works.

A client must read it when it starts, and can keep it from then on. A connector writes `wa:meta` when it starts,
before it opens any session, so no event exists until the count does. A client that starts
first may read a provisional count meanwhile, provided it takes the published one as soon
as it appears and never reads fewer streams than that. The published count only changes with
the whole fleet stopped: a connector whose own count disagrees with `wa:meta` refuses to
start. So a count that changes under a running client is an operator re-sharding, and the
safe answer is to stop reading and restart on the new count once the old streams are
drained, not to follow it on the fly: the sessions that moved would be read out of order.

| sid | `fnv1a32(sid)` | shard of 8 | shard of 16 |
|---|---|---|---|
| (empty string) | `0x811c9dc5` | 5 | 5 |
| `inbox-1` | `0x2cb1ca69` | 1 | 9 |
| `inbox-2` | `0x29b1c5b0` | 0 | 0 |
| `inbox-7` | `0x2eb1cd8f` | 7 | 15 |
| `9c2b7d1e-0000-4000-8000-0000000000c1` | `0x9cac14b8` | 0 | 8 |
| `sessão-ç` | `0x71e18cc7` | 7 | 7 |
| `abc` | `0x1a47e90b` | 3 | 11 |

**A client must deduplicate on `message.id`, and `seq` does not do it for you.** Delivery
is at-least-once per event, and the two mechanisms cover different things. `seq` catches
the same event handed over twice by the transport. It does not catch the case where one
WhatsApp message reaches the client as *two different events*, each with its own `seq`,
which is what a redelivered `message.send` produces: WhatsApp does not deduplicate a
stanza id, so the second attempt puts a second copy of the message on the wire, and the
connector publishes both. Measured, from an immediate resend out to thirty minutes
apart, and for direct chats and groups alike (#215).

This is not an edge case the client may skip. The connector's inbound path publishes a
message more than once **on purpose** in several places -- a placeholder published before
the real body arrives, a decryption that resolves after the fact, a session that changed
hands mid-publish -- and every one of them is written on the assumption that the client
keeps the first row and discards the repeat. A client that does not deduplicate on
`message.id` will show the same message twice without having done anything wrong.

**A `message.edited` may carry `unsupported` content, and a client keeps the bubble it
has.** A correction whose new body the connector cannot render is published with the
`unsupported` placeholder (`unknown_type`, or `empty` for a correction with no body)
rather than held back: WhatsApp closes the session's socket fifty minutes after
delivering anything that was not acknowledged, and again on every redelivery, so a
correction kept for a later build costs a dropped connection every fifty minutes (#402).
The event says the message was corrected into something this connector cannot show. It
is not a new body, and writing it over the one the client holds would blank a message
that was readable.

**An `unsupported` placeholder may name what arrived, in `detail`.** For `protocol` it is the name of the WhatsApp protocol message's type (`EPHEMERAL_SETTING`, `REMINDER_MESSAGE`), or `TYPE_<n>` for a type newer than the connector's own list. For `unknown_type` it is the name of the field the body arrived in (`pollCreationMessage`, `buttonsMessage`), the first one in WhatsApp's own declaration order when there are several, or `FIELD_<n>` for a field newer than the connector's own list. It is absent for every other reason. It is there for whoever investigates a placeholder later, and a client stores it as given: the names are WhatsApp's and change when WhatsApp's do, so nothing should branch on them (#415).

**A catalog product is shown as a product, sent or quoted, even when nothing about it is readable.** A business that shares an item of its catalog sends a `rich` card of kind `product`: the picture is its `media`, the name its `title`, the description its `body`, and the product itself is in `product` (id, `price_1000` and `sale_price_1000` in thousandths of the currency's unit, `currency`, `retailer_id`, `url`, `image_count`, the `owner` whose catalog it is, an inline `thumbnail`). A customer asking about an item from the catalog sends text whose `quoted_id` (`product_inquiry_<id>`) names no message, because WhatsApp quotes the product and not a message; the product is in `quoted_product`, with the same fields. A client shows that quote the way WhatsApp does, with the product's name, price and picture, instead of looking `quoted_id` up. Every field is what WhatsApp sent: a price or a currency it left out is absent, never zero or a default. A `product` or a `quoted_product` with nothing in it is still published: it means there is a product WhatsApp sent nothing readable about, and a client says so, so the agent can look it up on the phone, instead of showing an ordinary message (#426).

**A catalog order is a card of kind `order`, with the order itself in `order`.** It is not content of its own type because a client refuses a content type it does not know, and dropping the message (or, in `history.sync`, the slice around it) is worse than the placeholder it replaces. The card's parts are what WhatsApp shows on an order in the chat, written as WhatsApp Web writes them in English: `title` is the item count (`2 items`), `body` the words the customer wrote with the order, and `footer` the estimated total in the currency's notation (`€25.00 (estimated total)`, absent for a currency code the connector does not know). They are there for a client that renders only the parts. A client that reads `order` renders it in its own language from the numbers. `order` carries WhatsApp's summary (`id`, `title` as WhatsApp carried it, which is the seller account's name and is not on WhatsApp's card, `status`, `surface`, `item_count`, `total_1000`, `currency`, `seller` as an address, a number or a LID, `thumbnail`) and, on a live message, the `items` WhatsApp's catalog API returns (`product_id`, `name`, `quantity`, `price_1000`, `currency`, `variant`, `image`) with `subtotal_1000`. The connector asks for them the way WhatsApp Web Business does, by HTTPS to `graph.whatsapp.com`, because the IQ on the socket answers `feature-not-implemented`. The query has a short deadline and the order is published without `items` when it fails or runs out: nothing corrects the message afterwards. An order out of `history.sync` never has them, because a dump makes no network call while it is published. Amounts are integers in thousandths of the currency's unit, the scale of `total_1000`, and an item's `price_1000` (and `subtotal_1000`) is published only when the catalog's total matches `total_1000`, in thousandths or in whole units. It is absent otherwise (#422).

**Which stream a command goes on is part of the contract, not a detail.** A connector
reads `wa:cmd:<sid>` only for the sessions it is running, so a command addressed to a
session nobody has adopted is delivered to no connector at all and is lost when the
stream is trimmed. `wa:control` is read by every connector, which is why the commands
that have to reach an account nobody owns ride it:

- `session.wake` starts a session nobody is running, which is the whole point of it.
  **It puts the account in the air only when the connector already knows it should be.**
  A wake carries no connect of its own, so what licenses the dial is the record the
  client's own `session.connect` left (see the desired state below the key table): a wake
  with `desired: "connected"` for an account that has paired and whose client last asked
  for it to be connected adopts it and connects it with what that connect asked for, the
  group subscription, the call policy and the proxy included, the same way the resume
  sweep does. Every other wake adopts the account and stops there: `desired:
  "disconnected"`, an account with no record, one its client turned off, and one that
  never finished pairing, which has nothing to resume. So a client that has never
  connected a session, or wants it connected differently, still sends `session.connect`
  after the wake; sending it after a wake that already connected is harmless, since a
  resume on a session that is up or on its way up changes nothing. The record is read
  again when that connect runs, so a `session.disconnect` or a `session.connect` sent
  before the wake is what the account ends up doing. A wake is not a way to reach the
  instance already running a session: the fleet hands it to whichever instance reads it
  first, and one that does not own the account acknowledges it and does nothing.
- `session.delete` tears one down, and the account it matters most for is exactly the
  one that is down: an inbox destroyed while its session was not connected, or
  destroyed while the fleet was restarting.

Both are accepted on `wa:cmd:<sid>` as well, and a connector running the session
carries them out from there. A client that publishes `session.delete` only to the
session's own stream therefore gets the teardown whenever the session happens to be
up, and silence otherwise.

What `wa:control` guarantees is delivery to *some* connector, not to a particular one.
Every connector reads the stream under one consumer group, and what the one that read an
entry does with a session another connector is running depends on the command. A
`session.delete` is given up by the one that read it and reclaimed later, possibly by the
same one: an account **nobody** owns is torn down by whoever reads the entry, which is the
case this route exists for and is deterministic; an account a connector is **running** is
torn down when the entry reaches that connector, which happens but is not bounded. A
`session.wake` is not given up: it asks for the account to have an owner, and it has one,
so the entry is acknowledged and never reaches that owner (see `session.wake` above). The
exception is an owner that is giving the account back (`wa:handback:<sid>` below): there
the wake is left pending, because once the account is unowned it is the wake that starts it
again. An owner can decide to give an account back a moment before it writes that mark, and
a wake read in between is acknowledged like any other; so the connector that acknowledged
it leaves it owed to the owner (`wa:owed-wake:<sid>` below), and if the owner then lets the
account go, the release puts a `session.wake` for it back on `wa:control`, with the same
payload and an `id` of its own. A client can therefore see a `session.wake` on `wa:control`
that it did not write. Nothing is put back by an owner that keeps the account, by one that
deleted it, or for an account the fleet is leaving alone after failed attempts: that one is
brought back by the connector when its wait is over, as it would have been without the wake.
Nothing in the protocol asks an owner to give a session up **on demand**: a
`wa:handoff:<sid>` key was declared for that once and removed here, having never had
anything behind it. An owner giving a session up **of its own accord** is a different thing
and does exist -- it is `wa:handback:<sid>` in the table below, and it is the reason a wake can meet an account that is owned and on its way to
being unowned.

Around those four keys sit the ones that decide who reads and who writes. They are not
frames, but both sides have to agree on them, so they are part of the contract:

| Key | Type | Owner | Meaning |
|---|---|---|---|
| `wa:meta` | HASH | connector | `protocol_min`, `protocol_max`, `event_shards`; a connector whose `event_shards` disagrees refuses to start |
| `wa:instances`, `wa:instance:<inst>` | SET, HASH (PX 15s) | connector | live instances and what they advertise: `version`, `protocol_min`, `protocol_max`, `advertise_url`, `media_token`, and `calls`, `"true"` when the instance carries the voice of calls and `"false"` when it does not (see the calls conventions) |
| `wa:handback:<sid>` | STRING (PX 30s, not renewed) | connector | the instance that holds a session's lease and has started giving it up. Written before the release, compared against the lease holder by the acquire, cleared by the release, and left to expire when the release never lands. A `session.wake` that arrives in that window is left pending rather than acknowledged, so a client can see up to one lease TTL of silence before the account is picked up |
| `wa:owed-wake:<sid>` | HASH (PX 30s, not renewed) | connector | a `session.wake` acknowledged for an account some instance owns: `holder` names that instance, and the other fields are the wake to put back. The holder's release writes them to `wa:control` in the same step and deletes the key; a holder that keeps the account lets it expire. The release of an account its holder deleted drops it instead |
| `wa:lease:<sid>` | STRING (PX 30s, renewed) | connector | which instance owns a session. It expires on its own, which is what lets an account whose owner died be taken over |
| `wa:lease-epoch:<sid>` | STRING (**no expiry**) | connector | the epoch that owner holds the session under, incremented on every acquisition. It must outlive every disconnection, logout and re-pairing of the account, and only a `session.delete` removes it |
| `wa:idem:<sid>:<key>` | STRING | connector | command idempotency (`msg:<message_id>` for sends) |
| `wa:idem-try:<sid>:<key>` | STRING | connector | a command that ran and whose outcome never came back; expires on its own clock |
| `wa:resume:<sid>` | STRING (EX 60s) | connector | a turn taken to bring an unowned session back, so the fleet asks about one account once per window |
| `wa:quarantine:<sid>` | HASH (EX wait + 1h) | connector | `strikes` and `until`: how many times a session failed to come back, and how long the fleet leaves it alone. `attempt` is the connector's own bookkeeping, telling one failure from a retry of the same one |
| `wa:events:<shard>:lease` | STRING (EX 30s) | client | which consumer reads a shard; exactly one at a time, which is what preserves order |
| `wa:consumer:<cid>` | STRING (EX 15s) | client | consumer heartbeat and the shards it holds |
| `wa:cursor:<sid>` | STRING | client | last `epoch:seq` the client processed for a session |

**The epoch counter is the one key here with no lifetime, and that is a decision.** A
client keeps the highest epoch it has seen for a session and drops every event below it,
which is what stops a late event from a previous owner overwriting the state of the
instance running the account now. A counter that expired while nobody held the session
would start again at one on the next acquisition, and an owner still holding eight -- a
paused process, a socket that outlived its lease, a delivery that sat in a queue -- would
then out-rank the live one and be accepted. So a client must never treat a lower epoch as
fresh, whatever the gap, and nothing but the connector deletes this key. An account logged
out, whether it asked to be or WhatsApp imposed it, keeps its counter: the inbox is still
there and the account can be paired again under the same `sid`, so a counter starting over
would have the client discard the pairing itself.

There is exactly one moment the connector knows an account is gone, and it is the teardown
itself. Everything else is a guess, and the guesses are left unclosed: an id a
`session.wake` named and nothing ever paired keeps its counter, so does an account deleted
before this rule existed, and so does one whose `session.delete` was **delivered twice** --
the second delivery is answered from the command record without the teardown running, while
the adoption that answered it has written the counter back. Roughly sixty bytes each.

Reclaiming any of them means telling a deleted account from one waiting to be paired again,
and from this side those are identical: both have no rows at all. The record of a delete
does not settle it either, because it is kept for a day and the same `sid` can be paired
again inside that day -- dropping the counter on the strength of it restarts a live
session's fencing token under a cursor that is already higher, which is a TTL's damage
arriving by another road. The client is the only side that knows which sessions it still
has an inbox for, which is why no sweep is offered here rather than offered with a caveat.

**Four keys left this table rather than being explained in it.** `wa:sessions` and
`wa:session:<sid>` described a registry of session state that was never built, and
`wa:dlq:events` and `wa:dlq:commands` a dead letter queue neither side has ever written;
all four had a key constructor and nothing else. A row for a key nobody writes is worse
than an absent row -- a client vendoring this directory reads that the connector keeps
the last known state of every session, or that an operator can go and look at what
failed, and writes code against either. The registry cost a holdout agent a set of
acceptance criteria built on that premise while #151 was being verified, and the DLQ
would send an operator to a key that is empty whether or not anything failed. A client
that still reads those names in an older vendored copy of this contract should stop: they
are not written, and they were not written then either. Wanting a DLQ is an issue to open, not a
constructor to leave lying around.

`wa:quarantine:<sid>` was in the same state and is not any more: it counts the failures
of a session the connector could not bring back and says how long the fleet leaves it
alone, from a minute up to an hour, doubling. It gates what the connector does on its own,
which is two things: its resume sweep, and a `session.wake` the fleet has already handed
out once. A wake read for the first time is a client asking, and the quarantine does not
stand between a client and what it asked for, which is why no command is ever answered
`quarantined`: a `session.connect` is carried out whatever the backoff says, and so is a
first-read wake, which adopts the account and connects it when the record says it should
be connected (see `session.wake` above). Every copy after that one is this fleet repeating an attempt it already
made, and it waits out the backoff. **A client whose session does not come up should
publish another `session.wake` rather than wait on the one it already sent**, which is the
difference between asking again and being retried. Whether a session registry should exist
at all is a separate question from this table telling clients that one does.

**The one thing that registry was for does exist, and not here.** A connector keeps what
a client asked each session to be -- connected or disconnected -- in its own database,
written by `session.connect` and `session.disconnect` and deleted by `session.logout` and
`session.delete`. It is what makes a paired account survive the instance that was running
it: a lease dies with its holder and a `session.wake` is a frame read once, so without a
record of intent a restarted fleet leaves every account unowned and silent. A sweep reads
it and brings back what nobody is running, taking `wa:resume:<sid>` first so the fleet
spends one attempt per account per window rather than one per instance per pass.

It is deliberately not in Redis and not in this table. Desired state that a client could
write is a client deciding when the connector dials WhatsApp; what the client says is a
command, and this is the connector's record of having been told.

The client reads events with a consumer group named `chatwoot`, created at `0` so that
whatever the connector published while no client was running is still delivered.

## Compatibility

`v` is the major version. Additive changes (new event type, new optional field) do
NOT bump it: consumers must ignore unknown event types and unknown payload fields,
which is why payload objects allow additional properties while frames do not.

Removing an event type that no producer has ever published does not bump it either:
no consumer can have received one, so there is nothing for an older one to lose. That is
how `account.reachout_timelock` and `account.new_chat_cap` left. Removing a type that
something does publish, a command, or an error code is a breaking change.

A connector advertises `protocol{min,max}` in its Redis registry entry and supports
`N` and `N-1`. Clients refuse to talk to a connector whose range does not overlap
theirs, and the connector is always upgraded first.

## Conventions

- Identity is always an `address` (`kind` + bare `id`, no `@server`, no device or
  agent suffix) or a `party` (`phone` and/or `lid` plus display names). Raw JIDs
  never cross the wire.
- Timestamps are epoch milliseconds. A frame's `ts` is when the connector learned the
  thing it reports, not when it managed to write it: an event that spent time in a queue
  is not news from now, and a reader has only this to tell the two apart.
- `chat.presence` describes a moment rather than a state that holds, and the reader is
  what bounds how long it is worth showing: a `composing` or `recording` older than a
  few seconds by its own `ts` should not start an indicator. The connector drops one it
  can see has gone stale before it writes it, but it cannot promise more than that --
  nothing on the write side bounds how long a consumer takes to get there, and an
  indicator started late has nothing coming to clear it, because the `paused` that would
  have was published while the stale one was still on its way. `paused`, and both
  `presence.update` states, are facts that hold until something says otherwise and carry
  no such rule.
- `session.connect` may carry `proxy: {url}`, and a session that does leaves for WhatsApp through that proxy rather than from the connector's own address: the pairing, the running socket, and the uploads and downloads of media to WhatsApp's hosts. The URL uses `http`, `https` or `socks5`, and names a host; anything else, including `socks5h`, is refused with `invalid_payload` before the connector records or dials anything. A proxy whose address is link-local or a cloud metadata service is refused when it is dialled, and the connect fails rather than going out directly; loopback and private addresses are dialled like any other. **Each connect states the whole request**, as it does for `groups` and `calls`: a connect without `proxy`, with `proxy: null` or with an empty `url` asks for the session to go out directly, including on a session that had a proxy. A connect naming a different path than the one a session is on takes its socket down and dials again through the new one, so for a paired session the client sees `session.state` `reconnecting` with `reason: proxy_changed`, then `connecting` and `open`, and no `close`: the session comes back within that connect, without anybody asking again. A session still pairing has no connection to come back to, and its hang-up is the `close` with `reason: disconnect_requested` that a `session.disconnect` publishes; so is the hang-up of a move whose connect was answered as failed before the socket went down, because no redial follows it. A connect naming the same path changes nothing, which is what keeps a periodic reconnect from recycling a healthy socket. The proxy is remembered with the rest of the request and used when the connector brings the account back by itself, and a proxy that stops working keeps the account down rather than letting it go out directly. While a session with a proxy is trying to get its socket up -- `session.state` `reconnecting` after a drop, or `connecting` for a dial the connector goes on retrying, which is where a session resumed with its proxy down sits -- a dial that fails at the proxy (the proxy cannot be reached, or it refuses the tunnel) publishes that same state with `reason: proxy_unreachable`, once per change of cause and not once per attempt, although the retries go on for as long as the outage lasts. A failure past the proxy, a tunnel that opens and carries nothing back from WhatsApp, is not the proxy's and never carries that reason; and once the proxy answers again with the socket still down, the state is published again with `reason: disconnected`, so the proxy is not left named as the cause. A session with no proxy never carries `proxy_unreachable`, and the event says nothing about which proxy or what error: the reason is all there is. A connect naming a proxy that the connector could not record is refused before anything changes, because the account would otherwise leave through the proxy now and directly after the next restart. The URL is treated as a credential: it never appears in a reply, an event or an error message, so a client that needs to show which proxy an inbox uses keeps its own copy.
- `session.connect` may carry `history_sync: true`, and a session that does publishes the conversations the phone sends a linked device as `history.sync` events: the dump it sends when the device pairs (`sync` `bootstrap` and `recent`, and `full` for everything older, which the phone only sends to a device that asked for history when it paired) and each answer to a `history.request` (`on_demand`). Like `groups` and `calls`, each connect states it again and it is remembered with the rest of the request when the connector brings the account back by itself. A session without it still receives the dumps and publishes none of them. Each event is `{kind: "messages", progress, data}`, the envelope every provider's history arrives in, and `data` is one chat's messages (`sync`, `chat`, `name` for a group's subject, `messages`, `exhausted`), oldest first, at most 100 per event, so a longer chat arrives in several; each message is an `inbound_message` as `message.received` carries it, with its `from_me`. Reactions, edits, deletions and votes are not in it, because the phone sends the messages with those already applied. Media in a slice carries no `ref`: nothing is downloaded while a dump is published, and `message.download_media` fetches the file when the client wants it. `exhausted` on a chat's last event means the phone has nothing older for it, or nothing older it will share, and an on-demand answer with no messages is sent as one empty event with `exhausted` so a client stops asking. A dump is written down by the connector before any of it is published and acknowledged to the phone only after every event in it was, because the phone announces a dump once and does not announce it again: a dump that could not be published (Redis unreachable, a lost lease, a restart) is published again, whole, when the connector can, after a wait or on the next connection of the account by whichever instance holds it. A client deduplicates by message id, which it already does for `message.received`. `history.request` needs `before`, the oldest message the client has for the chat, because the phone can only walk back from a message it is shown; one without it is refused with `unsupported`. `count` defaults to 50 and is a hint the phone does not always honour. The request is answered `null` once it went out, and the phone's answer, if any, arrives later as `on_demand` events, for a group as well on a session that did not ask for `groups`, since the client asked for that chat; a phone that is offline never answers. The phone answers with messages only on a device that asked for history when it paired: on one paired without `history_sync`, every answer was measured to come back empty and `exhausted`, so a client that wants to page back a chat asks for history at the pairing. And the phone only pages back through what it held before this device paired: with `before` naming a message that reached the device live, after the pairing, it was measured not to answer at all, while the same chat anchored on a message out of the pairing's dump answered at once, so a client anchors on the oldest message it got from history.
- `session.connect` may carry `calls: {answer: true}`, which asks the connector to carry the voice of 1:1 calls between WhatsApp and the client's browser, the way a WhatsApp Cloud API provider does: the connector stands where Meta stands and the browser is a WebRTC peer. It is optional, and a connect without it changes nothing: `call.offer` keeps the shape it has always had and calls are left ringing or refused as before. Like `groups`, `history_sync` and `auto_reject`, each connect states it again. Every SDP travels as a `string`, the SDP text itself, and the connector does not rewrite what the browser sent. The flow, in both directions:
  - **A call this account receives.** With `calls.answer` on, a `call.offer` for a 1:1 voice call carries `sdp`, the connector's WebRTC offer. A video call, a group call and a session without `calls.answer` get a `call.offer` without it. `calls.auto_reject` wins over `calls.answer`: with both on, the call is refused as it is today and the `call.offer` carries no `sdp`. The client answers with `call.accept {call_id, sdp}`, where `sdp` is the browser's WebRTC answer, and the connector answers on WhatsApp once it has applied it. `call.reject` refuses the call as before.
  - **A call answered by a media server.** `call.accept {call_id, stream: {url}}` answers a received call with a media server in the browser's place, such as a voice agent, and carries no `sdp`. The connector dials the WebSocket at `url` and answers on WhatsApp only once it is open; a stream it cannot reach within 5 seconds fails the command with `invalid_payload` and leaves the call ringing, so it can still be accepted another way. A call offered without `sdp` can be accepted this way. Frames are JSON text, keyed by `event`, and a side ignores fields and events it does not know. The connector sends `start` once dialled, with `call_id`, `direction` (`inbound`), `peer` (the caller's number, or their LID when the number is not known) and `format` (`{encoding: "pcm_s16le", sample_rate: 16000, channels: 1}`); `answered` with `call_id` once the voice is wired, before which nothing the server sends is played; a `media` frame every 60 ms with `payload`, the caller's audio as base64 little-endian PCM in that format, silence included, so a server that hears the end of a turn in silence hears it; and `stop` when the call ends, after which it closes the socket. The server sends `media` frames of any length in the same format, queued to be played in order; `clear` to drop what it sent and was not played yet, when the caller talks over it; and `hangup`, with optional `by` and `reason`, to end the call. A `hangup`, or the socket closing or breaking without one, hangs the call up on WhatsApp, and the `call.terminate` event for it carries `reason` `stream_hangup` or `stream_lost`.
  - **A call the client places.** `call.start {to, sdp}` carries the browser's WebRTC offer and is an RPC whose result is `{call_id}`, the id `call.answered` and `call.terminate` are matched by. It rings somebody's phone, which is not a side effect that repeats harmlessly, so it **requires an `idempotency_key`**: a `call.start` redelivered with the same key answers the same `call_id` and does not ring again. When the callee answers, `call.answered {call_id, sdp}` brings the connector's WebRTC answer for the browser.
  - **The end of a call.** `call.terminate {call_id}` hangs up a call the client answered or placed. The `call.terminate` event, which already reported a call that ended before anybody answered it, also reports the end of a call that was answered or placed, whichever side ended it.
  - **Repeats and late commands.** `call.accept` and `call.terminate` are idempotent by `call_id` and are fire and forget: accepting a call that was already accepted or has ended, or ending one that already ended, does nothing new, and a failure arrives as `command.failed`.
  - **Where this connector stands.** The three commands are answered `unsupported` on a session without `calls.answer`, on one with `calls.auto_reject` (which wins over it), on a session connected with a `proxy`, and on every session of a deployment that did not open a port for call media: there `calls.answer` is accepted and has no effect, so no `call.offer` carries `sdp`. A proxied session is left out because a call's voice travels to WhatsApp over UDP, which the proxy does not carry, and it would leave from the connector's own address. The connector offers the browser G.722 and PCMU, in that order, and answers a browser's offer in whichever of the two it prefers. A call is carried by the instance that owns the session and cannot follow it: when the session moves to another instance or closes, the call is hung up, and the `call.terminate` that reports it may not reach the client. The browser's peer connection closing is then what says the call is over. `call.start` dials a `phone` address only, and is answered `recipient_not_on_whatsapp` for a number WhatsApp does not know. A `call.accept` whose `sdp` answers a call that was offered without one, or is not one the connector can use, fails with `invalid_payload` and the call goes on ringing.
  - **Whether an instance carries calls.** Each instance writes `calls` in its `wa:instance:<inst>` entry on every heartbeat: `"true"` when it opened the UDP socket the voice of calls goes through (`WAC_CALLS_UDP_PORT`), `"false"` otherwise, including on an instance whose engine opens no such socket. The field is always written, never left out, so an instance that comes back under the same name without the port does not keep the `"true"` of the run before it. A client reads it before offering calls, and offers them only when every live instance says `"true"`: a session can move to any instance of the fleet, and one that lands on an instance without the socket has no call voice, so a fleet is meant to be configured the same way on every instance. An entry without the field is an instance older than the field, and carries no calls a client can rely on. The field says what the instance can carry, not what a given session will: a session connected with `proxy`, without `calls.answer` or with `calls.auto_reject` has no call voice on an instance that says `"true"`. It also says nothing about whether the port is reachable from the agents' browsers, which the instance cannot know.
- `presence.set` takes effect when WhatsApp says so, not when the reply comes back: the
  node is written and acknowledged locally, and a `chat.presence` sent in the same breath
  as the `available` before it has been observed not to render on the other phone, while
  later ones in the same session do. What the first one is missing was not pinned down --
  the availability landing and the peer's own subscription to it are not separable from
  outside -- so the rule a client can rely on is only that the first typing indicator of
  a session may not show. An account marks itself available once when its session opens
  and types much later, so this bites only a client that does both at once.
- Neither an account's availability nor its presence subscriptions survive the
  connection they were set on: WhatsApp forgets both when the socket goes, and nothing
  replays them. `session.state: open` is therefore where a client re-establishes what it
  still wants, and that is both commands. The connector reapplies the last
  `presence.set` it carried out as soon as a connection comes up, which closes a window
  a client's own round trip cannot -- while the account is not marked available every
  message it receives is receipted as if nobody were there, and no sender's client
  renders that tick. What it puts back is kept next to the account rather than in the
  session, so an ownership change is covered too: the instance that takes the account
  over reapplies the last `presence.set` without ever having heard the command. Sending
  it again on `session.state: open` is harmless and stays the safe habit -- the
  connector's copy is only as current as the last command it carried out. Subscriptions are
  not reapplied at all: which parties are worth watching is the client's to know, and a
  connector holding that set would either re-subscribe an address book nobody is looking
  at or refuse the one contact somebody has open. Until the client asks again,
  `presence.update` stops arriving and the last state it published stands.
- Outbound message ids are generated by the client (`"3EB0" + 18 hex`, the
  whatsmeow/Baileys shape) so the echo can be matched before the reply arrives.
  Providers that cannot accept a caller-supplied id use `client_ref` instead.
- Media bytes never travel in a frame. Inbound media carries a `media_ref` the
  client fetches over HTTP; outbound media carries a URL the connector fetches.
- `voice_note` on an outbound audio is honoured only for opus in an Ogg container, the
  one format WhatsApp's Android client plays as a voice note: any other format sent with
  the flag plays on WhatsApp Web and fails on Android with "something is wrong with the
  audio file". The connector does not transcode, so a voice note whose type is anything
  else (`audio/mpeg`, `audio/mp4`, `audio/ogg; codecs=vorbis`, `audio/webm`) goes out as
  an ordinary audio file, without the flag and without its `waveform`, and the send
  succeeds. `audio/ogg` with no codec named is read as opus, and so is a voice note nobody
  gave a type to. A client that wants the voice bubble records or converts to opus before
  it sends.
- `video_note` marks a video recorded to play in a circle, WhatsApp's video message. It is
  only ever set on a `video`, and it is left out rather than sent false, so a producer or
  a client that predates it reads every frame the same. Inbound, a client that does not
  know the flag has an ordinary video to render, which is what the file is. Outbound, it
  is refused (`invalid_payload`) on any other kind and with a `caption`, which the circle
  has nowhere to show. The connector does not transcode or crop: the file goes out as it
  was given. Measured on a phone: the
  file WhatsApp recorded, forwarded back, and a 1280x720 video sent with the flag both
  played in the circle, the wider one cropped to it.
- A media message published with no `ref` is followed by `media.download_failed`, and
  `recoverable` on it is what says whether that is the end. False is every reason the
  file is not coming back -- the key lapsed, the bytes did not check out, the file is
  past what the instance keeps -- and the client flags the bubble. True is WhatsApp
  having dropped the file while the sender's phone may still hold it, and it is an
  invitation: `message.download_media` asks the phone to upload it again and answers
  with a fresh `media_ref`. The connector does not ask on its own, because the inbound
  path runs on a node handler it cannot spend somebody's phone waking up. A producer
  that predates the field leaves it out, and absent reads as false, which is the
  behaviour every client already had.
- `message.revoked` carries `message_author` where the deletion's key named one, and it
  is a claim rather than a fact. WhatsApp addresses a message by (id, participant), so
  any member of a group can send a deletion naming somebody who did not write the
  message: the phones apply nothing, and a client matching on the id alone marks the
  bubble deleted while every other member still sees it. Compare the claim against the
  author of the message you resolved, and drop the deletion when the two disagree. The
  check is necessary and not sufficient -- WhatsApp also requires the sender to be that
  author or an admin of the group, and a connector answers neither without keeping every
  message's author or spending a round trip per deletion -- so it closes the case a
  member can exploit rather than the whole rule. A key that says the message is the
  deleter's own names the deleter, whatever participant it also carries, because that is
  how WhatsApp resolves it. Absent means the key named nobody WhatsApp reads, which is a
  one-to-one chat: a key there addresses the message by the conversation rather than by a
  participant, so `sender` and `by` are the whole answer and a participant that turns up
  in one is dropped rather than passed on. A message sent through a broadcast list is
  shown in the direct conversation with whoever sent it and is published there, but its
  key is a list's and carries the field. A `message.revoked` for a
  group always carries the field -- a key with neither a participant nor `from_me` names
  no message, and this connector drops that deletion rather than publishing one no phone
  applied -- so a client can require it there.
- An absent field and an explicit `null` mean the same thing to a client, so a field
  that has to distinguish "there is none" from "this producer does not say" carries
  its own flag. `group_info.has_picture` is the one such field today: a `picture_url`
  of `null` cannot tell a group with no photo from a snapshot that does not mention
  one, and the client needs the difference to clear a photo removed while its session
  was out of the group. A producer that cannot answer leaves it out.
- Errors carry an `error_code`. The enum grows the way everything else here does: a
  consumer that meets a code it does not know treats it as `internal`, which both
  implementations already do -- `protocol.NewError` on the Go side, `Errors.build` on
  the Ruby one -- so a connector answering with a newer code gets exactly the behaviour
  an older client had before that code existed. The Ruby classes are not a 1:1 mapping
  in either direction: some of them (`event_out_of_order`, `message_already_processing`)
  never travel, and they exist to be rescued rather than to be sent.
- Three codes are published and never sent, so a client branching on them writes a branch
  that never runs. `session_not_found` is not answered at all: a command for a session no
  instance owns stays pending and its caller waits out its own deadline. `quarantined` is not
  answered either, and never will be: the backoff behind it paces what the connector does
  on its own, and refusing a client that asks would put it in front of the person fixing
  the account.
  `client_outdated` reaches a client as the `session.client_outdated` event instead, never
  as a reply. They stay in the enum because
  removing one narrows what a client may already match on, and each is marked in
  `internal/protocol/errors.go` with what arrives in its place.
- Two command types have no handler here -- `session.update` and `contact.info` -- and a
  client that sends one is answered `unsupported`. That answer only reaches a client whose
  session some instance owns: a command for a session nobody is running is delivered to
  nobody, so the caller waits out its own deadline instead. Which two is marked in `internal/protocol/types.go` and held
  there by a test, so wiring one up without saying so fails the build.
- Six of the event types have no producer in this connector either, and the same
  reasoning holds: a client may match on one and never see it. Unlike a command, nothing
  says so at the time -- a command it does not implement comes back `unsupported`, while
  an event that is never published is indistinguishable from one that has not happened.
  Which six is marked in `internal/protocol/types.go` and held there by a test, so
  the marking is what the build does rather than what it did when somebody last looked.
  An unproduced type stays only while some producer could emit it one day:
  `account.reachout_timelock` and `account.new_chat_cap` were removed because none can.
  whatsmeow exposes no WhatsApp Business messaging limit, and uazapi, the other provider
  behind this contract, reports its limits through the instance status rather than by
  event.
- A `party` carries both of WhatsApp's namespaces for one person only where this account was in a position to know they are the same person. A LID exists so somebody can take part in a conversation without handing over their number, and which accounts get to see the number behind one is granted per account. So the two halves are linked only where WhatsApp showed this account they belong together: an event that carried both, a group listing that named a participant by each, or the account's own pair. Otherwise a party goes out with the half the event carried, and a client should treat the other as not yet known rather than as absent for good: the next message from the same person usually carries both. A deployment hosting accounts for more than one operator is where this is load-bearing, because the device store's mapping table is shared by all of them.
- Three of the codes are about *who* failed, and the distinction is what an operator
  reads first: `wa_error` is WhatsApp refusing, `provider_unavailable` is a dependency
  the command itself named -- the storage a `message.send` points its `ref.url` at --
  not answering, and `internal` is this connector. All three are worth retrying; only
  the last one means the connector's own logs are where to look.

## RPC results

The `reply` frame carries `result` as an opaque object: the schema does not describe
it per command type, because a result is only ever read by the caller of that one
command. What the two sides agreed on is listed here, and it is what a command answers
when a connector carries it out at all: one that does not implement a command refuses
it with `unsupported` rather than answering a result of the wrong shape. In this
connector that is `contact.info` below, plus `session.update`, which has no result of its
own to list; `call.start` is refused the same way on a session that does not carry calls.

| Command | `result` |
|---|---|
| `session.connect`, `session.status` | `connection_state`, which also carries `reachout_time_lock` and `new_chat_cap` where a connector reports them. This one does not fill either: whatsmeow exposes no WhatsApp Business messaging limit to fill them with |
| `admin.ping` | `{ "inst": string, "version": string, "sessions": integer }` |
| `message.send`, `message.edit`, `message.react` | `{ "message_id": string, "timestamp": timestamp_ms, "client_ref": string\|null }`. `message.react` is refused with `unsupported` on a channel, which names a post by a server id the contract has no field for. A `message.edit` whose `text` names a media message this connector sent corrects its caption: the file goes out again as it was sent, from coordinates the connector keeps for an hour after the send, nothing fetched or uploaded. A voice note, a video note, an audio file or a sticker carries no caption and the edit is refused with `unsupported`; The correction goes to the chat the file was sent to, whichever address the edit names, and an empty `text` removes the caption. A media `message.send` whose coordinates the connector cannot keep fails and puts nothing on the wire, so a redelivery can send it again. A message the connector does not keep -- sent before this was built, from the phone, or longer than the hour ago -- is corrected as the text it names, and when that message is a file WhatsApp ignores the correction and keeps the caption it had, though the edit is acknowledged |
| `message.revoke` | `null`. Refused with `unsupported` on a channel: WhatsApp answers the deletion without an error and leaves the post up, so reporting success would tell the client a post is gone while every follower still sees it |
| `history.request` | `null`. The phone answers later, as `history.sync` events, and may never answer at all: the reply says the request went out, not that history is coming |
| `message.download_media` | `media_ref`, fetchable from `url` until `expires_at`. The connector answers with a `connector_blob`, the same shape its events carry: what it hands back is a blob it just wrote, instance-local and time-bounded like any other |
| `contact.check` | array of `{ "phone": digits, "exists": boolean, "address": address\|null }` |
| `contact.profile_picture` | `{ "url": string\|null }` |
| `contact.resolve` | `party`. Both of WhatsApp's namespaces for one person, out of what the connector already holds, plus the display names it has learned. Local: no round trip, and a session that is paired but not connected still answers it. It answers out of what this account was shown -- see the party rule under Conventions -- so a pairing nothing has shown it is answered with the half the caller already had |
| `contact.info` | `party` |
| `call.start` | `{ "call_id": string }`, the id `call.answered` and `call.terminate` carry for this call. Given once the callee's phone is ringing, not once it is answered |
| `group.create`, `group.info` | `group_info`. `topic_id` is WhatsApp's own id for the description, passed on as it arrives and never interpreted: a group whose description came back with the literal string `undefined` refuses every later edit with a conflict, and this is the only reading that says so. The connector does not turn it into an error code, because a conflict is genuinely ambiguous between a frozen description and another admin writing in between, and what to tell an operator is the client's to decide. `participants` is absent when the connector cannot account for every one of them -- an anonymous participant it has no address for, or a list shorter than `size` -- because a roster reads as the whole of the group and half of one takes people out of it. Absent means *not answered*, never *empty*: `size` is what says how many there are |
| `group.list` | array of `group_info`, empty when the account is in no groups, and **without `participants`**: an account can be in hundreds of groups of hundreds of people, and a listing that carried every membership would answer with the whole address book of every conversation to say which conversations exist. `size` still says how big each one is, and `group.info` answers the roster for the group a caller opens |
| `group.invite.get` | `{ "code": string, "url": string\|null }` |
| `group.participants.update`, `group.join_requests.update` | array of `{ "address": address, "status": "success"\|"failed", "code": error_code\|null }` |
| `group.join_requests.list` | array of `{ "party": party, "requested_at": timestamp_ms }`, empty when nobody is waiting. `requested_at` is `timestamp_ms\|null`, null when the provider did not date the request: a request with no date is still one somebody is waiting on, and a zero reads as January 1970 and sorts as one |
| `group.leave`, `group.name.set`, `group.description.set`, `group.photo.set`, `group.settings.set` | `null` |

A command whose result is `null` still answers `{"ok": true}`: the caller is waiting
for the confirmation, not for data.
