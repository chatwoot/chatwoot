## ADDED Requirements

### Requirement: Telegram inbox aparece como opção ao iniciar conversa a partir de contato
O sistema SHALL expor inboxes do tipo `Channel::Telegram` no `ContactableInboxesService` quando o contato possui um `contact_inbox` associado a esse inbox, retornando o `source_id` desse `contact_inbox` como identificador da conversa.

#### Scenario: Contato com histórico Telegram pode iniciar nova conversa
- **WHEN** o agente acessa a tela de contatos e seleciona um contato que possui `contact_inbox` vinculado a um inbox Telegram
- **THEN** o inbox Telegram aparece na lista de inboxes disponíveis para iniciar conversa

#### Scenario: Contato sem histórico Telegram não expõe inbox Telegram
- **WHEN** o agente acessa a tela de contatos e seleciona um contato que não possui nenhum `contact_inbox` vinculado a inbox Telegram
- **THEN** nenhum inbox Telegram é exibido como opção para iniciar conversa
