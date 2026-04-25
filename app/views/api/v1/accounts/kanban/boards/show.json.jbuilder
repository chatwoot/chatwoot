json.id @board.id
json.user_id @board.user_id
json.account_id @board.account_id
json.columns @board.columns.includes(:cards) do |column|
  json.partial! 'api/v1/accounts/kanban/columns/column', column: column
end
