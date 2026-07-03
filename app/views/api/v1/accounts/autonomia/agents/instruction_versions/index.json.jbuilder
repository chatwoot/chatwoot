json.payload do
  json.array! @versions,
              partial: 'api/v1/accounts/autonomia/agents/instruction_versions/instruction_version',
              as: :instruction_version
end

# Espelha o índice de agentes/sources para o factory `get` do FE (lê meta.total_count/meta.page).
json.meta do
  json.total_count @versions.size
  json.page 1
end
