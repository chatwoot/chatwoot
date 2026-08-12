# Passarini Law — fork Chatwoot e atualização pelo Portainer

Este guia explica como preparar o fork local, implementar a regra de privacidade por time, publicar uma imagem privada e trocar a imagem no Portainer. Ele não contém senhas, tokens, URLs de banco ou outros segredos.

## Resultado esperado

- O fork é mantido em `https://github.com/eloscopecoo-rgb/chatwoot`.
- A customização parte do release `v4.16.2` do Chatwoot.
- Agente comum vê apenas conversas atribuídas a ele ou ao seu time; administrador mantém visão global.
- A imagem privada vai para GHCR e a mesma tag é usada por `chatwoot_web` e `chatwoot_sidekiq`.

> Importante: time do Chatwoot padrão organiza o encaminhamento, mas não é isolamento estrito em um inbox compartilhado. A regra deve ser aplicada no servidor, cobrindo listagem, busca e acesso direto à conversa/API.

## 1. Preparar o repositório local

```bash
git clone https://github.com/eloscopecoo-rgb/chatwoot.git chatwoot-passarini
cd chatwoot-passarini
git remote add upstream https://github.com/chatwoot/chatwoot.git
git fetch --tags upstream
git switch -c passarini/team-privacy-v4.16.2 v4.16.2
git remote -v
```

Resultado: a branch de trabalho nasce do release estável `v4.16.2`; `origin` aponta para o fork Eloscope e `upstream` para o projeto original.

Antes de começar, confirme que a árvore está limpa:

```bash
git status --short
git describe --tags --exact-match
# esperado: v4.16.2
```

## 2. Implementar a política de privacidade

Requisitos funcionais:

1. **Administrador:** acesso global preservado.
2. **Agente:** só acessa conversa atribuída ao próprio agente ou a um time do qual ele participe.
3. **Não atribuídas:** não aparecem como uma fila global para agentes comuns.
4. A regra deve ser aplicada no escopo/consulta de autorização do servidor. Não basta ocultar abas ou filtros no frontend.
5. Cobrir: listagem de conversas, busca, contadores, filtros, abertura por URL e endpoints usados pela API.

Crie testes que provem no mínimo:

- Agente Financeiro não lista nem abre conversa do Jurídico.
- Dois membros do Financeiro listam e assumem conversa atribuída ao Financeiro.
- Administrador continua vendo todas as conversas.
- Um agente não contorna a regra manipulando URL, filtro ou chamada da API.

Rode a suíte específica e as verificações do projeto antes de publicar. Siga os comandos atuais definidos pelo repositório na versão usada.

## 3. Criar a imagem privada no GHCR

Use uma tag que carregue a versão do Chatwoot e a revisão do patch Eloscope:

```text
ghcr.io/eloscopecoo-rgb/chatwoot:passarini-v4.16.2.1
```

Convenção para alterações futuras:

```text
passarini-v4.16.2.2  # nova revisão do patch sobre a mesma base
passarini-v4.17.0.1  # atualização da base do Chatwoot + primeira revisão do patch
```

O workflow GitHub Actions deve:

1. Rodar os testes de autorização adicionados.
2. Autenticar no GHCR usando `GITHUB_TOKEN` com permissão `packages: write`.
3. Fazer build para `linux/amd64` (arquitetura do VPS).
4. Publicar no pacote **privado** do GitHub Container Registry.
5. Nunca imprimir secrets nos logs.

Após o build, confirme no GitHub que o pacote e a tag existem antes de alterar o Portainer.

## 4. Preparar o Portainer para ler o GHCR

No GitHub, crie um token dedicado ao Portainer com o escopo mínimo necessário para pacote privado: `read:packages`. Guarde-o apenas como credencial do registry no Portainer.

No Portainer:

1. Acesse **Registries** e adicione um registry do tipo **GitHub Container Registry**.
2. Usuário: `eloscopecoo-rgb`.
3. Senha/token: token dedicado com `read:packages`.
4. Salve e teste o acesso ao pacote privado.

Não usar token de administrador, token pessoal de uso diário ou token colado em conversa.

## 5. Backup e rollback antes do deploy

Antes de atualizar a stack:

1. Fazer backup do PostgreSQL e confirmar que pode ser restaurado.
2. Registrar a imagem hoje em uso: `chatwoot/chatwoot:v4.16.0`.
3. Manter a tag do patch anterior disponível no GHCR.
4. Planejar uma janela curta para reiniciar `web` e `sidekiq` juntos.

## 6. Trocar a imagem na stack do Portainer

Na stack atual, substitua **somente** a imagem dos dois serviços. Não alterar variáveis, redes, volume, Traefik, PostgreSQL ou Redis neste passo.

```yaml
chatwoot_web:
  image: ghcr.io/eloscopecoo-rgb/chatwoot:passarini-v4.16.2.1
  command: bundle exec rails s -p 3000 -b 0.0.0.0

chatwoot_sidekiq:
  image: ghcr.io/eloscopecoo-rgb/chatwoot:passarini-v4.16.2.1
  command: bundle exec sidekiq -c 5
```

Depois de editar:

1. Clique em **Update the stack** e escolha pull da nova imagem.
2. Acompanhe os logs de `chatwoot_web` e `chatwoot_sidekiq` até ambos iniciarem sem erro.
3. Verifique o healthcheck e o acesso a `https://chat.passarinilaw.com`.

## 7. Validação de acesso

Com usuários de teste em ao menos dois times:

1. Atribua uma conversa ao Financeiro e outra ao Jurídico.
2. Com usuário do Financeiro, teste “Todos”, “Não atribuídas”, busca e URL direta da conversa Jurídica.
3. Confirme que a conversa Jurídica não aparece nem abre.
4. Confirme que ambos os agentes do Financeiro veem e podem assumir a conversa do Financeiro.
5. Com administrador, confirme a visão global.
6. Registre o resultado na task de validação F3.5 do ClickUp.

## Rollback

Se o deploy falhar ou houver regressão, altere **os dois** serviços de volta para a tag anterior registrada e faça update da stack. Se houver problema de dados, interrompa o atendimento e use o backup validado do PostgreSQL conforme o runbook de infraestrutura.

## Rastreio

- ClickUp: [F2.5 — Fork Chatwoot: privacidade por time + imagem para Portainer](https://app.clickup.com/t/86e2th964)
- Diagrama e contexto de negócio: `areas/vendas/oportunidades/passarini-law/arquitetura-fork-chatwoot-portainer.md` no Segundo Cérebro Eloscope.
