json.id kanban_board.id
json.name kanban_board.name
json.description kanban_board.description
json.board_type kanban_board.board_type
json.columns_count kanban_board.kanban_columns.count
json.cards_count kanban_board.kanban_cards.count
json.columns kanban_board.kanban_columns.ordered do |kanban_column|
  json.id kanban_column.id
  json.name kanban_column.name
  json.description kanban_column.description
  json.color kanban_column.color
  json.position kanban_column.position
  json.win_probability kanban_column.win_probability.to_f
  json.cards_count kanban_column.kanban_cards.count
end
json.created_at kanban_board.created_at.to_i
json.updated_at kanban_board.updated_at.to_i
