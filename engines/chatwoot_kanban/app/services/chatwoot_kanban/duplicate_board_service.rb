module ChatwootKanban
  class DuplicateBoardService
    def initialize(source:, user:)
      @source = source
      @user   = user
    end

    def call
      ChatwootKanban::Board.transaction do
        new_board = ChatwootKanban::Board.create!(
          account_id:    @source.account_id,
          name:          "#{@source.name} (copy)",
          description:   @source.description,
          settings:      @source.settings,
          created_by_id: @user.id
        )
        # The board's after_create hook seeds default columns — remove them, we will copy from source.
        new_board.columns.destroy_all

        @source.columns.ordered.each do |col|
          new_col = new_board.columns.create!(
            name:      col.name,
            position:  col.position,
            color:     col.color,
            wip_limit: col.wip_limit
          )
          col.cards.each do |card|
            new_col.cards.create!(
              title:           card.title,
              description:     card.description,
              position:        card.position,
              priority:        card.priority,
              due_at:          card.due_at,
              assignee_id:     card.assignee_id,
              created_by_id:   @user.id,
              conversation_id: card.conversation_id,
              metadata:        card.metadata
            )
          end
        end
        new_board
      end
    end
  end
end
