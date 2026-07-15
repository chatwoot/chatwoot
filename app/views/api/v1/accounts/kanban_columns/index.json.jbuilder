json.array! @kanban_columns do |kanban_column|
  json.partial! 'kanban_column', kanban_column: kanban_column
end
