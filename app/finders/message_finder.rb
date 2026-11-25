class MessageFinder
  PAGE_LIMIT = 20

  # `messages.content_attributes` is `json` but the model stores it as a
  # double-encoded string (legacy `store coder: JSON`), so `->>` can't traverse
  # it directly — `#>>'{}'` unwraps the outer encoding into proper jsonb.
  NON_REACTION_CLAUSE = "((content_attributes#>>'{}')::jsonb->>'is_reaction') IS DISTINCT FROM 'true'".freeze

  MESSAGE_ID_MAX = 2_147_483_647

  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def conversation_messages
    @conversation.messages.includes(:attachments, :sender, sender: { avatar_attachment: [:blob] })
  end

  def messages
    return conversation_messages if @params[:filter_internal_messages].blank?

    conversation_messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def current_messages
    return messages.none if oversized_message_id?(@params[:after])

    if @params[:after].present? && @params[:before].present?
      messages_between(normalized_message_id(@params[:after]), @params[:before].to_i)
    elsif @params[:before].present?
      messages_before(@params[:before].to_i)
    elsif @params[:after].present?
      messages_after(normalized_message_id(@params[:after]))
    else
      messages_latest
    end
  end

  CATCH_UP_LIMIT = 100

  # Deliberately still by id, unlike `before_cursor`. This one answers "what has been
  # written since I last looked", which is a question about the sequence and not about
  # time: a client catching up has to be told about a backdated message imported a moment
  # ago, and comparing timestamps is exactly what would hide it.
  #
  # Which is also why the order is by id and not by time. The filter, the order and the
  # limit have to agree, or the limit cuts a different set than the filter chose: ordering
  # by `created_at` handed back the hundred oldest by time, which for a thread carrying
  # backdated rows is not the hundred lowest ids, and the ones it left out sat above the
  # cursor the client then moved past. The client sorts by time before rendering either
  # way, so the order here is the cursor's, not the reader's.
  def messages_after(after_id)
    messages.reorder('id asc').where('id > ?', after_id).limit(CATCH_UP_LIMIT)
  end

  def messages_before(before_id)
    return messages_latest if oversized_message_id?(before_id)

    page_window(before_cursor(normalized_message_id(before_id)))
  end

  def messages_between(after_id, before_id)
    message_scope = messages.reorder('created_at asc').where('id >= ?', after_id)
    message_scope = message_scope.merge(before_cursor(normalized_message_id(before_id))) unless oversized_message_id?(before_id)
    message_scope.limit(1000)
  end

  # Everything strictly earlier in the conversation than the cursor message.
  #
  # The cursor is an id, but "earlier" is a question about time, and the two only agree
  # while ids are handed out in the order messages happened. Imported history breaks that
  # by construction: the id comes from the sequence at INSERT and the timestamp is
  # backdated to when the message was sent, so one delivered late carries a newer id and
  # an older timestamp. An `id <` filter drops it from every page, permanently, including
  # the ones reached by scrolling up. Measured on the first imported inbox: 167 of 951
  # messages were unreachable that way, across 18 of 95 conversations.
  #
  # Comparing the pair puts this filter on the axis `page_window` has always ordered by,
  # with the id as the tiebreak that keeps the cursor stable when two messages share a
  # second (WhatsApp timestamps are second-resolution, and a burst lands inside one).
  # Where ids do follow chronology the two predicates select exactly the same rows, so a
  # conversation that never imported anything sees no change at all.
  def before_cursor(before_id)
    at = cursor_timestamp(before_id)
    return messages.where('messages.id < ?', before_id) if at.nil?

    messages.where('(messages.created_at, messages.id) < (?, ?)', at, before_id)
  end

  # Queried off the bare relation: `messages` carries the `includes` this finder needs for
  # rendering, and Rails would try to eager-load the polymorphic sender for a one-column
  # read. A cursor naming a message from another conversation has no timestamp to compare
  # against, which is the one case that keeps the id-only filter.
  def cursor_timestamp(message_id)
    Message.where(conversation_id: @conversation.id, id: message_id).pick(:created_at)
  end

  def messages_latest
    page_window(messages)
  end

  # Reactions don't count toward the page limit — otherwise a heavily-reacted
  # message can flood the latest page and hide regular messages from the UI on
  # initial load. Pick the most recent non-reactions, then add only the
  # reactions whose target is inside that window so chips render alongside
  # their parents and orphan reactions on older messages don't bloat the page.
  #
  # Ordered by the same pair `before_cursor` compares, and that agreement is the whole
  # point rather than a detail of presentation: this picks which rows the page shows and
  # the cursor decides what the next page starts below, so the two have to rank ties the
  # same way. Ordering here by time alone let Postgres choose freely among rows sharing a
  # second, and any tied row it happened to leave out with an id above the cursor's was
  # then excluded by the cursor as well — present in the conversation, absent from every
  # page, with nothing on screen to say so. Second-resolution WhatsApp timestamps and
  # backdated history imports are what put more than a page of rows inside one second.
  def page_window(scope)
    # Drop `includes(:sender, ...)` for the id-only probe to avoid Rails trying
    # to eager-load the polymorphic sender association (which would error).
    # `minimum(:id)` would silently aggregate over the FULL relation (Rails
    # drops the limit), pulling in old messages and blowing up the page. Pluck
    # the limited window first and take the min in Ruby.
    bare = scope.except(:includes)
    window_ids = bare.where(NON_REACTION_CLAUSE).reorder('created_at desc, id desc').limit(PAGE_LIMIT).pluck(:id)
    return scope.none if window_ids.empty?

    json_path = "(content_attributes#>>'{}')::jsonb"
    # `Message#ensure_in_reply_to` always populates content_attributes['in_reply_to']
    # when either the internal id or external source_id resolves to a parent in the
    # same conversation, so a single jsonb path scopes reactions to the windowed
    # parents reliably.
    reaction_in_window = "((#{json_path}->>'is_reaction') = 'true' AND " \
                         "(#{json_path}->>'in_reply_to')::bigint IN (:ids))"
    scope.where("id IN (:ids) OR #{reaction_in_window}", ids: window_ids)
         .reorder('created_at asc, id asc')
  end

  def normalized_message_id(value)
    value.to_i.clamp(0, MESSAGE_ID_MAX)
  end

  def oversized_message_id?(value)
    value.to_i > MESSAGE_ID_MAX
  end
end

MessageFinder.prepend_mod_with('MessageFinder')
