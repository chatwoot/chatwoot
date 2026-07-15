json.array! @kanban_boards do |kanban_board|
  json.partial! 'kanban_board', kanban_board: kanban_board
end
