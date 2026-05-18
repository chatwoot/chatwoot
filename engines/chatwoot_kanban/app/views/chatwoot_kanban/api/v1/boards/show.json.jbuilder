json.data do
  json.partial! 'chatwoot_kanban/api/v1/boards/board', board: @board
  json.columns @board.columns.ordered do |column|
    json.partial! 'chatwoot_kanban/api/v1/columns/column', column: column
    json.cards column.cards.order(:position) do |card|
      json.partial! 'chatwoot_kanban/api/v1/cards/card', card: card
    end
  end
end
