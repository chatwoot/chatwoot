json.array! @tokens_by_application do |application, tokens|
  json.id application.id
  json.name application.name
  json.scopes tokens.flat_map { |token| token.scopes.to_a }.uniq
  json.accounts @account_names.values_at(*tokens.map(&:account_id).uniq)
  json.authorized_at @authorized_at[application.id]
end
