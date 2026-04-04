## ADDED Requirements

### Requirement: Busca de contatos inclui username do Telegram
O sistema SHALL incluir o campo `additional_attributes->>'social_telegram_user_name'` na query de busca de contatos, permitindo encontrar usuários Telegram pelo seu username.

#### Scenario: Busca por username Telegram retorna contato
- **WHEN** o agente busca por "F4ll" na tela de contatos
- **THEN** contatos cujo `additional_attributes['social_telegram_user_name']` contenha "F4ll" são retornados nos resultados

#### Scenario: Busca por nome ainda funciona normalmente
- **WHEN** o agente busca por um nome como "João"
- **THEN** contatos cujo `name` contenha "João" são retornados normalmente, sem regressão
