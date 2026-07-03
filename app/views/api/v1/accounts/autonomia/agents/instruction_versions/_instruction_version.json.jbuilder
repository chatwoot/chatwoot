json.id instruction_version.id
json.created_at instruction_version.created_at
json.reason instruction_version.reason
# Autoria: nome do usuário que editou, ou fallback de sistema quando foi um refresh automático.
json.created_by_name(instruction_version.created_by&.name || 'Autonom.ia')
json.instruction_hash instruction_version.instruction_hash
# IP OCULTO: o TEXTO da instrução só sai para agentes MANUAIS (texto do próprio usuário, visível).
# Em modo guiado a instrução é gerada pelo Construtor (IP nosso) → nunca expomos o conteúdo, só
# metadados que ainda permitem o rollback.
json.instruction instruction_version.instruction if @agent.manual?
