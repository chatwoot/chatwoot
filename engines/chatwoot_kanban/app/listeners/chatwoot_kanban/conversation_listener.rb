module ChatwootKanban
  # Listens to Chatwoot conversation events.
  #
  # Hook this up in config/initializers/chatwoot_kanban.rb on the host:
  #
  #   Rails.configuration.dispatcher.attach_listener(
  #     ChatwootKanban::ConversationListener.instance
  #   )
  #
  # The listener is idempotent and a no-op for accounts without an auto-create
  # board configured.
  class ConversationListener < ::BaseListener
    include Singleton

    # Triggered by Chatwoot when a new conversation lands.
    def conversation_created(event)
      conversation = extract_conversation(event)
      return unless conversation

      account = conversation.account
      board   = auto_create_board_for(account)
      return unless board

      first_column = board.columns.ordered.first
      return unless first_column

      next_position = (first_column.cards.maximum(:position) || -1) + 1
      card = first_column.cards.create!(
        title:           conversation_title(conversation),
        description:     conversation_excerpt(conversation),
        position:        next_position,
        priority:        derive_priority(conversation),
        conversation_id: conversation.id,
        metadata:        { auto_created: true }
      )

      card.activities.create!(action: 'created',
                              payload: { auto_created_from_conversation_id: conversation.id })

      ChatwootKanban::BroadcastService.broadcast(
        board: board,
        event: :card_created,
        payload: { card_id: card.id, column_id: first_column.id }
      )
    rescue StandardError => e
      Rails.logger.warn("[ChatwootKanban] auto-create failed: #{e.message}")
    end

    # Triggered when conversation is resolved/reopened.
    def conversation_status_changed(event)
      conversation = extract_conversation(event)
      return unless conversation

      linked_card = ChatwootKanban::Card.active.find_by(conversation_id: conversation.id)
      return unless linked_card

      board    = linked_card.board
      done_ids = Array(board.settings['done_column_ids']).map(&:to_i)
      target   = if conversation.resolved? && done_ids.any?
                   ChatwootKanban::Column.where(id: done_ids, board_id: board.id).first
                 end
      return unless target
      return if linked_card.column_id == target.id

      MoveCardService.new(
        card:         linked_card,
        to_column_id: target.id,
        position:     (target.cards.maximum(:position) || -1) + 1,
        actor:        nil
      ).call
    rescue StandardError => e
      Rails.logger.warn("[ChatwootKanban] status sync failed: #{e.message}")
    end

    private

    def extract_conversation(event)
      return event.data[:conversation] if event.respond_to?(:data) && event.data.is_a?(Hash)
      return event[:conversation]      if event.is_a?(Hash)

      nil
    end

    # Look up the board flagged as the auto-create destination via
    # board.settings['auto_create_from_conversations'] == true.
    def auto_create_board_for(account)
      ChatwootKanban::Board.active
        .where(account_id: account.id)
        .find { |b| b.settings.is_a?(Hash) && b.settings['auto_create_from_conversations'] }
    end

    def conversation_title(c)
      sender = c.contact&.name.presence || 'Unknown'
      inbox  = c.inbox&.name.presence || 'channel'
      "##{c.display_id} · #{sender} (#{inbox})"
    end

    def conversation_excerpt(c)
      c.messages.where(message_type: :incoming).order(created_at: :asc).first&.content.to_s.truncate(500)
    end

    def derive_priority(c)
      case c.priority.to_s
      when 'urgent' then :urgent
      when 'high'   then :high
      when 'medium' then :medium
      else               :low
      end
    end
  end
end
