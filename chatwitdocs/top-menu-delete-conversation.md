# Excluir conversa no menu superior

Data: 2026-05-20

## Contexto

O menu de contexto da lista de conversas já permitia excluir uma conversa, mas o menu de ações do topo da conversa exibia apenas bloquear/desbloquear contato e enviar transcrição.

## Alteração

- Adicionado o item `Excluir conversa` ao menu superior da conversa em `MoreActions.vue`.
- O item aparece apenas para administradores, mantendo a mesma regra do menu de contexto.
- A ação usa o fluxo existente de exclusão via store `deleteConversation`, com o mesmo modal de confirmação e mensagens i18n já usadas no menu de contexto.
- Após confirmar a exclusão, a tela volta para a lista de conversas correspondente ao contexto atual.

## Escopo

- Alteração limitada ao desktop em `app/javascript/dashboard/components/widgets/conversation/MoreActions.vue`.
- Nenhuma mudança no módulo mobile PWA.
- Nenhuma alteração em API ou contrato com a plataforma.
