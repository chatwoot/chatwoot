## ADDED Requirements

### Requirement: Contato Telegram criado com identifier igual ao from_id
O sistema SHALL preencher o campo `identifier` do contato com o valor `telegram_from_id.to_s` ao criar um novo contato via mensagem Telegram, garantindo deduplicação correta e busca por esse campo.

#### Scenario: Novo contato Telegram recebe identifier
- **WHEN** uma mensagem Telegram de um usuário sem contato existente é recebida
- **THEN** o contato é criado com `identifier` igual ao ID numérico do usuário Telegram

#### Scenario: Segundo contato Telegram com mesmo from_id reutiliza contato existente
- **WHEN** uma mensagem Telegram de um usuário com contato já existente (mesmo `identifier`) é recebida
- **THEN** o contato existente é reutilizado sem criar duplicata

### Requirement: Nome do contato Telegram usa username como fallback
O sistema SHALL usar `@username` como nome do contato quando o usuário Telegram não possuir `first_name` nem `last_name`.

#### Scenario: Usuário com first_name tem nome correto
- **WHEN** uma mensagem Telegram é recebida de usuário com `first_name: "João"` e `last_name: "Silva"`
- **THEN** o contato é criado com `name: "João Silva"`

#### Scenario: Usuário sem nome tem username como fallback
- **WHEN** uma mensagem Telegram é recebida de usuário sem `first_name` nem `last_name`, mas com `username: "F4ll"`
- **THEN** o contato é criado com `name: "@F4ll"`
