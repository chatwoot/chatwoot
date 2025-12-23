# frozen_string_literal: true
#
# = net/imap.rb
#
# Copyright (C) 2000  Shugo Maeda <shugo@ruby-lang.org>
#
# This library is distributed under the terms of the Ruby license.
# You can freely distribute/modify this library.
#
# Documentation: Shugo Maeda, with RDoc conversion and overview by William
# Webber.
#
# See Net::IMAP for documentation.
#

require "socket"
require "monitor"
require 'net/protocol'
begin
  require "openssl"
rescue LoadError
end

module Net

  # Net::IMAP implements Internet Message Access Protocol (\IMAP) client
  # functionality.  The protocol is described
  # in {IMAP4rev1 [RFC3501]}[https://tools.ietf.org/html/rfc3501]
  # and {IMAP4rev2 [RFC9051]}[https://tools.ietf.org/html/rfc9051].
  #
  # == \IMAP Overview
  #
  # An \IMAP client connects to a server, and then authenticates
  # itself using either #authenticate or #login.  Having
  # authenticated itself, there is a range of commands
  # available to it.  Most work with mailboxes, which may be
  # arranged in an hierarchical namespace, and each of which
  # contains zero or more messages.  How this is implemented on
  # the server is implementation-dependent; on a UNIX server, it
  # will frequently be implemented as files in mailbox format
  # within a hierarchy of directories.
  #
  # To work on the messages within a mailbox, the client must
  # first select that mailbox, using either #select or #examine
  # (for read-only access).  Once the client has successfully
  # selected a mailbox, they enter the +selected+ state, and that
  # mailbox becomes the _current_ mailbox, on which mail-item
  # related commands implicitly operate.
  #
  # === Connection state
  #
  # Once an IMAP connection is established, the connection is in one of four
  # states: <tt>not authenticated</tt>, +authenticated+, +selected+, and
  # +logout+.  Most commands are valid only in certain states.
  #
  # === Sequence numbers and UIDs
  #
  # Messages have two sorts of identifiers: message sequence
  # numbers and UIDs.
  #
  # Message sequence numbers number messages within a mailbox
  # from 1 up to the number of items in the mailbox.  If a new
  # message arrives during a session, it receives a sequence
  # number equal to the new size of the mailbox.  If messages
  # are expunged from the mailbox, remaining messages have their
  # sequence numbers "shuffled down" to fill the gaps.
  #
  # To avoid sequence number race conditions, servers must not expunge messages
  # when no command is in progress, nor when responding to #fetch, #store, or
  # #search.  Expunges _may_ be sent during any other command, including
  # #uid_fetch, #uid_store, and #uid_search.  The #noop and #idle commands are
  # both useful for this side-effect: they allow the server to send all mailbox
  # updates, including expunges.
  #
  # UIDs, on the other hand, are permanently guaranteed not to
  # identify another message within the same mailbox, even if
  # the existing message is deleted.  UIDs are required to
  # be assigned in ascending (but not necessarily sequential)
  # order within a mailbox; this means that if a non-IMAP client
  # rearranges the order of mail items within a mailbox, the
  # UIDs have to be reassigned.  An \IMAP client thus cannot
  # rearrange message orders.
  #
  # === Examples of Usage
  #
  # ==== List sender and subject of all recent messages in the default mailbox
  #
  #   imap = Net::IMAP.new('mail.example.com')
  #   imap.authenticate('PLAIN', 'joe_user', 'joes_password')
  #   imap.examine('INBOX')
  #   imap.search(["RECENT"]).each do |message_id|
  #     envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
  #     puts "#{envelope.from[0].name}: \t#{envelope.subject}"
  #   end
  #
  # ==== Move all messages from April 2003 from "Mail/sent-mail" to "Mail/sent-apr03"
  #
  #   imap = Net::IMAP.new('mail.example.com')
  #   imap.authenticate('PLAIN', 'joe_user', 'joes_password')
  #   imap.select('Mail/sent-mail')
  #   if not imap.list('Mail/', 'sent-apr03')
  #     imap.create('Mail/sent-apr03')
  #   end
  #   imap.search(["BEFORE", "30-Apr-2003", "SINCE", "1-Apr-2003"]).each do |message_id|
  #     imap.copy(message_id, "Mail/sent-apr03")
  #     imap.store(message_id, "+FLAGS", [:Deleted])
  #   end
  #   imap.expunge
  #
  # == Capabilities
  #
  # Most Net::IMAP methods do not _currently_ modify their behaviour according
  # to the server's advertised #capabilities.  Users of this class must check
  # that the server is capable of extension commands or command arguments before
  # sending them.  Special care should be taken to follow the #capabilities
  # requirements for #starttls, #login, and #authenticate.
  #
  # See #capable?, #auth_capable?, #capabilities, #auth_mechanisms to discover
  # server capabilities.  For relevant capability requirements, see the
  # documentation on each \IMAP command.
  #
  #   imap = Net::IMAP.new("mail.example.com")
  #   imap.capable?(:IMAP4rev1) or raise "Not an IMAP4rev1 server"
  #   imap.capable?(:starttls)  or raise "Cannot start TLS"
  #   imap.starttls
  #
  #   if imap.auth_capable?("PLAIN")
  #     imap.authenticate "PLAIN", username, password
  #   elsif !imap.capability?("LOGINDISABLED")
  #     imap.login username, password
  #   else
  #     raise "No acceptable authentication mechanisms"
  #   end
  #
  #   # Support for "UTF8=ACCEPT" implies support for "ENABLE"
  #   imap.enable :utf8 if imap.capable?("UTF8=ACCEPT")
  #
  #   namespaces  = imap.namespace if imap.capable?(:namespace)
  #   mbox_prefix = namespaces&.personal&.first&.prefix || ""
  #   mbox_delim  = namespaces&.personal&.first&.delim  || "/"
  #   mbox_path   = prefix + %w[path to my mailbox].join(delim)
  #   imap.create mbox_path
  #
  # === Basic IMAP4rev1 capabilities
  #
  # IMAP4rev1 servers must advertise +IMAP4rev1+ in their capabilities list.
  # IMAP4rev1 servers must _implement_ the +STARTTLS+, <tt>AUTH=PLAIN</tt>,
  # and +LOGINDISABLED+ capabilities.  See #starttls, #login, and #authenticate
  # for the implications of these capabilities.
  #
  # === Caching +CAPABILITY+ responses
  #
  # Net::IMAP automatically stores and discards capability data according to the
  # the requirements and recommendations in
  # {IMAP4rev2 §6.1.1}[https://www.rfc-editor.org/rfc/rfc9051#section-6.1.1],
  # {§6.2}[https://www.rfc-editor.org/rfc/rfc9051#section-6.2], and
  # {§7.1}[https://www.rfc-editor.org/rfc/rfc9051#section-7.1].
  # Use #capable?, #auth_capable?, or #capabilities to use this cache and avoid
  # sending the #capability command unnecessarily.
  #
  # The server may advertise its initial capabilities using the +CAPABILITY+
  # ResponseCode in a +PREAUTH+ or +OK+ #greeting.  When TLS has started
  # (#starttls) and after authentication (#login or #authenticate), the server's
  # capabilities may change and cached capabilities are discarded.  The server
  # may send updated capabilities with an +OK+ TaggedResponse to #login or
  # #authenticate, and these will be cached by Net::IMAP.  But the
  # TaggedResponse to #starttls MUST be ignored--it is sent before TLS starts
  # and is unprotected.
  #
  # When storing capability values to variables, be careful that they are
  # discarded or reset appropriately, especially following #starttls.
  #
  # === Using IMAP4rev1 extensions
  #
  # See the {IANA IMAP4 capabilities
  # registry}[http://www.iana.org/assignments/imap4-capabilities] for a list of
  # all standard capabilities, and their reference RFCs.
  #
  # IMAP4rev1 servers must not activate behavior that is incompatible with the
  # base specification until an explicit client action invokes a capability,
  # e.g. sending a command or command argument specific to that capability.
  # Servers may send data with backward compatible behavior, such as response
  # codes or mailbox attributes, at any time without client action.
  #
  # Invoking capabilities which are unknown to Net::IMAP may cause unexpected
  # behavior and errors.  For example, ResponseParseError is raised when
  # unknown response syntax is received.  Invoking commands or command
  # parameters that are unsupported by the server may raise NoResponseError,
  # BadResponseError, or cause other unexpected behavior.
  #
  # Some capabilities must be explicitly activated using the #enable command.
  # See #enable for details.
  #
  # == Thread Safety
  #
  # Net::IMAP supports concurrent threads. For example,
  #
  #   imap = Net::IMAP.new("imap.foo.net", "imap2")
  #   imap.authenticate("scram-md5", "bar", "password")
  #   imap.select("inbox")
  #   fetch_thread = Thread.start { imap.fetch(1..-1, "UID") }
  #   search_result = imap.search(["BODY", "hello"])
  #   fetch_result = fetch_thread.value
  #   imap.disconnect
  #
  # This script invokes the FETCH command and the SEARCH command concurrently.
  #
  # When running multiple commands, care must be taken to avoid ambiguity.  For
  # example, SEARCH responses are ambiguous about which command they are
  # responding to, so search commands should not run simultaneously, unless the
  # server supports +ESEARCH+ {[RFC4731]}[https://rfc-editor.org/rfc/rfc4731] or
  # IMAP4rev2[https://www.rfc-editor.org/rfc/rfc9051].  See {RFC9051
  # §5.5}[https://www.rfc-editor.org/rfc/rfc9051.html#section-5.5] for
  # other examples of command sequences which should not be pipelined.
  #
  # == Unbounded memory use
  #
  # Net::IMAP reads server responses in a separate receiver thread per client.
  # Unhandled response data is saved to #responses, and response_handlers run
  # inside the receiver thread.  See the list of methods for {handling server
  # responses}[rdoc-ref:Net::IMAP@Handling+server+responses], below.
  #
  # Because the receiver thread continuously reads and saves new responses, some
  # scenarios must be careful to avoid unbounded memory use:
  #
  # * Commands such as #list or #fetch can have an enormous number of responses.
  # * Commands such as #fetch can result in an enormous size per response.
  # * Long-lived connections will gradually accumulate unsolicited server
  #   responses, especially +EXISTS+, +FETCH+, and +EXPUNGE+ responses.
  # * A buggy or untrusted server could send inappropriate responses, which
  #   could be very numerous, very large, and very rapid.
  #
  # Use paginated or limited versions of commands whenever possible.
  #
  # Use Config#max_response_size to impose a limit on incoming server responses
  # as they are being read.  <em>This is especially important for untrusted
  # servers.</em>
  #
  # Use #add_response_handler to handle responses after each one is received.
  # Use the +response_handlers+ argument to ::new to assign response handlers
  # before the receiver thread is started.  Use #extract_responses,
  # #clear_responses, or #responses (with a block) to prune responses.
  #
  # == Errors
  #
  # An \IMAP server can send three different types of responses to indicate
  # failure:
  #
  # NO:: the attempted command could not be successfully completed.  For
  #      instance, the username/password used for logging in are incorrect;
  #      the selected mailbox does not exist; etc.
  #
  # BAD:: the request from the client does not follow the server's
  #       understanding of the \IMAP protocol.  This includes attempting
  #       commands from the wrong client state; for instance, attempting
  #       to perform a SEARCH command without having SELECTed a current
  #       mailbox.  It can also signal an internal server
  #       failure (such as a disk crash) has occurred.
  #
  # BYE:: the server is saying goodbye.  This can be part of a normal
  #       logout sequence, and can be used as part of a login sequence
  #       to indicate that the server is (for some reason) unwilling
  #       to accept your connection.  As a response to any other command,
  #       it indicates either that the server is shutting down, or that
  #       the server is timing out the client connection due to inactivity.
  #
  # These three error response are represented by the errors
  # Net::IMAP::NoResponseError, Net::IMAP::BadResponseError, and
  # Net::IMAP::ByeResponseError, all of which are subclasses of
  # Net::IMAP::ResponseError.  Essentially, all methods that involve
  # sending a request to the server can generate one of these errors.
  # Only the most pertinent instances have been documented below.
  #
  # Because the IMAP class uses Sockets for communication, its methods
  # are also susceptible to the various errors that can occur when
  # working with sockets.  These are generally represented as
  # Errno errors.  For instance, any method that involves sending a
  # request to the server and/or receiving a response from it could
  # raise an Errno::EPIPE error if the network connection unexpectedly
  # goes down.  See the socket(7), ip(7), tcp(7), socket(2), connect(2),
  # and associated man pages.
  #
  # Finally, a Net::IMAP::DataFormatError is thrown if low-level data
  # is found to be in an incorrect format (for instance, when converting
  # between UTF-8 and UTF-16), and Net::IMAP::ResponseParseError is
  # thrown if a server response is non-parseable.
  #
  # == What's here?
  #
  # * {Connection control}[rdoc-ref:Net::IMAP@Connection+control+methods]
  # * {Server capabilities}[rdoc-ref:Net::IMAP@Server+capabilities]
  # * {Handling server responses}[rdoc-ref:Net::IMAP@Handling+server+responses]
  # * {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands]
  #   * {for any state}[rdoc-ref:Net::IMAP@Any+state]
  #   * {for the "not authenticated" state}[rdoc-ref:Net::IMAP@Not+Authenticated+state]
  #   * {for the "authenticated" state}[rdoc-ref:Net::IMAP@Authenticated+state]
  #   * {for the "selected" state}[rdoc-ref:Net::IMAP@Selected+state]
  #   * {for the "logout" state}[rdoc-ref:Net::IMAP@Logout+state]
  # * {IMAP extension support}[rdoc-ref:Net::IMAP@IMAP+extension+support]
  #
  # === Connection control methods
  #
  # - Net::IMAP.new: Creates a new \IMAP client which connects immediately and
  #   waits for a successful server greeting before the method returns.
  # - #connection_state: Returns the connection state.
  # - #starttls: Asks the server to upgrade a clear-text connection to use TLS.
  # - #logout: Tells the server to end the session.  Enters the +logout+ state.
  # - #disconnect: Disconnects the connection (without sending #logout first).
  # - #disconnected?: True if the connection has been closed.
  #
  # === Server capabilities
  #
  # - #capable?: Returns whether the server supports a given capability.
  # - #capabilities: Returns the server's capabilities as an array of strings.
  # - #auth_capable?: Returns whether the server advertises support for a given
  #   SASL mechanism, for use with #authenticate.
  # - #auth_mechanisms: Returns the #authenticate SASL mechanisms which
  #   the server claims to support as an array of strings.
  # - #clear_cached_capabilities: Clears cached capabilities.
  #
  #   <em>The capabilities cache is automatically cleared after completing
  #   #starttls, #login, or #authenticate.</em>
  # - #capability: Sends the +CAPABILITY+ command and returns the #capabilities.
  #
  #   <em>In general, #capable? should be used rather than explicitly sending a
  #   +CAPABILITY+ command to the server.</em>
  #
  # === Handling server responses
  #
  # - #greeting: The server's initial untagged response, which can indicate a
  #   pre-authenticated connection.
  # - #responses: Yields unhandled UntaggedResponse#data and <em>non-+nil+</em>
  #   ResponseCode#data.
  # - #extract_responses: Removes and returns the responses for which the block
  #   returns a true value.
  # - #clear_responses: Deletes unhandled data from #responses and returns it.
  # - #add_response_handler: Add a block to be called inside the receiver thread
  #   with every server response.
  # - #response_handlers: Returns the list of response handlers.
  # - #remove_response_handler: Remove a previously added response handler.
  #
  # === Core \IMAP commands
  #
  # The following commands are defined either by
  # the [IMAP4rev1[https://tools.ietf.org/html/rfc3501]] base specification, or
  # by one of the following extensions:
  # [IDLE[https://tools.ietf.org/html/rfc2177]],
  # [NAMESPACE[https://tools.ietf.org/html/rfc2342]],
  # [UNSELECT[https://tools.ietf.org/html/rfc3691]],
  # [ENABLE[https://tools.ietf.org/html/rfc5161]],
  # [MOVE[https://tools.ietf.org/html/rfc6851]].
  # These extensions are widely supported by modern IMAP4rev1 servers and have
  # all been integrated into [IMAP4rev2[https://tools.ietf.org/html/rfc9051]].
  # <em>*NOTE:* Net::IMAP doesn't support IMAP4rev2 yet.</em>
  #
  # ==== Any state
  #
  # - #capability: Returns the server's capabilities as an array of strings.
  #
  #   <em>In general, #capable? should be used rather than explicitly sending a
  #   +CAPABILITY+ command to the server.</em>
  # - #noop: Allows the server to send unsolicited untagged #responses.
  # - #logout: Tells the server to end the session. Enters the +logout+ state.
  #
  # ==== Not Authenticated state
  #
  # In addition to the commands for any state, the following commands are valid
  # in the +not_authenticated+ state:
  #
  # - #starttls: Upgrades a clear-text connection to use TLS.
  #
  #   <em>Requires the +STARTTLS+ capability.</em>
  # - #authenticate: Identifies the client to the server using the given
  #   {SASL mechanism}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
  #   and credentials.  Enters the +authenticated+ state.
  #
  #   <em>The server should list <tt>"AUTH=#{mechanism}"</tt> capabilities for
  #   supported mechanisms.</em>
  # - #login: Identifies the client to the server using a plain text password.
  #   Using #authenticate is preferred.  Enters the +authenticated+ state.
  #
  #   <em>The +LOGINDISABLED+ capability</em> <b>must NOT</b> <em>be listed.</em>
  #
  # ==== Authenticated state
  #
  # In addition to the commands for any state, the following commands are valid
  # in the +authenticated+ state:
  #
  # - #enable: Enables backwards incompatible server extensions.
  #   <em>Requires the +ENABLE+ or +IMAP4rev2+ capability.</em>
  # - #select:  Open a mailbox and enter the +selected+ state.
  # - #examine: Open a mailbox read-only, and enter the +selected+ state.
  # - #create: Creates a new mailbox.
  # - #delete: Permanently remove a mailbox.
  # - #rename: Change the name of a mailbox.
  # - #subscribe: Adds a mailbox to the "subscribed" set.
  # - #unsubscribe: Removes a mailbox from the "subscribed" set.
  # - #list: Returns names and attributes of mailboxes matching a given pattern.
  # - #namespace: Returns mailbox namespaces, with path prefixes and delimiters.
  #   <em>Requires the +NAMESPACE+ or +IMAP4rev2+ capability.</em>
  # - #status: Returns mailbox information, e.g. message count, unseen message
  #   count, +UIDVALIDITY+ and +UIDNEXT+.
  # - #append: Appends a message to the end of a mailbox.
  # - #idle: Allows the server to send updates to the client, without the client
  #   needing to poll using #noop.
  #   <em>Requires the +IDLE+ or +IMAP4rev2+ capability.</em>
  # - *Obsolete* #lsub: <em>Replaced by <tt>LIST-EXTENDED</tt> and removed from
  #   +IMAP4rev2+.</em>  Lists mailboxes in the "subscribed" set.
  #
  #   <em>*Note:* Net::IMAP hasn't implemented <tt>LIST-EXTENDED</tt> yet.</em>
  #
  # ==== Selected state
  #
  # In addition to the commands for any state and the +authenticated+
  # commands, the following commands are valid in the +selected+ state:
  #
  # - #close: Closes the mailbox and returns to the +authenticated+ state,
  #   expunging deleted messages, unless the mailbox was opened as read-only.
  # - #unselect: Closes the mailbox and returns to the +authenticated+ state,
  #   without expunging any messages.
  #   <em>Requires the +UNSELECT+ or +IMAP4rev2+ capability.</em>
  # - #expunge: Permanently removes messages which have the Deleted flag set.
  # - #uid_expunge: Restricts expunge to only remove the specified UIDs.
  #   <em>Requires the +UIDPLUS+ or +IMAP4rev2+ capability.</em>
  # - #search, #uid_search: Returns sequence numbers or UIDs of messages that
  #   match the given searching criteria.
  # - #fetch, #uid_fetch: Returns data associated with a set of messages,
  #   specified by sequence number or UID.
  # - #store, #uid_store: Alters a message's flags.
  # - #copy, #uid_copy: Copies the specified messages to the end of the
  #   specified destination mailbox.
  # - #move, #uid_move: Moves the specified messages to the end of the
  #   specified destination mailbox, expunging them from the current mailbox.
  #   <em>Requires the +MOVE+ or +IMAP4rev2+ capability.</em>
  # - #check: <em>*Obsolete:* removed from +IMAP4rev2+.</em>
  #   Can be replaced with #noop or #idle.
  #
  # ==== Logout state
  #
  # No \IMAP commands are valid in the +logout+ state.  If the socket is still
  # open, Net::IMAP will close it after receiving server confirmation.
  # Exceptions will be raised by \IMAP commands that have already started and
  # are waiting for a response, as well as any that are called after logout.
  #
  # === \IMAP extension support
  #
  # ==== RFC9051: +IMAP4rev2+
  #
  # Although IMAP4rev2[https://tools.ietf.org/html/rfc9051] is not supported
  # yet, Net::IMAP supports several extensions that have been folded into it:
  # +ENABLE+, +IDLE+, +MOVE+, +NAMESPACE+, +SASL-IR+, +UIDPLUS+, +UNSELECT+,
  # <tt>STATUS=SIZE</tt>, and the fetch side of +BINARY+.
  # Commands for these extensions are listed with the {Core IMAP
  # commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands], above.
  #
  # >>>
  #   <em>The following are folded into +IMAP4rev2+ but are currently
  #   unsupported or incompletely supported by</em> Net::IMAP<em>: RFC4466
  #   extensions, +ESEARCH+, +SEARCHRES+, +LIST-EXTENDED+, +LIST-STATUS+,
  #   +LITERAL-+, and +SPECIAL-USE+.</em>
  #
  # ==== RFC2087: +QUOTA+
  # - #getquota: returns the resource usage and limits for a quota root
  # - #getquotaroot: returns the list of quota roots for a mailbox, as well as
  #   their resource usage and limits.
  # - #setquota: sets the resource limits for a given quota root.
  #
  # ==== RFC2177: +IDLE+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051] and also included
  # above with {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands].
  # - #idle: Allows the server to send updates to the client, without the client
  #   needing to poll using #noop.
  #
  # ==== RFC2342: +NAMESPACE+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051] and also included
  # above with {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands].
  # - #namespace: Returns mailbox namespaces, with path prefixes and delimiters.
  #
  # ==== RFC2971: +ID+
  # - #id: exchanges client and server implementation information.
  #
  # ==== RFC3516: +BINARY+
  # The fetch side of +BINARY+ has been folded into
  # IMAP4rev2[https://tools.ietf.org/html/rfc9051].
  # - Updates #fetch and #uid_fetch with the +BINARY+, +BINARY.PEEK+, and
  #   +BINARY.SIZE+ items.  See FetchData#binary and FetchData#binary_size.
  #
  # >>>
  #   *NOTE:* The binary extension the #append command is _not_ supported yet.
  #
  # ==== RFC3691: +UNSELECT+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051] and also included
  # above with {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands].
  # - #unselect: Closes the mailbox and returns to the +authenticated+ state,
  #   without expunging any messages.
  #
  # ==== RFC4314: +ACL+
  # - #getacl: lists the authenticated user's access rights to a mailbox.
  # - #setacl: sets the access rights for a user on a mailbox
  # >>>
  #   *NOTE:* +DELETEACL+, +LISTRIGHTS+, and +MYRIGHTS+ are not supported yet.
  #
  # ==== RFC4315: +UIDPLUS+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051] and also included
  # above with {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands].
  # - #uid_expunge: Restricts #expunge to only remove the specified UIDs.
  # - Updates #select, #examine with the +UIDNOTSTICKY+ ResponseCode
  # - Updates #append with the +APPENDUID+ ResponseCode
  # - Updates #copy, #move with the +COPYUID+ ResponseCode
  #
  # ==== RFC4959: +SASL-IR+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051].
  # - Updates #authenticate with the option to send an initial response.
  #
  # ==== RFC5161: +ENABLE+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051] and also included
  # above with {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands].
  # - #enable: Enables backwards incompatible server extensions.
  #
  # ==== RFC5256: +SORT+
  # - #sort, #uid_sort: An alternate version of #search or #uid_search which
  #   sorts the results by specified keys.
  # ==== RFC5256: +THREAD+
  # - #thread, #uid_thread: An alternate version of #search or #uid_search,
  #   which arranges the results into ordered groups or threads according to a
  #   chosen algorithm.
  #
  # ==== +X-GM-EXT-1+
  # +X-GM-EXT-1+ is a non-standard Gmail extension.  See {Google's
  # documentation}[https://developers.google.com/gmail/imap/imap-extensions].
  # - Updates #fetch and #uid_fetch with support for +X-GM-MSGID+ (unique
  #   message ID), +X-GM-THRID+ (thread ID), and +X-GM-LABELS+ (Gmail labels).
  # - Updates #search with the +X-GM-RAW+ search attribute.
  # - #xlist: replaced by +SPECIAL-USE+ attributes in #list responses.
  #
  # *NOTE:* The +OBJECTID+ extension should replace +X-GM-MSGID+ and
  # +X-GM-THRID+, but Gmail does not support it (as of 2023-11-10).
  #
  # ==== RFC6851: +MOVE+
  # Folded into IMAP4rev2[https://tools.ietf.org/html/rfc9051] and also included
  # above with {Core IMAP commands}[rdoc-ref:Net::IMAP@Core+IMAP+commands].
  # - #move, #uid_move: Moves the specified messages to the end of the
  #   specified destination mailbox, expunging them from the current mailbox.
  #
  # ==== RFC6855: <tt>UTF8=ACCEPT</tt>, <tt>UTF8=ONLY</tt>
  #
  # - See #enable for information about support for UTF-8 string encoding.
  #
  # ==== RFC7162: +CONDSTORE+
  #
  # - Updates #enable with +CONDSTORE+ parameter.  +CONDSTORE+ will also be
  #   enabled by using any of the extension's command parameters, listed below.
  # - Updates #status with the +HIGHESTMODSEQ+ status attribute.
  # - Updates #select and #examine with the +condstore+ modifier, and adds
  #   either a +HIGHESTMODSEQ+ or +NOMODSEQ+ ResponseCode to the responses.
  # - Updates #search, #uid_search, #sort, and #uid_sort with the +MODSEQ+
  #   search criterion, and adds SearchResult#modseq to the search response.
  # - Updates #thread and #uid_thread with the +MODSEQ+ search criterion
  #   <em>(but thread responses are unchanged)</em>.
  # - Updates #fetch and #uid_fetch with the +changedsince+ modifier and
  #   +MODSEQ+ FetchData attribute.
  # - Updates #store and #uid_store with the +unchangedsince+ modifier and adds
  #   the +MODIFIED+ ResponseCode to the tagged response.
  #
  # ==== RFC8438: <tt>STATUS=SIZE</tt>
  # - Updates #status with the +SIZE+ status attribute.
  #
  # ==== RFC8474: +OBJECTID+
  # - Adds +MAILBOXID+ ResponseCode to #create tagged response.
  # - Adds +MAILBOXID+ ResponseCode to #select and #examine untagged response.
  # - Updates #fetch and #uid_fetch with the +EMAILID+ and +THREADID+ items.
  #   See FetchData#emailid and FetchData#emailid.
  # - Updates #status with support for the +MAILBOXID+ status attribute.
  #
  # == References
  #
  # [{IMAP4rev1}[https://www.rfc-editor.org/rfc/rfc3501.html]]::
  #   Crispin, M., "INTERNET MESSAGE ACCESS PROTOCOL - \VERSION 4rev1",
  #   RFC 3501, DOI 10.17487/RFC3501, March 2003,
  #   <https://www.rfc-editor.org/info/rfc3501>.
  #
  # [IMAP-ABNF-EXT[https://www.rfc-editor.org/rfc/rfc4466.html]]::
  #   Melnikov, A. and C. Daboo, "Collected Extensions to IMAP4 ABNF",
  #   RFC 4466, DOI 10.17487/RFC4466, April 2006,
  #   <https://www.rfc-editor.org/info/rfc4466>.
  #
  #   <em>Note: Net::IMAP cannot parse the entire RFC4466 grammar yet.</em>
  #
  # [{IMAP4rev2}[https://www.rfc-editor.org/rfc/rfc9051.html]]::
  #   Melnikov, A., Ed., and B. Leiba, Ed., "Internet Message Access Protocol
  #   (\IMAP) - Version 4rev2", RFC 9051, DOI 10.17487/RFC9051, August 2021,
  #   <https://www.rfc-editor.org/info/rfc9051>.
  #
  #   <em>Note: Net::IMAP is not fully compatible with IMAP4rev2 yet.</em>
  #
  # [IMAP-IMPLEMENTATION[https://www.rfc-editor.org/info/rfc2683]]::
  #   Leiba, B., "IMAP4 Implementation Recommendations",
  #   RFC 2683, DOI 10.17487/RFC2683, September 1999,
  #   <https://www.rfc-editor.org/info/rfc2683>.
  #
  # [IMAP-MULTIACCESS[https://www.rfc-editor.org/info/rfc2180]]::
  #   Gahrns, M., "IMAP4 Multi-Accessed Mailbox Practice", RFC 2180, DOI
  #   10.17487/RFC2180, July 1997, <https://www.rfc-editor.org/info/rfc2180>.
  #
  # [UTF7[https://tools.ietf.org/html/rfc2152]]::
  #   Goldsmith, D. and M. Davis, "UTF-7 A Mail-Safe Transformation Format of
  #   Unicode", RFC 2152, DOI 10.17487/RFC2152, May 1997,
  #   <https://www.rfc-editor.org/info/rfc2152>.
  #
  # === Message envelope and body structure
  #
  # [RFC5322[https://tools.ietf.org/html/rfc5322]]::
  #   Resnick, P., Ed., "Internet Message Format",
  #   RFC 5322, DOI 10.17487/RFC5322, October 2008,
  #   <https://www.rfc-editor.org/info/rfc5322>.
  #
  #   <em>Note: obsoletes</em>
  #   RFC-2822[https://tools.ietf.org/html/rfc2822]<em> (April 2001) and</em>
  #   RFC-822[https://tools.ietf.org/html/rfc822]<em> (August 1982).</em>
  #
  # [CHARSET[https://tools.ietf.org/html/rfc2978]]::
  #   Freed, N. and J. Postel, "IANA Charset Registration Procedures", BCP 19,
  #   RFC 2978, DOI 10.17487/RFC2978, October 2000,
  #   <https://www.rfc-editor.org/info/rfc2978>.
  #
  # [DISPOSITION[https://tools.ietf.org/html/rfc2183]]::
  #    Troost, R., Dorner, S., and K. Moore, Ed., "Communicating Presentation
  #    Information in Internet Messages: The Content-Disposition Header
  #    Field", RFC 2183, DOI 10.17487/RFC2183, August 1997,
  #    <https://www.rfc-editor.org/info/rfc2183>.
  #
  # [MIME-IMB[https://tools.ietf.org/html/rfc2045]]::
  #    Freed, N. and N. Borenstein, "Multipurpose Internet Mail Extensions
  #    (MIME) Part One: Format of Internet Message Bodies",
  #    RFC 2045, DOI 10.17487/RFC2045, November 1996,
  #    <https://www.rfc-editor.org/info/rfc2045>.
  #
  # [MIME-IMT[https://tools.ietf.org/html/rfc2046]]::
  #    Freed, N. and N. Borenstein, "Multipurpose Internet Mail Extensions
  #    (MIME) Part Two: Media Types", RFC 2046, DOI 10.17487/RFC2046,
  #    November 1996, <https://www.rfc-editor.org/info/rfc2046>.
  #
  # [MIME-HDRS[https://tools.ietf.org/html/rfc2047]]::
  #    Moore, K., "MIME (Multipurpose Internet Mail Extensions) Part Three:
  #    Message Header Extensions for Non-ASCII Text",
  #    RFC 2047, DOI 10.17487/RFC2047, November 1996,
  #    <https://www.rfc-editor.org/info/rfc2047>.
  #
  # [RFC2231[https://tools.ietf.org/html/rfc2231]]::
  #    Freed, N. and K. Moore, "MIME Parameter Value and Encoded Word
  #    Extensions: Character Sets, Languages, and Continuations",
  #    RFC 2231, DOI 10.17487/RFC2231, November 1997,
  #    <https://www.rfc-editor.org/info/rfc2231>.
  #
  # [I18n-HDRS[https://tools.ietf.org/html/rfc6532]]::
  #    Yang, A., Steele, S., and N. Freed, "Internationalized Email Headers",
  #    RFC 6532, DOI 10.17487/RFC6532, February 2012,
  #    <https://www.rfc-editor.org/info/rfc6532>.
  #
  # [LANGUAGE-TAGS[https://www.rfc-editor.org/info/rfc3282]]::
  #    Alvestrand, H., "Content Language Headers",
  #    RFC 3282, DOI 10.17487/RFC3282, May 2002,
  #    <https://www.rfc-editor.org/info/rfc3282>.
  #
  # [LOCATION[https://www.rfc-editor.org/info/rfc2557]]::
  #    Palme, J., Hopmann, A., and N. Shelness, "MIME Encapsulation of
  #    Aggregate Documents, such as HTML (MHTML)",
  #    RFC 2557, DOI 10.17487/RFC2557, March 1999,
  #    <https://www.rfc-editor.org/info/rfc2557>.
  #
  # [MD5[https://tools.ietf.org/html/rfc1864]]::
  #    Myers, J. and M. Rose, "The Content-MD5 Header Field",
  #    RFC 1864, DOI 10.17487/RFC1864, October 1995,
  #    <https://www.rfc-editor.org/info/rfc1864>.
  #
  # [RFC3503[https://tools.ietf.org/html/rfc3503]]::
  #    Melnikov, A., "Message Disposition Notification (MDN)
  #    profile for Internet Message Access Protocol (IMAP)",
  #    RFC 3503, DOI 10.17487/RFC3503, March 2003,
  #    <https://www.rfc-editor.org/info/rfc3503>.
  #
  # === \IMAP Extensions
  #
  # [QUOTA[https://tools.ietf.org/html/rfc9208]]::
  #   Melnikov, A., "IMAP QUOTA Extension", RFC 9208, DOI 10.17487/RFC9208,
  #   March 2022, <https://www.rfc-editor.org/info/rfc9208>.
  #
  #   <em>Note: obsoletes</em>
  #   RFC-2087[https://tools.ietf.org/html/rfc2087]<em> (January 1997)</em>.
  #   <em>Net::IMAP does not fully support the RFC9208 updates yet.</em>
  # [IDLE[https://tools.ietf.org/html/rfc2177]]::
  #   Leiba, B., "IMAP4 IDLE command", RFC 2177, DOI 10.17487/RFC2177,
  #   June 1997, <https://www.rfc-editor.org/info/rfc2177>.
  # [NAMESPACE[https://tools.ietf.org/html/rfc2342]]::
  #   Gahrns, M. and C. Newman, "IMAP4 Namespace", RFC 2342,
  #   DOI 10.17487/RFC2342, May 1998, <https://www.rfc-editor.org/info/rfc2342>.
  # [ID[https://tools.ietf.org/html/rfc2971]]::
  #   Showalter, T., "IMAP4 ID extension", RFC 2971, DOI 10.17487/RFC2971,
  #   October 2000, <https://www.rfc-editor.org/info/rfc2971>.
  # [BINARY[https://tools.ietf.org/html/rfc3516]]::
  #   Nerenberg, L., "IMAP4 Binary Content Extension", RFC 3516,
  #   DOI 10.17487/RFC3516, April 2003,
  #   <https://www.rfc-editor.org/info/rfc3516>.
  # [ACL[https://tools.ietf.org/html/rfc4314]]::
  #   Melnikov, A., "IMAP4 Access Control List (ACL) Extension", RFC 4314,
  #   DOI 10.17487/RFC4314, December 2005,
  #   <https://www.rfc-editor.org/info/rfc4314>.
  # [UIDPLUS[https://www.rfc-editor.org/rfc/rfc4315.html]]::
  #   Crispin, M., "Internet Message Access Protocol (\IMAP) - UIDPLUS
  #   extension", RFC 4315, DOI 10.17487/RFC4315, December 2005,
  #   <https://www.rfc-editor.org/info/rfc4315>.
  # [SORT[https://tools.ietf.org/html/rfc5256]]::
  #   Crispin, M. and K. Murchison, "Internet Message Access Protocol - SORT and
  #   THREAD Extensions", RFC 5256, DOI 10.17487/RFC5256, June 2008,
  #   <https://www.rfc-editor.org/info/rfc5256>.
  # [THREAD[https://tools.ietf.org/html/rfc5256]]::
  #   Crispin, M. and K. Murchison, "Internet Message Access Protocol - SORT and
  #   THREAD Extensions", RFC 5256, DOI 10.17487/RFC5256, June 2008,
  #   <https://www.rfc-editor.org/info/rfc5256>.
  # [RFC5530[https://www.rfc-editor.org/rfc/rfc5530.html]]::
  #   Gulbrandsen, A., "IMAP Response Codes", RFC 5530, DOI 10.17487/RFC5530,
  #   May 2009, <https://www.rfc-editor.org/info/rfc5530>.
  # [MOVE[https://tools.ietf.org/html/rfc6851]]::
  #   Gulbrandsen, A. and N. Freed, Ed., "Internet Message Access Protocol
  #   (\IMAP) - MOVE Extension", RFC 6851, DOI 10.17487/RFC6851, January 2013,
  #   <https://www.rfc-editor.org/info/rfc6851>.
  # [UTF8=ACCEPT[https://tools.ietf.org/html/rfc6855]]::
  # [UTF8=ONLY[https://tools.ietf.org/html/rfc6855]]::
  #   Resnick, P., Ed., Newman, C., Ed., and S. Shen, Ed.,
  #   "IMAP Support for UTF-8", RFC 6855, DOI 10.17487/RFC6855, March 2013,
  #   <https://www.rfc-editor.org/info/rfc6855>.
  # [CONDSTORE[https://tools.ietf.org/html/rfc7162]]::
  # [QRESYNC[https://tools.ietf.org/html/rfc7162]]::
  #   Melnikov, A. and D. Cridland, "IMAP Extensions: Quick Flag Changes
  #   Resynchronization (CONDSTORE) and Quick Mailbox Resynchronization
  #   (QRESYNC)", RFC 7162, DOI 10.17487/RFC7162, May 2014,
  #   <https://www.rfc-editor.org/info/rfc7162>.
  # [OBJECTID[https://tools.ietf.org/html/rfc8474]]::
  #   Gondwana, B., Ed., "IMAP Extension for Object Identifiers",
  #   RFC 8474, DOI 10.17487/RFC8474, September 2018,
  #   <https://www.rfc-editor.org/info/rfc8474>.
  #
  # === IANA registries
  # * {IMAP Capabilities}[http://www.iana.org/assignments/imap4-capabilities]
  # * {IMAP Response Codes}[https://www.iana.org/assignments/imap-response-codes/imap-response-codes.xhtml]
  # * {IMAP Mailbox Name Attributes}[https://www.iana.org/assignments/imap-mailbox-name-attributes/imap-mailbox-name-attributes.xhtml]
  # * {IMAP and JMAP Keywords}[https://www.iana.org/assignments/imap-jmap-keywords/imap-jmap-keywords.xhtml]
  # * {IMAP Threading Algorithms}[https://www.iana.org/assignments/imap-threading-algorithms/imap-threading-algorithms.xhtml]
  # * {SASL Mechanisms and SASL SCRAM Family Mechanisms}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
  # * {Service Name and Transport Protocol Port Number Registry}[https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml]:
  #   +imap+: tcp/143, +imaps+: tcp/993
  # * {GSSAPI/Kerberos/SASL Service Names}[https://www.iana.org/assignments/gssapi-service-names/gssapi-service-names.xhtml]:
  #   +imap+
  # * {Character sets}[https://www.iana.org/assignments/character-sets/character-sets.xhtml]
  # ===== For currently unsupported features:
  # * {IMAP Quota Resource Types}[http://www.iana.org/assignments/imap4-capabilities#imap-capabilities-2]
  # * {LIST-EXTENDED options and responses}[https://www.iana.org/assignments/imap-list-extended/imap-list-extended.xhtml]
  # * {IMAP METADATA Server Entry and Mailbox Entry Registries}[https://www.iana.org/assignments/imap-metadata/imap-metadata.xhtml]
  # * {IMAP ANNOTATE Extension Entries and Attributes}[https://www.iana.org/assignments/imap-annotate-extension/imap-annotate-extension.xhtml]
  # * {IMAP URLAUTH Access Identifiers and Prefixes}[https://www.iana.org/assignments/urlauth-access-ids/urlauth-access-ids.xhtml]
  # * {IMAP URLAUTH Authorization Mechanism Registry}[https://www.iana.org/assignments/urlauth-authorization-mechanism-registry/urlauth-authorization-mechanism-registry.xhtml]
  #
  class IMAP < Protocol
    VERSION = "0.4.20"

    # Aliases for supported capabilities, to be used with the #enable command.
    ENABLE_ALIASES = {
      utf8:          "UTF8=ACCEPT",
      "UTF8=ONLY" => "UTF8=ACCEPT",
    }.freeze

    autoload :ResponseReader, File.expand_path("imap/response_reader", __dir__)
    autoload :SASL,        File.expand_path("imap/sasl",         __dir__)
    autoload :SASLAdapter, File.expand_path("imap/sasl_adapter", __dir__)
    autoload :StringPrep,  File.expand_path("imap/stringprep",   __dir__)

    include MonitorMixin
    if defined?(OpenSSL::SSL)
      include OpenSSL
      include SSL
    end

    # Returns the global Config object
    def self.config; Config.global end

    # Returns the global debug mode.
    # Delegates to {Net::IMAP.config.debug}[rdoc-ref:Config#debug].
    def self.debug; config.debug end

    # Sets the global debug mode.
    # Delegates to {Net::IMAP.config.debug=}[rdoc-ref:Config#debug=].
    def self.debug=(val)
      config.debug = val
    end

    # The default port for IMAP connections, port 143
    def self.default_port
      return PORT
    end

    # The default port for IMAPS connections, port 993
    def self.default_tls_port
      return SSL_PORT
    end

    class << self
      alias default_imap_port default_port
      alias default_imaps_port default_tls_port
      alias default_ssl_port default_tls_port
    end

    # Returns the initial greeting sent by the server, an UntaggedResponse.
    attr_reader :greeting

    # The client configuration.  See Net::IMAP::Config.
    #
    # By default, the client's local configuration inherits from the global
    # Net::IMAP.config.
    attr_reader :config

    ##
    # :attr_reader: open_timeout
    # Seconds to wait until a connection is opened.  Also used by #starttls.
    # Delegates to {config.open_timeout}[rdoc-ref:Config#open_timeout].

    ##
    # :attr_reader: idle_response_timeout
    # Seconds to wait until an IDLE response is received.
    # Delegates to {config.idle_response_timeout}[rdoc-ref:Config#idle_response_timeout].

    ##
    # :attr_accessor: max_response_size
    #
    # The maximum allowed server response size, in bytes.
    # Delegates to {config.max_response_size}[rdoc-ref:Config#max_response_size].

    # :stopdoc:
    def open_timeout;           config.open_timeout            end
    def idle_response_timeout;  config.idle_response_timeout   end
    def max_response_size;      config.max_response_size       end
    def max_response_size=(val) config.max_response_size = val end
    # :startdoc:

    # The hostname this client connected to
    attr_reader :host

    # The port this client connected to
    attr_reader :port

    # Returns the
    # {SSLContext}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html]
    # used by the SSLSocket when TLS is attempted, even when the TLS handshake
    # is unsuccessful.  The context object will be frozen.
    #
    # Returns +nil+ for a plaintext connection.
    attr_reader :ssl_ctx

    # Returns the parameters that were sent to #ssl_ctx
    # {set_params}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#method-i-set_params]
    # when the connection tries to use TLS (even when unsuccessful).
    #
    # Returns +false+ for a plaintext connection.
    attr_reader :ssl_ctx_params

    # Creates a new Net::IMAP object and connects it to the specified
    # +host+.
    #
    # ==== Options
    #
    # Accepts the following options:
    #
    # [port]
    #   Port number.  Defaults to 993 when +ssl+ is truthy, and 143 otherwise.
    #
    # [ssl]
    #   If +true+, the connection will use TLS with the default params set by
    #   {OpenSSL::SSL::SSLContext#set_params}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#method-i-set_params].
    #   If +ssl+ is a hash, it's passed to
    #   {OpenSSL::SSL::SSLContext#set_params}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#method-i-set_params];
    #   the keys are names of attribute assignment methods on
    #   SSLContext[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html].  For example:
    #
    #   [{ca_file}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#attribute-i-ca_file]]
    #     The path to a file containing a PEM-format CA certificate.
    #   [{ca_path}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#attribute-i-ca_path]]
    #     The path to a directory containing CA certificates in PEM format.
    #   [{min_version}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#method-i-min_version-3D]]
    #     Sets the lower bound on the supported SSL/TLS protocol version. Set to
    #     an +OpenSSL+ constant such as +OpenSSL::SSL::TLS1_2_VERSION+,
    #   [{verify_mode}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#attribute-i-verify_mode]]
    #     SSL session verification mode.  Valid modes include
    #     +OpenSSL::SSL::VERIFY_PEER+ and +OpenSSL::SSL::VERIFY_NONE+.
    #
    #   See {OpenSSL::SSL::SSLContext}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html] for other valid SSL context params.
    #
    #   See DeprecatedClientOptions.new for deprecated SSL arguments.
    #
    # [response_handlers]
    #   A list of response handlers to be added before the receiver thread is
    #   started.  This ensures every server response is handled, including the
    #   #greeting.  Note that the greeting is handled in the current thread, but
    #   all other responses are handled in the receiver thread.
    #
    # [config]
    #   A Net::IMAP::Config object to use as the basis for #config.  By default,
    #   the global Net::IMAP.config is used.
    #
    #   >>>
    #     *NOTE:* +config+ does not set #config directly---it sets the _parent_
    #     config for inheritance.  Every client creates its own unique #config.
    #
    #   All other keyword arguments are forwarded to Net::IMAP::Config.new, to
    #   initialize the client's #config. For example:
    #
    #   [{open_timeout}[rdoc-ref:Config#open_timeout]]
    #     Seconds to wait until a connection is opened
    #   [{idle_response_timeout}[rdoc-ref:Config#idle_response_timeout]]
    #     Seconds to wait until an IDLE response is received
    #
    #   See Net::IMAP::Config for other valid options.
    #
    # ==== Examples
    #
    # Connect to cleartext port 143 at mail.example.com and receive the server greeting:
    #   imap = Net::IMAP.new('mail.example.com', ssl: false) # => #<Net::IMAP:0x00007f79b0872bd0>
    #   imap.port          => 143
    #   imap.tls_verified? => false
    #   imap.greeting      => name: ("OK" | "PREAUTH") => status
    #   status # => "OK"
    #   # The client is connected in the "Not Authenticated" state.
    #
    # Connect with TLS to port 993
    #   imap = Net::IMAP.new('mail.example.com', ssl: true) # => #<Net::IMAP:0x00007f79b0872bd0>
    #   imap.port          => 993
    #   imap.tls_verified? => true
    #   imap.greeting      => name: (/OK/i | /PREAUTH/i) => status
    #   case status
    #   in /OK/i
    #     # The client is connected in the "Not Authenticated" state.
    #     imap.authenticate("PLAIN", "joe_user", "joes_password")
    #   in /PREAUTH/i
    #     # The client is connected in the "Authenticated" state.
    #   end
    #
    # Connect with prior authentication, for example using an SSL certificate:
    #   ssl_ctx_params = {
    #     cert: OpenSSL::X509::Certificate.new(File.read("client.crt")),
    #     key:  OpenSSL::PKey::EC.new(File.read('client.key')),
    #     extra_chain_cert: [
    #       OpenSSL::X509::Certificate.new(File.read("intermediate.crt")),
    #     ],
    #   }
    #   imap = Net::IMAP.new('mail.example.com', ssl: ssl_ctx_params)
    #   imap.port          => 993
    #   imap.tls_verified? => true
    #   imap.greeting      => name: "PREAUTH"
    #   # The client is connected in the "Authenticated" state.
    #
    # ==== Exceptions
    #
    # The most common errors are:
    #
    # [Errno::ECONNREFUSED]
    #   Connection refused by +host+ or an intervening firewall.
    # [Errno::ETIMEDOUT]
    #   Connection timed out (possibly due to packets being dropped by an
    #   intervening firewall).
    # [Errno::ENETUNREACH]
    #   There is no route to that network.
    # [SocketError]
    #   Hostname not known or other socket error.
    # [Net::IMAP::ByeResponseError]
    #   Connected to the host successfully, but it immediately said goodbye.
    #
    def initialize(host, port: nil, ssl: nil, response_handlers: nil,
                   config: Config.global, **config_options)
      super()
      # Config options
      @host = host
      @config = Config.new(config, **config_options)
      @port = port || (ssl ? SSL_PORT : PORT)
      @ssl_ctx_params, @ssl_ctx = build_ssl_ctx(ssl)

      # Basic Client State
      @utf8_strings = false
      @debug_output_bol = true
      @exception = nil
      @greeting = nil
      @capabilities = nil

      # Client Protocol Receiver
      @parser = ResponseParser.new(config: @config)
      @responses = Hash.new {|h, k| h[k] = [] }
      @response_handlers = []
      @receiver_thread = nil
      @receiver_thread_exception = nil
      @receiver_thread_terminating = false
      response_handlers&.each do add_response_handler(_1) end

      # Client Protocol Sender (including state for currently running commands)
      @tag_prefix = "RUBY"
      @tagno = 0
      @tagged_responses = {}
      @tagged_response_arrival = new_cond
      @continued_command_tag = nil
      @continuation_request_arrival = new_cond
      @continuation_request_exception = nil
      @idle_done_cond = nil
      @logout_command_tag = nil

      # Connection
      @tls_verified = false
      @sock = tcp_socket(@host, @port)
      @reader = ResponseReader.new(self, @sock)
      start_tls_session if ssl_ctx
      start_imap_connection

      # DEPRECATED: to remove in next version
      @client_thread = Thread.current
    end

    # Returns true after the TLS negotiation has completed and the remote
    # hostname has been verified.  Returns false when TLS has been established
    # but peer verification was disabled.
    def tls_verified?; @tls_verified end

    def client_thread # :nodoc:
      warn "Net::IMAP#client_thread is deprecated and will be removed soon."
      @client_thread
    end

    # Disconnects from the server.
    #
    # Related: #logout, #logout!
    def disconnect
      return if disconnected?
      begin
        begin
          # try to call SSL::SSLSocket#io.
          @sock.io.shutdown
        rescue NoMethodError
          # @sock is not an SSL::SSLSocket.
          @sock.shutdown
        end
      rescue Errno::ENOTCONN
        # ignore `Errno::ENOTCONN: Socket is not connected' on some platforms.
      rescue Exception => e
        @receiver_thread.raise(e)
      end
      @receiver_thread.join
      synchronize do
        @sock.close
      end
      raise e if e
    end

    # Returns true if disconnected from the server.
    #
    # Related: #logout, #disconnect
    def disconnected?
      return @sock.closed?
    end

    # Returns whether the server supports a given +capability+.  When available,
    # cached #capabilities are used without sending a new #capability command to
    # the server.
    #
    # <em>*NOTE:* Most Net::IMAP methods do not _currently_ modify their
    # behaviour according to the server's advertised #capabilities.</em>
    #
    # See Net::IMAP@Capabilities for more about \IMAP capabilities.
    #
    # Related: #auth_capable?, #capabilities, #capability, #enable
    def capable?(capability) capabilities.include? capability.to_s.upcase end
    alias capability? capable?

    # Returns the server capabilities.  When available, cached capabilities are
    # used without sending a new #capability command to the server.
    #
    # To ensure a case-insensitive comparison, #capable? can be used instead.
    #
    # <em>*NOTE:* Most Net::IMAP methods do not _currently_ modify their
    # behaviour according to the server's advertised #capabilities.</em>
    #
    # See Net::IMAP@Capabilities for more about \IMAP capabilities.
    #
    # Related: #capable?, #auth_capable?, #auth_mechanisms, #capability, #enable
    def capabilities
      @capabilities || capability
    end

    # Returns the #authenticate mechanisms that the server claims to support.
    # These are derived from the #capabilities with an <tt>AUTH=</tt> prefix.
    #
    # This may be different when the connection is cleartext or using TLS.  Most
    # servers will drop all <tt>AUTH=</tt> mechanisms from #capabilities after
    # the connection has authenticated.
    #
    #    imap = Net::IMAP.new(hostname, ssl: false)
    #    imap.capabilities    # => ["IMAP4REV1", "LOGINDISABLED"]
    #    imap.auth_mechanisms # => []
    #
    #    imap.starttls
    #    imap.capabilities    # => ["IMAP4REV1", "AUTH=PLAIN", "AUTH=XOAUTH2",
    #                         #     "AUTH=OAUTHBEARER"]
    #    imap.auth_mechanisms # => ["PLAIN", "XOAUTH2", "OAUTHBEARER"]
    #
    #    imap.authenticate("XOAUTH2", username, oauth2_access_token)
    #    imap.auth_mechanisms # => []
    #
    # Related: #authenticate, #auth_capable?, #capabilities
    def auth_mechanisms
      capabilities
        .grep(/\AAUTH=/i)
        .map { _1.delete_prefix("AUTH=") }
    end

    # Returns whether the server supports a given SASL +mechanism+ for use with
    # the #authenticate command.  The +mechanism+ is supported when
    # #capabilities includes <tt>"AUTH=#{mechanism.to_s.upcase}"</tt>.  When
    # available, cached capabilities are used without sending a new #capability
    # command to the server.
    #
    #   imap.capable?      "AUTH=PLAIN"  # => true
    #   imap.auth_capable? "PLAIN"       # => true
    #   imap.auth_capable? "blurdybloop" # => false
    #
    # Related: #authenticate, #auth_mechanisms, #capable?, #capabilities
    def auth_capable?(mechanism)
      capable? "AUTH=#{mechanism}"
    end

    # Returns whether capabilities have been cached.  When true, #capable? and
    # #capabilities don't require sending a #capability command to the server.
    #
    # See Net::IMAP@Capabilities for more about \IMAP capabilities.
    #
    # Related: #capable?, #capability, #clear_cached_capabilities
    def capabilities_cached?
      !!@capabilities
    end

    # Clears capabilities that have been remembered by the Net::IMAP client.
    # This forces a #capability command to be sent the next time a #capabilities
    # query method is called.
    #
    # Net::IMAP automatically discards its cached capabilities when they can
    # change.  Explicitly calling this _should_ be unnecessary for well-behaved
    # servers.
    #
    # Related: #capable?, #capability, #capabilities_cached?
    def clear_cached_capabilities
      synchronize do
        clear_responses("CAPABILITY")
        @capabilities = nil
      end
    end

    # Sends a {CAPABILITY command [IMAP4rev1 §6.1.1]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.1.1]
    # and returns an array of capabilities that are supported by the server.
    # The result is stored for use by #capable? and #capabilities.
    #
    # <em>*NOTE:* Most Net::IMAP methods do not _currently_ modify their
    # behaviour according to the server's advertised #capabilities.</em>
    #
    # Net::IMAP automatically stores and discards capability data according to
    # the requirements and recommendations in
    # {IMAP4rev2 §6.1.1}[https://www.rfc-editor.org/rfc/rfc9051#section-6.1.1],
    # {§6.2}[https://www.rfc-editor.org/rfc/rfc9051#section-6.2], and
    # {§7.1}[https://www.rfc-editor.org/rfc/rfc9051#section-7.1].
    # Use #capable?, #auth_capable?, or #capabilities to this cache and avoid
    # sending the #capability command unnecessarily.
    #
    # See Net::IMAP@Capabilities for more about \IMAP capabilities.
    #
    # Related: #capable?, #auth_capable?, #capability, #enable
    def capability
      synchronize do
        send_command("CAPABILITY")
        @capabilities = clear_responses("CAPABILITY").last.freeze
      end
    end

    # Sends an {ID command [RFC2971 §3.1]}[https://www.rfc-editor.org/rfc/rfc2971#section-3.1]
    # and returns a hash of the server's response, or nil if the server does not
    # identify itself.
    #
    # Note that the user should first check if the server supports the ID
    # capability. For example:
    #
    #    if capable?(:ID)
    #      id = imap.id(
    #        name: "my IMAP client (ruby)",
    #        version: MyIMAP::VERSION,
    #        "support-url": "mailto:bugs@example.com",
    #        os: RbConfig::CONFIG["host_os"],
    #      )
    #    end
    #
    # See [ID[https://tools.ietf.org/html/rfc2971]] for field definitions.
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +ID+
    # [RFC2971[https://tools.ietf.org/html/rfc2971]].
    def id(client_id=nil)
      synchronize do
        send_command("ID", ClientID.new(client_id))
        clear_responses("ID").last
      end
    end

    # Sends a {NOOP command [IMAP4rev1 §6.1.2]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.1.2]
    # to the server.
    #
    # This allows the server to send unsolicited untagged EXPUNGE #responses,
    # but does not execute any client request.  \IMAP servers are permitted to
    # send unsolicited untagged responses at any time, except for +EXPUNGE+:
    #
    # * +EXPUNGE+ can only be sent while a command is in progress.
    # * +EXPUNGE+ must _not_ be sent during #fetch, #store, or #search.
    # * +EXPUNGE+ may be sent during #uid_fetch, #uid_store, or #uid_search.
    #
    # Related: #idle, #check
    def noop
      send_command("NOOP")
    end

    # Sends a {LOGOUT command [IMAP4rev1 §6.1.3]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.1.3]
    # to inform the command to inform the server that the client is done with
    # the connection.
    #
    # Related: #disconnect, #logout!
    def logout
      send_command("LOGOUT")
    end

    # Calls #logout then, after receiving the TaggedResponse for the +LOGOUT+,
    # calls #disconnect.  Returns the TaggedResponse from +LOGOUT+.  Returns
    # +nil+ when the client is already disconnected, in contrast to #logout
    # which raises an exception.
    #
    # If #logout raises a StandardError, a warning will be printed but the
    # exception will not be re-raised.
    #
    # This is useful in situations where the connection must be dropped, for
    # example for security or after tests.  If logout errors need to be handled,
    # use #logout and #disconnect instead.
    #
    # Related: #logout, #disconnect
    def logout!
      logout unless disconnected?
    rescue => ex
      warn "%s during <Net::IMAP %s:%s> logout!: %s" % [
        ex.class, host, port, ex
      ]
    ensure
      disconnect
    end

    # Sends a {STARTTLS command [IMAP4rev1 §6.2.1]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.2.1]
    # to start a TLS session.
    #
    # Any +options+ are forwarded directly to
    # {OpenSSL::SSL::SSLContext#set_params}[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html#method-i-set_params];
    # the keys are names of attribute assignment methods on
    # SSLContext[https://docs.ruby-lang.org/en/master/OpenSSL/SSL/SSLContext.html].
    #
    # See DeprecatedClientOptions#starttls for deprecated arguments.
    #
    # This method returns after TLS negotiation and hostname verification are
    # both successful.  Any error indicates that the connection has not been
    # secured.
    #
    # After the server agrees to start a TLS connection, this method waits up to
    # {config.open_timeout}[rdoc-ref:Config#open_timeout] before raising
    # +Net::OpenTimeout+.
    #
    # *Note:*
    # >>>
    #   Any #response_handlers added before STARTTLS should be aware that the
    #   TaggedResponse to STARTTLS is sent clear-text, _before_ TLS negotiation.
    #   TLS starts immediately _after_ that response.  Any response code sent
    #   with the response (e.g. CAPABILITY) is insecure and cannot be trusted.
    #
    # Related: Net::IMAP.new, #login, #authenticate
    #
    # ===== Capability
    # Clients should not call #starttls unless the server advertises the
    # +STARTTLS+ capability.
    #
    # Server capabilities may change after #starttls, #login, and #authenticate.
    # Cached #capabilities will be cleared when this method completes.
    #
    def starttls(**options)
      @ssl_ctx_params, @ssl_ctx = build_ssl_ctx(options)
      error = nil
      ok = send_command("STARTTLS") do |resp|
        if resp.kind_of?(TaggedResponse) && resp.name == "OK"
          clear_cached_capabilities
          clear_responses
          start_tls_session
        end
      rescue Exception => error
        raise # note that the error backtrace is in the receiver_thread
      end
      if error
        disconnect
        raise error
      end
      ok
    end

    # :call-seq:
    #   authenticate(mechanism, *, sasl_ir: config.sasl_ir, registry: Net::IMAP::SASL.authenticators, **, &) -> ok_resp
    #
    # Sends an {AUTHENTICATE command [IMAP4rev1 §6.2.2]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.2.2]
    # to authenticate the client.  If successful, the connection enters the
    # "_authenticated_" state.
    #
    # +mechanism+ is the name of the \SASL authentication mechanism to be used.
    #
    # +sasl_ir+ allows or disallows sending an "initial response" (see the
    # +SASL-IR+ capability, below).  Defaults to the #config value for
    # {sasl_ir}[rdoc-ref:Config#sasl_ir], which defaults to +true+.
    #
    # All other arguments are forwarded to the registered SASL authenticator for
    # the requested mechanism.  <em>The documentation for each individual
    # mechanism must be consulted for its specific parameters.</em>
    #
    # Related: #login, #starttls, #auth_capable?, #auth_mechanisms
    #
    # ==== Mechanisms
    #
    # Each mechanism has different properties and requirements.  Please consult
    # the documentation for the specific mechanisms you are using:
    #
    # +ANONYMOUS+::
    #     See AnonymousAuthenticator[rdoc-ref:Net::IMAP::SASL::AnonymousAuthenticator].
    #
    #     Allows the user to gain access to public services or resources without
    #     authenticating or disclosing an identity.
    #
    # +EXTERNAL+::
    #     See ExternalAuthenticator[rdoc-ref:Net::IMAP::SASL::ExternalAuthenticator].
    #
    #     Authenticates using already established credentials, such as a TLS
    #     certificate or IPsec.
    #
    # +OAUTHBEARER+::
    #     See OAuthBearerAuthenticator[rdoc-ref:Net::IMAP::SASL::OAuthBearerAuthenticator].
    #
    #     Login using an OAuth2 Bearer token.  This is the standard mechanism
    #     for using OAuth2 with \SASL, but it is not yet deployed as widely as
    #     +XOAUTH2+.
    #
    # +PLAIN+::
    #     See PlainAuthenticator[rdoc-ref:Net::IMAP::SASL::PlainAuthenticator].
    #
    #     Login using clear-text username and password.
    #
    # +SCRAM-SHA-1+::
    # +SCRAM-SHA-256+::
    #     See ScramAuthenticator[rdoc-ref:Net::IMAP::SASL::ScramAuthenticator].
    #
    #     Login by username and password.  The password is not sent to the
    #     server but is used in a salted challenge/response exchange.
    #     +SCRAM-SHA-1+ and +SCRAM-SHA-256+ are directly supported by
    #     Net::IMAP::SASL.  New authenticators can easily be added for any other
    #     <tt>SCRAM-*</tt> mechanism if the digest algorithm is supported by
    #     OpenSSL::Digest.
    #
    # +XOAUTH2+::
    #     See XOAuth2Authenticator[rdoc-ref:Net::IMAP::SASL::XOAuth2Authenticator].
    #
    #     Login using a username and an OAuth2 access token.  Non-standard and
    #     obsoleted by +OAUTHBEARER+, but widely supported.
    #
    # See the {SASL mechanism
    # registry}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
    # for a list of all SASL mechanisms and their specifications.  To register
    # new authenticators, see Authenticators.
    #
    # ===== Deprecated mechanisms
    #
    # <em>Obsolete mechanisms should be avoided, but are still available for
    # backwards compatibility.  See</em> Net::IMAP::SASL@Deprecated+mechanisms.
    # <em>Using a deprecated mechanism will print a warning.</em>
    #
    # ==== Capabilities
    #
    # <tt>"AUTH=#{mechanism}"</tt> capabilities indicate server support for
    # mechanisms.  Use #auth_capable? or #auth_mechanisms to check for support
    # before using a particular mechanism.
    #
    #    if imap.auth_capable? "XOAUTH2"
    #      imap.authenticate "XOAUTH2", username, oauth2_access_token
    #    elsif imap.auth_capable? "PLAIN"
    #      imap.authenticate "PLAIN", username, password
    #    elsif !imap.capability? "LOGINDISABLED"
    #      imap.login username, password
    #    else
    #      raise "No acceptable authentication mechanism is available"
    #    end
    #
    # Although servers should list all supported \SASL mechanisms, they may
    # allow authentication with an unlisted +mechanism+.
    #
    # If [SASL-IR[https://www.rfc-editor.org/rfc/rfc4959.html]] is supported
    # and the appropriate <tt>"AUTH=#{mechanism}"</tt> capability is present,
    # an "initial response" may be sent as an argument to the +AUTHENTICATE+
    # command, saving a round-trip.  The SASL exchange allows for server
    # challenges and client responses, but many mechanisms expect the client to
    # "respond" first.  The initial response will only be sent for
    # "client-first" mechanisms.
    #
    # Server capabilities may change after #starttls, #login, and #authenticate.
    # Previously cached #capabilities will be cleared when this method
    # completes.  If the TaggedResponse to #authenticate includes updated
    # capabilities, they will be cached.
    def authenticate(mechanism, *creds,
                     sasl_ir: config.sasl_ir,
                     **props, &callback)
      mechanism = mechanism.to_s.tr("_", "-").upcase
      authenticator = SASL.authenticator(mechanism, *creds, **props, &callback)
      cmdargs = ["AUTHENTICATE", mechanism]
      if sasl_ir && capable?("SASL-IR") && auth_capable?(mechanism) &&
          authenticator.respond_to?(:initial_response?) &&
          authenticator.initial_response?
        response = authenticator.process(nil)
        cmdargs << (response.empty? ? "=" : [response].pack("m0"))
      end
      result = send_command_with_continuations(*cmdargs) {|data|
        challenge = data.unpack1("m")
        response  = authenticator.process challenge
        [response].pack("m0")
      }
      if authenticator.respond_to?(:done?) && !authenticator.done?
        logout!
        raise SASL::AuthenticationIncomplete, result
      end
      @capabilities = capabilities_from_resp_code result
      result
    end

    # Sends a {LOGIN command [IMAP4rev1 §6.2.3]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.2.3]
    # to identify the client and carries the plaintext +password+ authenticating
    # this +user+.  If successful, the connection enters the "_authenticated_"
    # state.
    #
    # Using #authenticate {should be
    # preferred}[https://www.rfc-editor.org/rfc/rfc9051.html#name-login-command]
    # over #login.  The LOGIN command is not the same as #authenticate with the
    # "LOGIN" +mechanism+.
    #
    # A Net::IMAP::NoResponseError is raised if authentication fails.
    #
    # Related: #authenticate, #starttls
    #
    # ===== Capabilities
    #
    # An IMAP client MUST NOT call #login when the server advertises the
    # +LOGINDISABLED+ capability.
    #
    #    if imap.capability? "LOGINDISABLED"
    #      raise "Remote server has disabled the login command"
    #    else
    #      imap.login username, password
    #    end
    #
    # Server capabilities may change after #starttls, #login, and #authenticate.
    # Cached capabilities _must_ be invalidated after this method completes.
    # The TaggedResponse to #login may include updated capabilities in its
    # ResponseCode.
    #
    def login(user, password)
      send_command("LOGIN", user, password)
        .tap { @capabilities = capabilities_from_resp_code _1 }
    end

    # Sends a {SELECT command [IMAP4rev1 §6.3.1]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.1]
    # to select a +mailbox+ so that messages in the +mailbox+ can be accessed.
    #
    # After you have selected a mailbox, you may retrieve the number of items in
    # that mailbox from <tt>imap.responses("EXISTS", &:last)</tt>, and the
    # number of recent messages from <tt>imap.responses("RECENT", &:last)</tt>.
    # Note that these values can change if new messages arrive during a session
    # or when existing messages are expunged; see #add_response_handler for a
    # way to detect these events.
    #
    # When the +condstore+ keyword argument is true, the server is told to
    # enable the extension.  If +mailbox+ supports persistence of mod-sequences,
    # the +HIGHESTMODSEQ+ ResponseCode will be sent as an untagged response to
    # #select and all `FETCH` responses will include FetchData#modseq.
    # Otherwise, the +NOMODSEQ+ ResponseCode will be sent.
    #
    # A Net::IMAP::NoResponseError is raised if the mailbox does not
    # exist or is for some reason non-selectable.
    #
    # Related: #examine
    #
    # ===== Capabilities
    #
    # If [UIDPLUS[https://www.rfc-editor.org/rfc/rfc4315.html]] is supported,
    # the server may return an untagged "NO" response with a "UIDNOTSTICKY"
    # response code indicating that the mailstore does not support persistent
    # UIDs:
    #   imap.responses("NO", &:last)&.code&.name == "UIDNOTSTICKY"
    #
    # If [CONDSTORE[https://www.rfc-editor.org/rfc/rfc7162.html]] is supported,
    # the +condstore+ keyword parameter may be used.
    #   imap.select("mbox", condstore: true)
    #   modseq = imap.responses("HIGHESTMODSEQ", &:last)
    def select(mailbox, condstore: false)
      args = ["SELECT", mailbox]
      args << ["CONDSTORE"] if condstore
      synchronize do
        @responses.clear
        send_command(*args)
      end
    end

    # Sends a {EXAMINE command [IMAP4rev1 §6.3.2]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.2]
    # to select a +mailbox+ so that messages in the +mailbox+ can be accessed.
    # Behaves the same as #select, except that the selected +mailbox+ is
    # identified as read-only.
    #
    # A Net::IMAP::NoResponseError is raised if the mailbox does not
    # exist or is for some reason non-examinable.
    #
    # Related: #select
    def examine(mailbox, condstore: false)
      args = ["EXAMINE", mailbox]
      args << ["CONDSTORE"] if condstore
      synchronize do
        @responses.clear
        send_command(*args)
      end
    end

    # Sends a {CREATE command [IMAP4rev1 §6.3.3]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.3]
    # to create a new +mailbox+.
    #
    # A Net::IMAP::NoResponseError is raised if a mailbox with that name
    # cannot be created.
    #
    # Related: #rename, #delete
    def create(mailbox)
      send_command("CREATE", mailbox)
    end

    # Sends a {DELETE command [IMAP4rev1 §6.3.4]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.4]
    # to remove the +mailbox+.
    #
    # A Net::IMAP::NoResponseError is raised if a mailbox with that name
    # cannot be deleted, either because it does not exist or because the
    # client does not have permission to delete it.
    #
    # Related: #create, #rename
    def delete(mailbox)
      send_command("DELETE", mailbox)
    end

    # Sends a {RENAME command [IMAP4rev1 §6.3.5]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.5]
    # to change the name of the +mailbox+ to +newname+.
    #
    # A Net::IMAP::NoResponseError is raised if a mailbox with the
    # name +mailbox+ cannot be renamed to +newname+ for whatever
    # reason; for instance, because +mailbox+ does not exist, or
    # because there is already a mailbox with the name +newname+.
    #
    # Related: #create, #delete
    def rename(mailbox, newname)
      send_command("RENAME", mailbox, newname)
    end

    # Sends a {SUBSCRIBE command [IMAP4rev1 §6.3.6]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.6]
    # to add the specified +mailbox+ name to the server's set of "active" or
    # "subscribed" mailboxes as returned by #lsub.
    #
    # A Net::IMAP::NoResponseError is raised if +mailbox+ cannot be
    # subscribed to; for instance, because it does not exist.
    #
    # Related: #unsubscribe, #lsub, #list
    def subscribe(mailbox)
      send_command("SUBSCRIBE", mailbox)
    end

    # Sends an {UNSUBSCRIBE command [IMAP4rev1 §6.3.7]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.7]
    # to remove the specified +mailbox+ name from the server's set of "active"
    # or "subscribed" mailboxes.
    #
    # A Net::IMAP::NoResponseError is raised if +mailbox+ cannot be
    # unsubscribed from; for instance, because the client is not currently
    # subscribed to it.
    #
    # Related: #subscribe, #lsub, #list
    def unsubscribe(mailbox)
      send_command("UNSUBSCRIBE", mailbox)
    end

    # Sends a {LIST command [IMAP4rev1 §6.3.8]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.8]
    # and returns a subset of names from the complete set of all names available
    # to the client.  +refname+ provides a context (for instance, a base
    # directory in a directory-based mailbox hierarchy).  +mailbox+ specifies a
    # mailbox or (via wildcards) mailboxes under that context.  Two wildcards
    # may be used in +mailbox+: <tt>"*"</tt>, which matches all characters
    # *including* the hierarchy delimiter (for instance, "/" on a UNIX-hosted
    # directory-based mailbox hierarchy); and <tt>"%"</tt>, which matches all
    # characters *except* the hierarchy delimiter.
    #
    # If +refname+ is empty, +mailbox+ is used directly to determine
    # which mailboxes to match.  If +mailbox+ is empty, the root
    # name of +refname+ and the hierarchy delimiter are returned.
    #
    # The return value is an array of MailboxList.
    #
    # Related: #lsub, MailboxList
    #
    # ===== For example:
    #
    #   imap.create("foo/bar")
    #   imap.create("foo/baz")
    #   p imap.list("", "foo/%")
    #   #=> [#<Net::IMAP::MailboxList attr=[:Noselect], delim="/", name="foo/">, \\
    #        #<Net::IMAP::MailboxList attr=[:Noinferiors, :Marked], delim="/", name="foo/bar">, \\
    #        #<Net::IMAP::MailboxList attr=[:Noinferiors], delim="/", name="foo/baz">]
    #
    #--
    # TODO: support LIST-EXTENDED extension [RFC5258].  Needed for IMAP4rev2.
    #++
    def list(refname, mailbox)
      synchronize do
        send_command("LIST", refname, mailbox)
        clear_responses("LIST")
      end
    end

    # Sends a {NAMESPACE command [RFC2342 §5]}[https://www.rfc-editor.org/rfc/rfc2342#section-5]
    # and returns the namespaces that are available.  The NAMESPACE command
    # allows a client to discover the prefixes of namespaces used by a server
    # for personal mailboxes, other users' mailboxes, and shared mailboxes.
    #
    # The return value is a Namespaces object which has +personal+, +other+, and
    # +shared+ fields, each an array of Namespace objects.  These arrays will be
    # empty when the server responds with +nil+.
    #
    # Many \IMAP servers are configured with the default personal namespaces as
    # <tt>("" "/")</tt>: no prefix and the "+/+" hierarchy delimiter. In that
    # common case, the naive client may not have any trouble naming mailboxes.
    # But many servers are configured with the default personal namespace as
    # e.g.  <tt>("INBOX." ".")</tt>, placing all personal folders under INBOX,
    # with "+.+" as the hierarchy delimiter. If the client does not check for
    # this, but naively assumes it can use the same folder names for all
    # servers, then folder creation (and listing, moving, etc) can lead to
    # errors.
    #
    # From RFC2342[https://tools.ietf.org/html/rfc2342]:
    # >>>
    #    <em>Although typically a server will support only a single Personal
    #    Namespace, and a single Other User's Namespace, circumstances exist
    #    where there MAY be multiples of these, and a client MUST be prepared
    #    for them.  If a client is configured such that it is required to create
    #    a certain mailbox, there can be circumstances where it is unclear which
    #    Personal Namespaces it should create the mailbox in.  In these
    #    situations a client SHOULD let the user select which namespaces to
    #    create the mailbox in.</em>
    #
    # Related: #list, Namespaces, Namespace
    #
    # ===== For example:
    #
    #    if capable?("NAMESPACE")
    #      namespaces = imap.namespace
    #      if namespace = namespaces.personal.first
    #        prefix = namespace.prefix  # e.g. "" or "INBOX."
    #        delim  = namespace.delim   # e.g. "/" or "."
    #        # personal folders should use the prefix and delimiter
    #        imap.create(prefix + "foo")
    #        imap.create(prefix + "bar")
    #        imap.create(prefix + %w[path to my folder].join(delim))
    #      end
    #    end
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +NAMESPACE+
    # [RFC2342[https://tools.ietf.org/html/rfc2342]].
    def namespace
      synchronize do
        send_command("NAMESPACE")
        clear_responses("NAMESPACE").last
      end
    end

    # Sends a XLIST command, and returns a subset of names from
    # the complete set of all names available to the client.
    # +refname+ provides a context (for instance, a base directory
    # in a directory-based mailbox hierarchy).  +mailbox+ specifies
    # a mailbox or (via wildcards) mailboxes under that context.
    # Two wildcards may be used in +mailbox+: '*', which matches
    # all characters *including* the hierarchy delimiter (for instance,
    # '/' on a UNIX-hosted directory-based mailbox hierarchy); and '%',
    # which matches all characters *except* the hierarchy delimiter.
    #
    # If +refname+ is empty, +mailbox+ is used directly to determine
    # which mailboxes to match.  If +mailbox+ is empty, the root
    # name of +refname+ and the hierarchy delimiter are returned.
    #
    # The XLIST command is like the LIST command except that the flags
    # returned refer to the function of the folder/mailbox, e.g. :Sent
    #
    # The return value is an array of MailboxList objects. For example:
    #
    #   imap.create("foo/bar")
    #   imap.create("foo/baz")
    #   p imap.xlist("", "foo/%")
    #   #=> [#<Net::IMAP::MailboxList attr=[:Noselect], delim="/", name="foo/">, \\
    #        #<Net::IMAP::MailboxList attr=[:Noinferiors, :Marked], delim="/", name="foo/bar">, \\
    #        #<Net::IMAP::MailboxList attr=[:Noinferiors], delim="/", name="foo/baz">]
    #
    # Related: #list, MailboxList
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +XLIST+,
    # a deprecated Gmail extension (replaced by +SPECIAL-USE+).
    #--
    # TODO: Net::IMAP doesn't yet have full SPECIAL-USE support.  Supporting
    # servers MAY return SPECIAL-USE attributes, but are not *required* to
    # unless the SPECIAL-USE return option is supplied.
    #++
    def xlist(refname, mailbox)
      synchronize do
        send_command("XLIST", refname, mailbox)
        clear_responses("XLIST")
      end
    end

    # Sends a {GETQUOTAROOT command [RFC2087 §4.3]}[https://www.rfc-editor.org/rfc/rfc2087#section-4.3]
    # along with the specified +mailbox+.  This command is generally available
    # to both admin and user.  If this mailbox exists, it returns an array
    # containing objects of type MailboxQuotaRoot and MailboxQuota.
    #
    # Related: #getquota, #setquota, MailboxQuotaRoot, MailboxQuota
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +QUOTA+
    # [RFC2087[https://tools.ietf.org/html/rfc2087]].
    def getquotaroot(mailbox)
      synchronize do
        send_command("GETQUOTAROOT", mailbox)
        result = []
        result.concat(clear_responses("QUOTAROOT"))
        result.concat(clear_responses("QUOTA"))
        return result
      end
    end

    # Sends a {GETQUOTA command [RFC2087 §4.2]}[https://www.rfc-editor.org/rfc/rfc2087#section-4.2]
    # along with specified +mailbox+.  If this mailbox exists, then an array
    # containing a MailboxQuota object is returned.  This command is generally
    # only available to server admin.
    #
    # Related: #getquotaroot, #setquota, MailboxQuota
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +QUOTA+
    # [RFC2087[https://tools.ietf.org/html/rfc2087]].
    def getquota(mailbox)
      synchronize do
        send_command("GETQUOTA", mailbox)
        clear_responses("QUOTA")
      end
    end

    # Sends a {SETQUOTA command [RFC2087 §4.1]}[https://www.rfc-editor.org/rfc/rfc2087#section-4.1]
    # along with the specified +mailbox+ and +quota+.  If +quota+ is nil, then
    # +quota+ will be unset for that mailbox.  Typically one needs to be logged
    # in as a server admin for this to work.
    #
    # Related: #getquota, #getquotaroot
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +QUOTA+
    # [RFC2087[https://tools.ietf.org/html/rfc2087]].
    def setquota(mailbox, quota)
      if quota.nil?
        data = '()'
      else
        data = '(STORAGE ' + quota.to_s + ')'
      end
      send_command("SETQUOTA", mailbox, RawData.new(data))
    end

    # Sends a {SETACL command [RFC4314 §3.1]}[https://www.rfc-editor.org/rfc/rfc4314#section-3.1]
    # along with +mailbox+, +user+ and the +rights+ that user is to have on that
    # mailbox.  If +rights+ is nil, then that user will be stripped of any
    # rights to that mailbox.
    #
    # Related: #getacl
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +ACL+
    # [RFC4314[https://tools.ietf.org/html/rfc4314]].
    def setacl(mailbox, user, rights)
      if rights.nil?
        send_command("SETACL", mailbox, user, "")
      else
        send_command("SETACL", mailbox, user, rights)
      end
    end

    # Sends a {GETACL command [RFC4314 §3.3]}[https://www.rfc-editor.org/rfc/rfc4314#section-3.3]
    # along with a specified +mailbox+.  If this mailbox exists, an array
    # containing objects of MailboxACLItem will be returned.
    #
    # Related: #setacl, MailboxACLItem
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +ACL+
    # [RFC4314[https://tools.ietf.org/html/rfc4314]].
    def getacl(mailbox)
      synchronize do
        send_command("GETACL", mailbox)
        clear_responses("ACL").last
      end
    end

    # Sends a {LSUB command [IMAP4rev1 §6.3.9]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.9]
    # and returns a subset of names from the set of names that the user has
    # declared as being "active" or "subscribed."  +refname+ and +mailbox+ are
    # interpreted as for #list.
    #
    # The return value is an array of MailboxList objects.
    #
    # Related: #subscribe, #unsubscribe, #list, MailboxList
    def lsub(refname, mailbox)
      synchronize do
        send_command("LSUB", refname, mailbox)
        clear_responses("LSUB")
      end
    end

    # Sends a {STATUS command [IMAP4rev1 §6.3.10]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.10]
    # and returns the status of the indicated +mailbox+. +attr+ is a list of one
    # or more attributes whose statuses are to be requested.
    #
    # The return value is a hash of attributes.  Most status attributes return
    # integer values, but some return other value types (documented below).
    #
    # A Net::IMAP::NoResponseError is raised if status values
    # for +mailbox+ cannot be returned; for instance, because it
    # does not exist.
    #
    # ===== Supported attributes
    #
    # +MESSAGES+::    The number of messages in the mailbox.
    #
    # +UIDNEXT+::     The next unique identifier value of the mailbox.
    #
    # +UIDVALIDITY+:: The unique identifier validity value of the mailbox.
    #
    # +UNSEEN+::      The number of messages without the <tt>\Seen</tt> flag.
    #
    # +DELETED+::     The number of messages with the <tt>\Deleted</tt> flag.
    #
    # +SIZE+::
    #     The approximate size of the mailbox---must be greater than or equal to
    #     the sum of all messages' +RFC822.SIZE+ fetch item values.
    #
    # +HIGHESTMODSEQ+::
    #    The highest mod-sequence value of all messages in the mailbox.  See
    #    +CONDSTORE+ {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html].
    #
    # +MAILBOXID+::
    #     A server-allocated unique _string_ identifier for the mailbox.  See
    #     +OBJECTID+ {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html].
    #
    # +RECENT+::
    #     The number of messages with the <tt>\Recent</tt> flag.
    #     _NOTE:_ +RECENT+ was removed from IMAP4rev2.
    #
    # Unsupported attributes may be requested.  The attribute value will be
    # either an Integer or an ExtensionData object.
    #
    # ===== For example:
    #
    #   p imap.status("inbox", ["MESSAGES", "RECENT"])
    #   #=> {"RECENT"=>0, "MESSAGES"=>44}
    #
    # ===== Capabilities
    #
    # +SIZE+ requires the server's capabilities to include either +IMAP4rev2+ or
    # <tt>STATUS=SIZE</tt>
    # {[RFC8483]}[https://www.rfc-editor.org/rfc/rfc8483.html].
    #
    # +DELETED+ requires the server's capabilities to include +IMAP4rev2+.
    #
    # +HIGHESTMODSEQ+ requires the server's capabilities to include +CONDSTORE+
    # {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html].
    #
    # +MAILBOXID+ requires the server's capabilities to include +OBJECTID+
    # {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html].
    def status(mailbox, attr)
      synchronize do
        send_command("STATUS", mailbox, attr)
        clear_responses("STATUS").last&.attr
      end
    end

    # Sends an {APPEND command [IMAP4rev1 §6.3.11]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.3.11]
    # to append the +message+ to the end of the +mailbox+. The optional +flags+
    # argument is an array of flags initially passed to the new message.  The
    # optional +date_time+ argument specifies the creation time to assign to the
    # new message; it defaults to the current time.
    #
    # For example:
    #
    #   imap.append("inbox", <<EOF.gsub(/\n/, "\r\n"), [:Seen], Time.now)
    #   Subject: hello
    #   From: shugo@ruby-lang.org
    #   To: shugo@ruby-lang.org
    #
    #   hello world
    #   EOF
    #
    # A Net::IMAP::NoResponseError is raised if the mailbox does
    # not exist (it is not created automatically), or if the flags,
    # date_time, or message arguments contain errors.
    #
    # ===== Capabilities
    #
    # If +UIDPLUS+ [RFC4315[https://www.rfc-editor.org/rfc/rfc4315.html]] is
    # supported and the destination supports persistent UIDs, the server's
    # response should include an +APPENDUID+ response code with UIDPlusData.
    # This will report the UIDVALIDITY of the destination mailbox and the
    # assigned UID of the appended message.
    #
    #--
    # TODO: add MULTIAPPEND support
    #++
    def append(mailbox, message, flags = nil, date_time = nil)
      args = []
      if flags
        args.push(flags)
      end
      args.push(date_time) if date_time
      args.push(Literal.new(message))
      send_command("APPEND", mailbox, *args)
    end

    # Sends a {CHECK command [IMAP4rev1 §6.4.1]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.1]
    # to request a checkpoint of the currently selected mailbox.  This performs
    # implementation-specific housekeeping; for instance, reconciling the
    # mailbox's in-memory and on-disk state.
    #
    # Related: #idle, #noop
    def check
      send_command("CHECK")
    end

    # Sends a {CLOSE command [IMAP4rev1 §6.4.2]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.2]
    # to close the currently selected mailbox.  The CLOSE command permanently
    # removes from the mailbox all messages that have the <tt>\\Deleted</tt>
    # flag set.
    #
    # Related: #unselect
    def close
      send_command("CLOSE")
    end

    # Sends an {UNSELECT command [RFC3691 §2]}[https://www.rfc-editor.org/rfc/rfc3691#section-3]
    # {[IMAP4rev2 §6.4.2]}[https://www.rfc-editor.org/rfc/rfc9051#section-6.4.2]
    # to free the session resources for a mailbox and return to the
    # "_authenticated_" state.  This is the same as #close, except that
    # <tt>\\Deleted</tt> messages are not removed from the mailbox.
    #
    # Related: #close
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +UNSELECT+
    # [RFC3691[https://tools.ietf.org/html/rfc3691]].
    def unselect
      send_command("UNSELECT")
    end

    # Sends an {EXPUNGE command [IMAP4rev1 §6.4.3]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.3]
    # Sends a EXPUNGE command to permanently remove from the currently
    # selected mailbox all messages that have the \Deleted flag set.
    #
    # Related: #uid_expunge
    def expunge
      synchronize do
        send_command("EXPUNGE")
        clear_responses("EXPUNGE")
      end
    end

    # Sends a {UID EXPUNGE command [RFC4315 §2.1]}[https://www.rfc-editor.org/rfc/rfc4315#section-2.1]
    # {[IMAP4rev2 §6.4.9]}[https://www.rfc-editor.org/rfc/rfc9051#section-6.4.9]
    # to permanently remove all messages that have both the <tt>\\Deleted</tt>
    # flag set and a UID that is included in +uid_set+.
    #
    # By using #uid_expunge instead of #expunge when resynchronizing with
    # the server, the client can ensure that it does not inadvertantly
    # remove any messages that have been marked as <tt>\\Deleted</tt> by other
    # clients between the time that the client was last connected and
    # the time the client resynchronizes.
    #
    # *Note:*
    # >>>
    #        Although the command takes a set of UIDs for its argument, the
    #        server still returns regular EXPUNGE responses, which contain
    #        a <em>sequence number</em>. These will be deleted from
    #        #responses and this method returns them as an array of
    #        <em>sequence number</em> integers.
    #
    # Related: #expunge
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +UIDPLUS+
    # [RFC4315[https://www.rfc-editor.org/rfc/rfc4315.html]].
    def uid_expunge(uid_set)
      synchronize do
        send_command("UID EXPUNGE", MessageSet.new(uid_set))
        clear_responses("EXPUNGE")
      end
    end

    # Sends a {SEARCH command [IMAP4rev1 §6.4.4]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.4]
    # to search the mailbox for messages that match the given searching
    # criteria, and returns message sequence numbers.  +keys+ can either be a
    # string holding the entire search string, or a single-dimension array of
    # search keywords and arguments.
    #
    # Returns a SearchResult object.  SearchResult inherits from Array (for
    # backward compatibility) but adds SearchResult#modseq when the +CONDSTORE+
    # capability has been enabled.
    #
    # Related: #uid_search
    #
    # ===== Search criteria
    #
    # For a full list of search criteria,
    # see [{IMAP4rev1 §6.4.4}[https://www.rfc-editor.org/rfc/rfc3501.html#section-6.4.4]],
    # or  [{IMAP4rev2 §6.4.4}[https://www.rfc-editor.org/rfc/rfc9051.html#section-6.4.4]],
    # in addition to documentation for
    # any [CAPABILITIES[https://www.iana.org/assignments/imap-capabilities/imap-capabilities.xhtml]]
    # reported by #capabilities which may define additional search filters, e.g:
    # +CONDSTORE+, +WITHIN+, +FILTERS+, <tt>SEARCH=FUZZY</tt>, +OBJECTID+, or
    # +SAVEDATE+.  The following are some common search criteria:
    #
    # <message set>:: a set of message sequence numbers.  "<tt>,</tt>" indicates
    #                 an interval, "+:+" indicates a range.  For instance,
    #                 "<tt>2,10:12,15</tt>" means "<tt>2,10,11,12,15</tt>".
    #
    # BEFORE <date>:: messages with an internal date strictly before
    #                 <b><date></b>.  The date argument has a format similar
    #                 to <tt>8-Aug-2002</tt>, and can be formatted using
    #                 Net::IMAP.format_date.
    #
    # BODY <string>:: messages that contain <string> within their body.
    #
    # CC <string>:: messages containing <string> in their CC field.
    #
    # FROM <string>:: messages that contain <string> in their FROM field.
    #
    # NEW:: messages with the \Recent, but not the \Seen, flag set.
    #
    # NOT <search-key>:: negate the following search key.
    #
    # OR <search-key> <search-key>:: "or" two search keys together.
    #
    # ON <date>:: messages with an internal date exactly equal to <date>,
    #             which has a format similar to 8-Aug-2002.
    #
    # SINCE <date>:: messages with an internal date on or after <date>.
    #
    # SUBJECT <string>:: messages with <string> in their subject.
    #
    # TO <string>:: messages with <string> in their TO field.
    #
    # ===== For example:
    #
    #   p imap.search(["SUBJECT", "hello", "NOT", "NEW"])
    #   #=> [1, 6, 7, 8]
    #
    # ===== Capabilities
    #
    # If [CONDSTORE[https://www.rfc-editor.org/rfc/rfc7162.html]] is supported
    # and enabled for the selected mailbox, a non-empty SearchResult will
    # include a +MODSEQ+ value.
    #   imap.select("mbox", condstore: true)
    #   result = imap.search(["SUBJECT", "hi there", "not", "new")
    #   #=> Net::IMAP::SearchResult[1, 6, 7, 8, modseq: 5594]
    #   result.modseq # => 5594
    def search(keys, charset = nil)
      return search_internal("SEARCH", keys, charset)
    end

    # Sends a {UID SEARCH command [IMAP4rev1 §6.4.8]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.8]
    # to search the mailbox for messages that match the given searching
    # criteria, and returns unique identifiers (<tt>UID</tt>s).
    #
    # Returns a SearchResult object.  SearchResult inherits from Array (for
    # backward compatibility) but adds SearchResult#modseq when the +CONDSTORE+
    # capability has been enabled.
    #
    # See #search for documentation of search criteria.
    def uid_search(keys, charset = nil)
      return search_internal("UID SEARCH", keys, charset)
    end

    # :call-seq:
    #   fetch(set, attr, changedsince: nil) -> array of FetchData
    #
    # Sends a {FETCH command [IMAP4rev1 §6.4.5]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.5]
    # to retrieve data associated with a message in the mailbox.
    #
    # The +set+ parameter is a number or a range between two numbers,
    # or an array of those.  The number is a message sequence number,
    # where -1 represents a '*' for use in range notation like 100..-1
    # being interpreted as '100:*'.  Beware that the +exclude_end?+
    # property of a Range object is ignored, and the contents of a
    # range are independent of the order of the range endpoints as per
    # the protocol specification, so 1...5, 5..1 and 5...1 are all
    # equivalent to 1..5.
    #
    # +attr+ is a list of attributes to fetch; see the documentation
    # for FetchData for a list of valid attributes.
    #
    # +changedsince+ is an optional integer mod-sequence.  It limits results to
    # messages with a mod-sequence greater than +changedsince+.
    #
    # The return value is an array of FetchData.
    #
    # Related: #uid_search, FetchData
    #
    # ===== For example:
    #
    #   p imap.fetch(6..8, "UID")
    #   #=> [#<Net::IMAP::FetchData seqno=6, attr={"UID"=>98}>, \\
    #        #<Net::IMAP::FetchData seqno=7, attr={"UID"=>99}>, \\
    #        #<Net::IMAP::FetchData seqno=8, attr={"UID"=>100}>]
    #   p imap.fetch(6, "BODY[HEADER.FIELDS (SUBJECT)]")
    #   #=> [#<Net::IMAP::FetchData seqno=6, attr={"BODY[HEADER.FIELDS (SUBJECT)]"=>"Subject: test\r\n\r\n"}>]
    #   data = imap.uid_fetch(98, ["RFC822.SIZE", "INTERNALDATE"])[0]
    #   p data.seqno
    #   #=> 6
    #   p data.attr["RFC822.SIZE"]
    #   #=> 611
    #   p data.attr["INTERNALDATE"]
    #   #=> "12-Oct-2000 22:40:59 +0900"
    #   p data.attr["UID"]
    #   #=> 98
    #
    # ===== Capabilities
    #
    # Many extensions define new message +attr+ names.  See FetchData for a list
    # of supported extension fields.
    #
    # The server's capabilities must include +CONDSTORE+
    # {[RFC7162]}[https://tools.ietf.org/html/rfc7162] in order to use the
    # +changedsince+ argument.  Using +changedsince+ implicitly enables the
    # +CONDSTORE+ extension.
    def fetch(set, attr, mod = nil, changedsince: nil)
      fetch_internal("FETCH", set, attr, mod, changedsince: changedsince)
    end

    # :call-seq:
    #   uid_fetch(set, attr, changedsince: nil) -> array of FetchData
    #
    # Sends a {UID FETCH command [IMAP4rev1 §6.4.8]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.8]
    # to retrieve data associated with a message in the mailbox.
    #
    # Similar to #fetch, but the +set+ parameter contains unique identifiers
    # instead of message sequence numbers.
    #
    # >>>
    #   *Note:* Servers _MUST_ implicitly include the +UID+ message data item as
    #   part of any +FETCH+ response caused by a +UID+ command, regardless of
    #   whether a +UID+ was specified as a message data item to the +FETCH+.
    #
    # Related: #fetch, FetchData
    #
    # ===== Capabilities
    # Same as #fetch.
    def uid_fetch(set, attr, mod = nil, changedsince: nil)
      fetch_internal("UID FETCH", set, attr, mod, changedsince: changedsince)
    end

    # :call-seq:
    #   store(set, attr, value, unchangedsince: nil) -> array of FetchData
    #
    # Sends a {STORE command [IMAP4rev1 §6.4.6]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.6]
    # to alter data associated with messages in the mailbox, in particular their
    # flags.
    #
    # +set+ is a number, an array of numbers, or a Range object.  Each number is
    # a message sequence number.
    #
    # +attr+ is the name of a data item to store.  The semantics of +value+
    # varies based on +attr+:
    # * When +attr+ is <tt>"FLAGS"</tt>, the flags in +value+ replace the
    #   message's flag list.
    # * When +attr+ is <tt>"+FLAGS"</tt>, the flags in +value+ are added to
    #   the flags for the message.
    # * When +attr+ is <tt>"-FLAGS"</tt>, the flags in +value+ are removed
    #   from the message.
    #
    # +unchangedsince+ is an optional integer mod-sequence.  It prohibits any
    # changes to messages with +mod-sequence+ greater than the specified
    # +unchangedsince+ value.  A SequenceSet of any messages that fail this
    # check will be returned in a +MODIFIED+ ResponseCode.
    #
    # The return value is an array of FetchData.
    #
    # Related: #uid_store
    #
    # ===== For example:
    #
    #   p imap.store(6..8, "+FLAGS", [:Deleted])
    #   #=> [#<Net::IMAP::FetchData seqno=6, attr={"FLAGS"=>[:Seen, :Deleted]}>,
    #        #<Net::IMAP::FetchData seqno=7, attr={"FLAGS"=>[:Seen, :Deleted]}>,
    #        #<Net::IMAP::FetchData seqno=8, attr={"FLAGS"=>[:Seen, :Deleted]}>]
    #
    # ===== Capabilities
    #
    # Extensions may define new data items to be used with #store.
    #
    # The server's capabilities must include +CONDSTORE+
    # {[RFC7162]}[https://tools.ietf.org/html/rfc7162] in order to use the
    # +unchangedsince+ argument.  Using +unchangedsince+ implicitly enables the
    # +CONDSTORE+ extension.
    def store(set, attr, flags, unchangedsince: nil)
      store_internal("STORE", set, attr, flags, unchangedsince: unchangedsince)
    end

    # :call-seq:
    #   uid_store(set, attr, value, unchangedsince: nil) -> array of FetchData
    #
    # Sends a {UID STORE command [IMAP4rev1 §6.4.8]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.8]
    # to alter data associated with messages in the mailbox, in particular their
    # flags.
    #
    # Similar to #store, but +set+ contains unique identifiers instead of
    # message sequence numbers.
    #
    # Related: #store
    #
    # ===== Capabilities
    # Same as #store.
    def uid_store(set, attr, flags, unchangedsince: nil)
      store_internal("UID STORE", set, attr, flags, unchangedsince: unchangedsince)
    end

    # Sends a {COPY command [IMAP4rev1 §6.4.7]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.7]
    # to copy the specified message(s) to the end of the specified destination
    # +mailbox+. The +set+ parameter is a number, an array of numbers, or a
    # Range object.  The number is a message sequence number.
    #
    # Related: #uid_copy
    #
    # ===== Capabilities
    #
    # If +UIDPLUS+ [RFC4315[https://www.rfc-editor.org/rfc/rfc4315.html]] is
    # supported, the server's response should include a +COPYUID+ response code
    # with UIDPlusData.  This will report the UIDVALIDITY of the destination
    # mailbox, the UID set of the source messages, and the assigned UID set of
    # the moved messages.
    def copy(set, mailbox)
      copy_internal("COPY", set, mailbox)
    end

    # Sends a {UID COPY command [IMAP4rev1 §6.4.8]}[https://www.rfc-editor.org/rfc/rfc3501#section-6.4.8]
    # to copy the specified message(s) to the end of the specified destination
    # +mailbox+.
    #
    # Similar to #copy, but +set+ contains unique identifiers.
    #
    # ===== Capabilities
    #
    # +UIDPLUS+ affects #uid_copy the same way it affects #copy.
    def uid_copy(set, mailbox)
      copy_internal("UID COPY", set, mailbox)
    end

    # Sends a {MOVE command [RFC6851 §3.1]}[https://www.rfc-editor.org/rfc/rfc6851#section-3.1]
    # {[IMAP4rev2 §6.4.8]}[https://www.rfc-editor.org/rfc/rfc9051#section-6.4.8]
    # to move the specified message(s) to the end of the specified destination
    # +mailbox+. The +set+ parameter is a number, an array of numbers, or a
    # Range object. The number is a message sequence number.
    #
    # Related: #uid_move
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +MOVE+
    # [RFC6851[https://tools.ietf.org/html/rfc6851]].
    #
    # If +UIDPLUS+ [RFC4315[https://www.rfc-editor.org/rfc/rfc4315.html]] is
    # supported, the server's response should include a +COPYUID+ response code
    # with UIDPlusData.  This will report the UIDVALIDITY of the destination
    # mailbox, the UID set of the source messages, and the assigned UID set of
    # the moved messages.
    #
    def move(set, mailbox)
      copy_internal("MOVE", set, mailbox)
    end

    # Sends a {UID MOVE command [RFC6851 §3.2]}[https://www.rfc-editor.org/rfc/rfc6851#section-3.2]
    # {[IMAP4rev2 §6.4.9]}[https://www.rfc-editor.org/rfc/rfc9051#section-6.4.9]
    # to move the specified message(s) to the end of the specified destination
    # +mailbox+.
    #
    # Similar to #move, but +set+ contains unique identifiers.
    #
    # Related: #move
    #
    # ===== Capabilities
    #
    # Same as #move: The server's capabilities must include +MOVE+
    # [RFC6851[https://tools.ietf.org/html/rfc6851]].  +UIDPLUS+ also affects
    # #uid_move the same way it affects #move.
    def uid_move(set, mailbox)
      copy_internal("UID MOVE", set, mailbox)
    end

    # Sends a {SORT command [RFC5256 §3]}[https://www.rfc-editor.org/rfc/rfc5256#section-3]
    # to search a mailbox for messages that match +search_keys+ and return an
    # array of message sequence numbers, sorted by +sort_keys+.  +search_keys+
    # are interpreted the same as for #search.
    #
    #--
    # TODO: describe +sort_keys+
    #++
    #
    # Related: #uid_sort, #search, #uid_search, #thread, #uid_thread
    #
    # ===== For example:
    #
    #   p imap.sort(["FROM"], ["ALL"], "US-ASCII")
    #   #=> [1, 2, 3, 5, 6, 7, 8, 4, 9]
    #   p imap.sort(["DATE"], ["SUBJECT", "hello"], "US-ASCII")
    #   #=> [6, 7, 8, 1]
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +SORT+
    # [RFC5256[https://tools.ietf.org/html/rfc5256]].
    def sort(sort_keys, search_keys, charset)
      return sort_internal("SORT", sort_keys, search_keys, charset)
    end

    # Sends a {UID SORT command [RFC5256 §3]}[https://www.rfc-editor.org/rfc/rfc5256#section-3]
    # to search a mailbox for messages that match +search_keys+ and return an
    # array of unique identifiers, sorted by +sort_keys+.  +search_keys+ are
    # interpreted the same as for #search.
    #
    # Related: #sort, #search, #uid_search, #thread, #uid_thread
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +SORT+
    # [RFC5256[https://tools.ietf.org/html/rfc5256]].
    def uid_sort(sort_keys, search_keys, charset)
      return sort_internal("UID SORT", sort_keys, search_keys, charset)
    end

    # Sends a {THREAD command [RFC5256 §3]}[https://www.rfc-editor.org/rfc/rfc5256#section-3]
    # to search a mailbox and return message sequence numbers in threaded
    # format, as a ThreadMember tree.  +search_keys+ are interpreted the same as
    # for #search.
    #
    # The supported algorithms are:
    #
    # ORDEREDSUBJECT:: split into single-level threads according to subject,
    #                  ordered by date.
    # REFERENCES:: split into threads by parent/child relationships determined
    #              by which message is a reply to which.
    #
    # Unlike #search, +charset+ is a required argument.  US-ASCII
    # and UTF-8 are sample values.
    #
    # Related: #uid_thread, #search, #uid_search, #sort, #uid_sort
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +THREAD+
    # [RFC5256[https://tools.ietf.org/html/rfc5256]].
    def thread(algorithm, search_keys, charset)
      return thread_internal("THREAD", algorithm, search_keys, charset)
    end

    # Sends a {UID THREAD command [RFC5256 §3]}[https://www.rfc-editor.org/rfc/rfc5256#section-3]
    # Similar to #thread, but returns unique identifiers instead of
    # message sequence numbers.
    #
    # Related: #thread, #search, #uid_search, #sort, #uid_sort
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +THREAD+
    # [RFC5256[https://tools.ietf.org/html/rfc5256]].
    def uid_thread(algorithm, search_keys, charset)
      return thread_internal("UID THREAD", algorithm, search_keys, charset)
    end

    # Sends an {ENABLE command [RFC5161 §3.2]}[https://www.rfc-editor.org/rfc/rfc5161#section-3.1]
    # {[IMAP4rev2 §6.3.1]}[https://www.rfc-editor.org/rfc/rfc9051#section-6.3.1]
    # to enable the specified server +capabilities+.  Each capability may be an
    # array, string, or symbol.  Returns a list of the capabilities that were
    # enabled.
    #
    # The +ENABLE+ command is only valid in the _authenticated_ state, before
    # any mailbox is selected.
    #
    # Related: #capable?, #capabilities, #capability
    #
    # ===== Capabilities
    #
    # The server's capabilities must include
    # +ENABLE+ [RFC5161[https://tools.ietf.org/html/rfc5161]]
    # or +IMAP4REV2+ [RFC9051[https://tools.ietf.org/html/rfc9051]].
    #
    # Additionally, the server capabilities must include a capability matching
    # each enabled extension (usually the same name as the enabled extension).
    # The following capabilities may be enabled:
    #
    # [+CONDSTORE+ {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html]]
    #
    #   Updates various commands to return +CONDSTORE+ extension responses.  It
    #   is not necessary to explicitly enable +CONDSTORE+—using any of the
    #   command parameters defined by the extension will implicitly enable it.
    #   See {[RFC7162 §3.1]}[https://www.rfc-editor.org/rfc/rfc7162.html#section-3.1].
    #
    # [+:utf8+ --- an alias for <tt>"UTF8=ACCEPT"</tt>]
    #
    #   In a future release, <tt>enable(:utf8)</tt> will enable either
    #   <tt>"UTF8=ACCEPT"</tt> or <tt>"IMAP4rev2"</tt>, depending on server
    #   capabilities.
    #
    # [<tt>"UTF8=ACCEPT"</tt> [RFC6855[https://tools.ietf.org/html/rfc6855]]]
    #
    #   The server's capabilities must include <tt>UTF8=ACCEPT</tt> _or_
    #   <tt>UTF8=ONLY</tt>.
    #
    #   This allows the server to send strings encoded as UTF-8 which might
    #   otherwise need to use a 7-bit encoding, such as {modified
    #   UTF-7}[::decode_utf7] for mailbox names, or RFC2047 encoded-words for
    #   message headers.
    #
    #   *Note:* <em>A future update may set string encodings slightly
    #   differently</em>, e.g: "US-ASCII" when UTF-8 is not enabled, and "UTF-8"
    #   when it is.  Currently, the encoding of strings sent as "quoted" or
    #   "text" will _always_ be "UTF-8", even when only ASCII characters are
    #   used (e.g. "Subject: Agenda") And currently, string "literals" sent
    #   by the server will always have an "ASCII-8BIT" (binary)
    #   encoding, even if they generally contain UTF-8 data, if they are
    #   text at all.
    #
    # [<tt>"UTF8=ONLY"</tt> [RFC6855[https://tools.ietf.org/html/rfc6855]]]
    #
    #   A server that reports the <tt>UTF8=ONLY</tt> capability _requires_ that
    #   the client <tt>enable("UTF8=ACCEPT")</tt> before any mailboxes may be
    #   selected.  For convenience, <tt>enable("UTF8=ONLY")</tt> is aliased to
    #   <tt>enable("UTF8=ACCEPT")</tt>.
    #
    # ===== Unsupported capabilities
    #
    # *Note:* Some extensions that use ENABLE permit the server to send syntax
    # that Net::IMAP cannot parse, which may raise an exception and disconnect.
    # Some extensions may work, but the support may be incomplete, untested, or
    # experimental.
    #
    # Until a capability is documented here as supported, enabling it may result
    # in undocumented behavior and a future release may update with incompatible
    # behavior <em>without warning or deprecation</em>.
    #
    # <em>Caution is advised.</em>
    #
    def enable(*capabilities)
      capabilities = capabilities
        .flatten
        .map {|e| ENABLE_ALIASES[e] || e }
        .uniq
        .join(' ')
      synchronize do
        send_command("ENABLE #{capabilities}")
        result = clear_responses("ENABLED").last || []
        @utf8_strings ||= result.include? "UTF8=ACCEPT"
        @utf8_strings ||= result.include? "IMAP4REV2"
        result
      end
    end

    # Sends an {IDLE command [RFC2177 §3]}[https://www.rfc-editor.org/rfc/rfc6851#section-3]
    # {[IMAP4rev2 §6.3.13]}[https://www.rfc-editor.org/rfc/rfc9051#section-6.3.13]
    # that waits for notifications of new or expunged messages.  Yields
    # responses from the server during the IDLE.
    #
    # Use #idle_done to leave IDLE.
    #
    # If +timeout+ is given, this method returns after +timeout+ seconds passed.
    # +timeout+ can be used for keep-alive.  For example, the following code
    # checks the connection for each 60 seconds.
    #
    #   loop do
    #     imap.idle(60) do |response|
    #       do_something_with(response)
    #       imap.idle_done if some_condition?(response)
    #     end
    #   end
    #
    # Returns the server's response to indicate the IDLE state has ended.
    # Returns +nil+ if the server does not respond to #idle_done within
    # {config.idle_response_timeout}[rdoc-ref:Config#idle_response_timeout]
    # seconds.
    #
    # Related: #idle_done, #noop, #check
    #
    # ===== Capabilities
    #
    # The server's capabilities must include +IDLE+
    # [RFC2177[https://tools.ietf.org/html/rfc2177]].
    def idle(timeout = nil, &response_handler)
      raise LocalJumpError, "no block given" unless response_handler

      response = nil

      synchronize do
        tag = Thread.current[:net_imap_tag] = generate_tag
        put_string("#{tag} IDLE#{CRLF}")

        begin
          add_response_handler(&response_handler)
          @idle_done_cond = new_cond
          @idle_done_cond.wait(timeout)
          @idle_done_cond = nil
          if @receiver_thread_terminating
            raise @exception || Net::IMAP::Error.new("connection closed")
          end
        ensure
          unless @receiver_thread_terminating
            remove_response_handler(response_handler)
            put_string("DONE#{CRLF}")
            response = get_tagged_response(tag, "IDLE", idle_response_timeout)
          end
        end
      end

      return response
    end

    # Leaves IDLE, allowing #idle to return.
    #
    # If the server does not respond within
    # {config.idle_response_timeout}[rdoc-ref:Config#idle_response_timeout]
    # seconds, #idle will return +nil+.
    #
    # Related: #idle
    def idle_done
      synchronize do
        if @idle_done_cond.nil?
          raise Net::IMAP::Error, "not during IDLE"
        end
        @idle_done_cond.signal
      end
    end

    RESPONSES_DEPRECATION_MSG =
      "Pass a type or block to #responses, " \
      "set config.responses_without_block to :frozen_dup " \
      "or :silence_deprecation_warning, " \
      "or use #extract_responses or #clear_responses."
    private_constant :RESPONSES_DEPRECATION_MSG

    # :call-seq:
    #   responses       -> hash of {String => Array} (see config.responses_without_block)
    #   responses(type) -> frozen array
    #   responses       {|hash|  ...} -> block result
    #   responses(type) {|array| ...} -> block result
    #
    # Yields or returns unhandled server responses.  Unhandled responses are
    # stored in a hash, with arrays of UntaggedResponse#data keyed by
    # UntaggedResponse#name and <em>non-+nil+</em> untagged ResponseCode#data
    # keyed by ResponseCode#name.
    #
    # When a block is given, yields unhandled responses and returns the block's
    # result.  Without a block, returns the unhandled responses.
    #
    # [With +type+]
    #   Yield or return only the array of responses for that +type+.
    #   When no block is given, the returned array is a frozen copy.
    # [Without +type+]
    #   Yield or return the entire responses hash.
    #
    #   When no block is given, the behavior is determined by
    #   Config#responses_without_block:
    #   >>>
    #     [+:silence_deprecation_warning+ <em>(original behavior)</em>]
    #       Returns the mutable responses hash (without any warnings).
    #       <em>This is not thread-safe.</em>
    #
    #     [+:warn+ <em>(default since +v0.5+)</em>]
    #       Prints a warning and returns the mutable responses hash.
    #       <em>This is not thread-safe.</em>
    #
    #     [+:frozen_dup+ <em>(planned default for +v0.6+)</em>]
    #       Returns a frozen copy of the unhandled responses hash, with frozen
    #       array values.
    #
    #     [+:raise+]
    #       Raise an +ArgumentError+ with the deprecation warning.
    #
    # For example:
    #
    #   imap.select("inbox")
    #   p imap.responses("EXISTS").last
    #   #=> 2
    #   p imap.responses("UIDNEXT", &:last)
    #   #=> 123456
    #   p imap.responses("UIDVALIDITY", &:last)
    #   #=> 968263756
    #   p imap.responses {|responses|
    #     {
    #       exists:      responses.delete("EXISTS").last,
    #       uidnext:     responses.delete("UIDNEXT").last,
    #       uidvalidity: responses.delete("UIDVALIDITY").last,
    #     }
    #   }
    #   #=> {:exists=>2, :uidnext=>123456, :uidvalidity=>968263756}
    #   # "EXISTS", "UIDNEXT", and "UIDVALIDITY" have been removed:
    #   p imap.responses(&:keys)
    #   #=> ["FLAGS", "OK", "PERMANENTFLAGS", "RECENT", "HIGHESTMODSEQ"]
    #
    # Related: #extract_responses, #clear_responses, #response_handlers, #greeting
    #
    # ===== Thread safety
    # >>>
    #   *Note:* Access to the responses hash is synchronized for thread-safety.
    #   The receiver thread and response_handlers cannot process new responses
    #   until the block completes.  Accessing either the response hash or its
    #   response type arrays outside of the block is unsafe.  They can be safely
    #   updated inside the block.  Consider using #clear_responses or
    #   #extract_responses instead.
    #
    #   Net::IMAP will add and remove responses from the responses hash and its
    #   array values, in the calling threads for commands and in the receiver
    #   thread, but will not modify any responses after adding them to the
    #   responses hash.
    #
    # ===== Clearing responses
    #
    # Previously unhandled responses are automatically cleared before entering a
    # mailbox with #select or #examine.  Long-lived connections can receive many
    # unhandled server responses, which must be pruned or they will continually
    # consume more memory.  Update or clear the responses hash or arrays inside
    # the block, or remove responses with #extract_responses, #clear_responses,
    # or #add_response_handler.
    #
    # ===== Missing responses
    #
    # Only non-+nil+ data is stored.  Many important response codes have no data
    # of their own, but are used as "tags" on the ResponseText object they are
    # attached to.  ResponseText will be accessible by its response types:
    # "+OK+", "+NO+", "+BAD+", "+BYE+", or "+PREAUTH+".
    #
    # TaggedResponse#data is not saved to #responses, nor is any
    # ResponseCode#data on tagged responses.  Although some command methods do
    # return the TaggedResponse directly, #add_response_handler must be used to
    # handle all response codes.
    def responses(type = nil)
      if block_given?
        synchronize { yield(type ? @responses[type.to_s.upcase] : @responses) }
      elsif type
        synchronize { @responses[type.to_s.upcase].dup.freeze }
      else
        case config.responses_without_block
        when :raise
          raise ArgumentError, RESPONSES_DEPRECATION_MSG
        when :warn
          warn(RESPONSES_DEPRECATION_MSG, uplevel: 1)
        when :frozen_dup
          synchronize {
            responses = @responses.transform_values(&:freeze)
            responses.default_proc = nil
            responses.default = [].freeze
            return responses.freeze
          }
        end
        @responses
      end
    end

    # :call-seq:
    #   clear_responses       -> hash
    #   clear_responses(type) -> array
    #
    # Clears and returns the unhandled #responses hash or the unhandled
    # responses array for a single response +type+.
    #
    # Clearing responses is synchronized with other threads.  The lock is
    # released before returning.
    #
    # Related: #extract_responses, #responses, #response_handlers
    def clear_responses(type = nil)
      synchronize {
        if type
          @responses.delete(type) || []
        else
          @responses.dup.transform_values(&:freeze)
            .tap { _1.default = [].freeze }
            .tap { @responses.clear }
        end
      }
        .freeze
    end

    # :call-seq:
    #   extract_responses(type) {|response| ... } -> array
    #
    # Yields all of the unhandled #responses for a single response +type+.
    # Removes and returns the responses for which the block returns a true
    # value.
    #
    # Extracting responses is synchronized with other threads.  The lock is
    # released before returning.
    #
    # Related: #responses, #clear_responses
    def extract_responses(type)
      type = String.try_convert(type) or
        raise ArgumentError, "type must be a string"
      raise ArgumentError, "must provide a block" unless block_given?
      extracted = []
      responses(type) do |all|
        all.reject! do |response|
          extracted << response if yield response
        end
      end
      extracted
    end

    # Returns all response handlers, including those that are added internally
    # by commands.  Each response handler will be called with every new
    # UntaggedResponse, TaggedResponse, and ContinuationRequest.
    #
    # Response handlers are called with a mutex inside the receiver thread.  New
    # responses cannot be processed and commands from other threads must wait
    # until all response_handlers return.  An exception will shut-down the
    # receiver thread and close the connection.
    #
    # For thread-safety, the returned array is a frozen copy of the internal
    # array.
    #
    # Related: #add_response_handler, #remove_response_handler
    def response_handlers
      synchronize { @response_handlers.clone.freeze }
    end

    # Adds a response handler. For example, to detect when
    # the server sends a new EXISTS response (which normally
    # indicates new messages being added to the mailbox),
    # add the following handler after selecting the
    # mailbox:
    #
    #   imap.add_response_handler { |resp|
    #     if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
    #       puts "Mailbox now has #{resp.data} messages"
    #     end
    #   }
    #
    # Response handlers can also be added when the client is created before the
    # receiver thread is started, by the +response_handlers+ argument to ::new.
    # This ensures every server response is handled, including the #greeting.
    #
    # Related: #remove_response_handler, #response_handlers
    def add_response_handler(handler = nil, &block)
      raise ArgumentError, "two Procs are passed" if handler && block
      synchronize do
        @response_handlers.push(block || handler)
      end
    end

    # Removes the response handler.
    #
    # Related: #add_response_handler, #response_handlers
    def remove_response_handler(handler)
      synchronize do
        @response_handlers.delete(handler)
      end
    end

    private

    CRLF = "\r\n"      # :nodoc:
    PORT = 143         # :nodoc:
    SSL_PORT = 993   # :nodoc:

    def start_imap_connection
      @greeting        = get_server_greeting
      @capabilities    = capabilities_from_resp_code @greeting
      @response_handlers.each do |handler| handler.call(@greeting) end
      @receiver_thread = start_receiver_thread
    rescue Exception
      @sock.close
      raise
    end

    def get_server_greeting
      greeting = get_response
      raise Error, "No server greeting - connection closed" unless greeting
      record_untagged_response_code greeting
      raise ByeResponseError, greeting if greeting.name == "BYE"
      greeting
    end

    def start_receiver_thread
      Thread.start do
        receive_responses
      rescue Exception => ex
        @receiver_thread_exception = ex
        # don't exit the thread with an exception
      end
    end

    def tcp_socket(host, port)
      s = Socket.tcp(host, port, :connect_timeout => open_timeout)
      s.setsockopt(:SOL_SOCKET, :SO_KEEPALIVE, true)
      s
    rescue Errno::ETIMEDOUT
      raise Net::OpenTimeout, "Timeout to open TCP connection to " +
        "#{host}:#{port} (exceeds #{open_timeout} seconds)"
    end

    def receive_responses
      connection_closed = false
      until connection_closed
        synchronize do
          @exception = nil
        end
        begin
          resp = get_response
        rescue Exception => e
          synchronize do
            @sock.close
            @exception = e
          end
          break
        end
        unless resp
          synchronize do
            @exception = EOFError.new("end of file reached")
          end
          break
        end
        begin
          synchronize do
            case resp
            when TaggedResponse
              @tagged_responses[resp.tag] = resp
              @tagged_response_arrival.broadcast
              case resp.tag
              when @logout_command_tag
                return
              when @continued_command_tag
                @continuation_request_exception =
                  RESPONSE_ERRORS[resp.name].new(resp)
                @continuation_request_arrival.signal
              end
            when UntaggedResponse
              record_untagged_response(resp)
              if resp.name == "BYE" && @logout_command_tag.nil?
                @sock.close
                @exception = ByeResponseError.new(resp)
                connection_closed = true
              end
            when ContinuationRequest
              @continuation_request_arrival.signal
            end
            @response_handlers.each do |handler|
              handler.call(resp)
            end
          end
        rescue Exception => e
          @exception = e
          synchronize do
            @tagged_response_arrival.broadcast
            @continuation_request_arrival.broadcast
          end
        end
      end
      synchronize do
        @receiver_thread_terminating = true
        @tagged_response_arrival.broadcast
        @continuation_request_arrival.broadcast
        if @idle_done_cond
          @idle_done_cond.signal
        end
      end
    end

    def get_tagged_response(tag, cmd, timeout = nil)
      if timeout
        deadline = Time.now + timeout
      end
      until @tagged_responses.key?(tag)
        raise @exception if @exception
        if timeout
          timeout = deadline - Time.now
          if timeout <= 0
            return nil
          end
        end
        @tagged_response_arrival.wait(timeout)
      end
      resp = @tagged_responses.delete(tag)
      case resp.name
      when /\A(?:OK)\z/ni
        return resp
      when /\A(?:NO)\z/ni
        raise NoResponseError, resp
      when /\A(?:BAD)\z/ni
        raise BadResponseError, resp
      else
        disconnect
        raise InvalidResponseError, "invalid tagged resp: %p" % [resp.raw.chomp]
      end
    end

    def get_response
      buff = @reader.read_response_buffer
      return nil if buff.length == 0
      $stderr.print(buff.gsub(/^/n, "S: ")) if config.debug?
      @parser.parse(buff)
    end

    #############################
    # built-in response handlers

    # store name => [..., data]
    def record_untagged_response(resp)
      @responses[resp.name] << resp.data
      record_untagged_response_code resp
    end

    # store code.name => [..., code.data]
    def record_untagged_response_code(resp)
      return unless resp.data.is_a?(ResponseText)
      return unless (code = resp.data.code)
      @responses[code.name] << code.data
    end

    # NOTE: only call this for greeting, login, and authenticate
    def capabilities_from_resp_code(resp)
      return unless %w[PREAUTH OK].any? { _1.casecmp? resp.name }
      return unless (code = resp.data.code)
      return unless code.name.casecmp?("CAPABILITY")
      code.data.freeze
    end

    #############################

    # Calls send_command, yielding the text of each ContinuationRequest and
    # responding with each block result.  Returns TaggedResponse.  Raises
    # NoResponseError or BadResponseError.
    def send_command_with_continuations(cmd, *args)
      send_command(cmd, *args) do |server_response|
        if server_response.instance_of?(ContinuationRequest)
          client_response = yield server_response.data.text
          put_string(client_response + CRLF)
        end
      end
    end

    def send_command(cmd, *args, &block)
      synchronize do
        args.each do |i|
          validate_data(i)
        end
        tag = generate_tag
        put_string(tag + " " + cmd)
        args.each do |i|
          put_string(" ")
          send_data(i, tag)
        end
        put_string(CRLF)
        if cmd == "LOGOUT"
          @logout_command_tag = tag
        end
        if block
          add_response_handler(&block)
        end
        begin
          return get_tagged_response(tag, cmd)
        ensure
          if block
            remove_response_handler(block)
          end
        end
      end
    end

    def generate_tag
      @tagno += 1
      return format("%s%04d", @tag_prefix, @tagno)
    end

    def put_string(str)
      @sock.print(str)
      if config.debug?
        if @debug_output_bol
          $stderr.print("C: ")
        end
        $stderr.print(str.gsub(/\n/n) { $'.empty? ? $& : "\nC: " })
        if /\n\z/n.match(str)
          @debug_output_bol = true
        else
          @debug_output_bol = false
        end
      end
    end

    def search_internal(cmd, keys, charset)
      if keys.instance_of?(String)
        keys = [RawData.new(keys)]
      else
        normalize_searching_criteria(keys)
      end
      synchronize do
        if charset
          send_command(cmd, "CHARSET", charset, *keys)
        else
          send_command(cmd, *keys)
        end
        clear_responses("SEARCH").last || []
      end
    end

    def fetch_internal(cmd, set, attr, mod = nil, changedsince: nil)
      if changedsince
        mod ||= []
        mod << "CHANGEDSINCE" << Integer(changedsince)
      end
      case attr
      when String then
        attr = RawData.new(attr)
      when Array then
        attr = attr.map { |arg|
          arg.is_a?(String) ? RawData.new(arg) : arg
        }
      end

      synchronize do
        clear_responses("FETCH")
        if mod
          send_command(cmd, MessageSet.new(set), attr, mod)
        else
          send_command(cmd, MessageSet.new(set), attr)
        end
        clear_responses("FETCH")
      end
    end

    def store_internal(cmd, set, attr, flags, unchangedsince: nil)
      attr = RawData.new(attr) if attr.instance_of?(String)
      args = [MessageSet.new(set)]
      args << ["UNCHANGEDSINCE", Integer(unchangedsince)] if unchangedsince
      args << attr << flags
      synchronize do
        clear_responses("FETCH")
        send_command(cmd, *args)
        clear_responses("FETCH")
      end
    end

    def copy_internal(cmd, set, mailbox)
      send_command(cmd, MessageSet.new(set), mailbox)
    end

    def sort_internal(cmd, sort_keys, search_keys, charset)
      if search_keys.instance_of?(String)
        search_keys = [RawData.new(search_keys)]
      else
        normalize_searching_criteria(search_keys)
      end
      synchronize do
        send_command(cmd, sort_keys, charset, *search_keys)
        clear_responses("SORT").last || []
      end
    end

    def thread_internal(cmd, algorithm, search_keys, charset)
      if search_keys.instance_of?(String)
        search_keys = [RawData.new(search_keys)]
      else
        normalize_searching_criteria(search_keys)
      end
      synchronize do
        send_command(cmd, algorithm, charset, *search_keys)
        clear_responses("THREAD").last || []
      end
    end

    def normalize_searching_criteria(keys)
      keys.collect! do |i|
        case i
        when -1, Range, Array
          MessageSet.new(i)
        else
          i
        end
      end
    end

    def build_ssl_ctx(ssl)
      if ssl
        params = (Hash.try_convert(ssl) || {}).freeze
        context = SSLContext.new
        context.set_params(params)
        if defined?(VerifyCallbackProc)
          context.verify_callback = VerifyCallbackProc
        end
        context.freeze
        [params, context]
      else
        false
      end
    end

    def start_tls_session
      raise "SSL extension not installed" unless defined?(OpenSSL::SSL)
      raise "already using SSL" if @sock.kind_of?(OpenSSL::SSL::SSLSocket)
      raise "cannot start TLS without SSLContext" unless ssl_ctx
      @sock = SSLSocket.new(@sock, ssl_ctx)
      @reader = ResponseReader.new(self, @sock)
      @sock.sync_close = true
      @sock.hostname = @host if @sock.respond_to? :hostname=
      ssl_socket_connect(@sock, open_timeout)
      if ssl_ctx.verify_mode != VERIFY_NONE
        @sock.post_connection_check(@host)
        @tls_verified = true
      end
    end

    def sasl_adapter
      SASLAdapter.new(self, &method(:send_command_with_continuations))
    end

    #--
    # We could get the saslprep method by extending the SASLprep module
    # directly.  It's done indirectly, so SASLprep can be lazily autoloaded,
    # because most users won't need it.
    #++
    # Delegates to Net::IMAP::StringPrep::SASLprep#saslprep.
    def self.saslprep(string, **opts)
      Net::IMAP::StringPrep::SASLprep.saslprep(string, **opts)
    end

  end
end

require_relative "imap/errors"
require_relative "imap/config"
require_relative "imap/command_data"
require_relative "imap/data_encoding"
require_relative "imap/flags"
require_relative "imap/response_data"
require_relative "imap/response_parser"
require_relative "imap/authenticators"

require_relative "imap/deprecated_client_options"
Net::IMAP.prepend Net::IMAP::DeprecatedClientOptions
