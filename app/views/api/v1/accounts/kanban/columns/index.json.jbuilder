json.array! @columns do |column|
  json.partial! 'api/v1/accounts/kanban/columns/column', column: column
end
