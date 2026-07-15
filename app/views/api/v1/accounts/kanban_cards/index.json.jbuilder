json.array! @kanban_cards do |kanban_card|
  json.partial! 'kanban_card', kanban_card: kanban_card
end
