<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/brand/logo-dark.png">
  <source media="(prefers-color-scheme: light)" srcset=".github/brand/logo-light.png">
  <img src=".github/brand/logo-light.png" alt="fazer.ai" width="200">
</picture>

<h1>Chatwoot fazer.ai</h1>

<p>O Chatwoot oficial, com tudo que faltava pra atender no Brasil.</p>
<p>Atendimento por WhatsApp no seu servidor, com edição aberta e opção Pro.</p>

**Português (Brasil)** · [English](README-en.md)

[![Release](https://img.shields.io/github/v/release/fazer-ai/chatwoot)](https://github.com/fazer-ai/chatwoot/releases)
[![Downloads](https://img.shields.io/endpoint?url=https%3A%2F%2Ffazer.ai%2Fapi%2Fbadges%2Fchatwoot-downloads)](https://github.com/fazer-ai/chatwoot/pkgs/container/chatwoot)

</div>

## O que é

Chatwoot fazer.ai é um fork do Chatwoot oficial, mantido pela fazer.ai (FAZER.AI LTDA). A Chatwoot Inc. desenvolve o produto original e é uma empresa separada.

O fork acompanha as versões do Chatwoot oficial e acrescenta recursos para quem monta e opera atendimento por WhatsApp. Você pode usar a edição aberta gratuitamente ou contratar o Chatwoot fazer.ai Pro para incluir o Kanban de vendas.

## O que a fazer.ai adiciona

### WhatsApp

- Conexão pelo QR code do celular, sem API paga de terceiros, ou pela API oficial, inclusive em coexistência com o app WhatsApp Business.
- Provedor próprio para QR code, “WhatsApp (nativo)”. Roda no servidor da instalação, sem serviço de terceiros, com um [conector de código aberto em Go](https://github.com/fazer-ai/whatsapp-connector) mantido pela fazer.ai.
- Troca do modo de conexão da caixa de entrada sem perder o histórico.
- Importação do histórico do celular ao conectar.
- Grupos do WhatsApp.
- Reações e respostas citando mensagens, além de edição e exclusão.
- Indicadores de “digitando” e “gravando áudio”.
- Notas de voz são enviadas como notas de voz, em vez de arquivo de áudio.
- Foto de perfil do contato puxada do WhatsApp.

### Chat interno entre agentes

A equipe conversa dentro do atendimento, em canais públicos ou privados e por mensagens diretas.

- Threads e reações, com menção a conversas.
- Anexos ao colar ou arrastar arquivos, com rascunhos de mensagens.
- Notificações nativas e layout para celular.

A edição Pro libera o chat interno completo.

### Conversas e mensagens

- Mensagens agendadas, inclusive recorrentes ou com template do WhatsApp. Você pode suspender o envio se o cliente responder antes.
- Edição de mensagens enviadas, com histórico do conteúdo.
- Conversas fixadas ou marcadas como não lidas.
- Conversa travada no agente que a assumiu.
- Assinatura por caixa de entrada.
- Filtros personalizados pessoais ou globais, inclusive para encontrar contatos ou conversas com atributo personalizado ausente.

### Automações e integrações

- Gatilhos para mensagem editada e conversa parada por um período.
- Bots observadores recebem tudo o que acontece na caixa de entrada sem responder nem assumir conversas. Servem para classificar ou revisar o atendimento enquanto a equipe ou outro bot responde.
- Webhook por caixa de entrada, com eventos de mensagens recebidas ou enviadas e novas tentativas em caso de falha.
- Node do n8n: [`@fazer-ai/n8n-nodes-chatwoot`](https://www.npmjs.com/package/@fazer-ai/n8n-nodes-chatwoot).
- [fazer.ai agents](https://fazer.ai/agents): agentes de IA que atendem pelo Chatwoot nas duas edições, com [código disponível no GitHub](https://github.com/fazer-ai/agents).

### Operação

- Interface em português ou no idioma da conta, assim como e-mails transacionais e mensagens de atividade.
- White label com nome e logo próprios, além de cor e e-mails com a sua marca. Consulte [CUSTOM_BRANDING.md](CUSTOM_BRANDING.md).
- Envio de e-mail pelo Resend e armazenamento em serviços compatíveis com S3, como R2 ou MinIO.
- Importação em massa de e-mails por IMAP.
- Relatórios ordenáveis por qualquer coluna, com visões cruzadas entre agente, caixa de entrada e time.

Veja as mudanças de cada versão nas [notas de release](https://fazer.ai/chatwoot-release-notes) ou nas [releases do GitHub](https://github.com/fazer-ai/chatwoot/releases).

## Edições

| | Chatwoot fazer.ai | Chatwoot fazer.ai Pro |
| --- | --- | --- |
| Base de recursos | Chatwoot oficial com as adições da fazer.ai | Toda a edição aberta |
| Kanban de vendas | Não | Funis e oportunidades com valor, produtos, tarefas, automações e relatórios de funil |
| Chat interno | Até 2 canais privados, busca nos últimos 90 dias, sem enquetes | Completo, sem esses limites e com enquetes |
| Licença | Gratuita, MIT fora de `enterprise/` | Licença própria da fazer.ai para o código Pro, em repositório separado |
| Imagem Docker | Pública: `ghcr.io/fazer-ai/chatwoot` | Privada, liberada com a assinatura |

Conheça o [Kanban do Pro](https://fazer.ai/kanban) e ative sua licença em [app.fazer.ai](https://app.fazer.ai). A licença do Chatwoot fazer.ai Pro vem de graça com a assinatura Pro da [Comunidade Lucas Moreira](https://www.lucasmoreira.ai).

A licença do Chatwoot fazer.ai Pro cobre uma instalação (um domínio), sem limite de usuários, e vale para todas as contas dessa instalação. Você pode atender seus próprios clientes em contas da sua instalação, inclusive dando a eles acesso ao painel. Cada instalação separada precisa de licença própria; veja os [termos de uso](https://fazer.ai/termos-kanban).

### Chatwoot Enterprise

As licenças fazer.ai não incluem recursos do Chatwoot Enterprise. SSO e Captain, assim como logs de auditoria e funções personalizadas, são licenciados pela Chatwoot Inc.

Para usar esses recursos com o fork, contrate a licença com a Chatwoot Inc. e defina `CW_EDITION=ee` no web e no Sidekiq da imagem `ghcr.io/fazer-ai/chatwoot`. A variável não substitui a licença.

Com `CW_EDITION=ee`, o container baixa no boot o diretório `enterprise/` da tag oficial do Chatwoot que corresponde à versão da imagem, confere o conteúdo contra o hash fixado no build e guarda uma cópia em `storage/.cw-enterprise`. O primeiro boot de cada versão precisa de acesso a `codeload.github.com`, e os seguintes usam a cópia guardada. Se o download ou a conferência falhar, o container não sobe e o log diz por quê; as variáveis de ajuste estão descritas em `docker/entrypoints/helpers/enterprise.sh`.

Com `CW_EDITION=ee`, o código Enterprise roda exatamente como a Chatwoot Inc. o publica para aquela versão, sem alterações ou patches do fork. A página “Marca” do super admin do fork só existe sem Enterprise; com Enterprise ativo, a marca segue as regras dele: a personalização é um recurso premium, e o plano community restaura as configurações de marca aos valores padrão. Consulte [CUSTOM_BRANDING.md](CUSTOM_BRANDING.md) para os detalhes.

Isso vale para a imagem Docker. Numa instalação a partir do código-fonte, o diretório `enterprise/` do checkout é carregado sempre que existe, com ou sem `CW_EDITION`; para rodar a edição Community, remova o diretório.

## Instalar

### Com o instalador do fazer.ai agents

O caminho mais curto é o [instalador do fazer.ai agents](https://fazer.ai/agents). Um agente de código conduz a instalação do Chatwoot fazer.ai e do agente de IA, junto com os demais serviços, num VPS.

### Só o Chatwoot, com Docker

Use a imagem pública `ghcr.io/fazer-ai/chatwoot:latest`. Se você já tem uma instalação, faça backup do banco antes de substituir a imagem oficial e siga os passos de migração abaixo.

O repositório inclui o [docker-compose.coolify.yaml](docker-compose.coolify.yaml) e um [guia de deploy no Coolify](docker/README-coolify-deploy.md), em português.

As variáveis próprias do fork estão comentadas no [.env.example](.env.example). A imagem pública oferece a tag `latest` e uma tag para cada release.

### WhatsApp (nativo)

O conector vem na imagem do Chatwoot fazer.ai e roda no container do Sidekiq, ligado por padrão para toda conta. Usa o mesmo Redis e cria um banco próprio no mesmo PostgreSQL no primeiro start. Para desligar, configure:

```bash
WHATSAPP_CONNECTOR_ENABLED=false
```

Para rodar o conector como serviço separado na stack, configure `WHATSAPP_CONNECTOR_EMBEDDED=false`. O [README do conector](https://github.com/fazer-ai/whatsapp-connector#instalar-com-o-chatwoot-fazerai) traz o passo a passo dos dois modos, com exemplos de docker-compose e migração de caixa.

> [!WARNING]
> Se você já roda o conector separado, configure `WHATSAPP_CONNECTOR_EMBEDDED=false` antes de atualizar a imagem. Sem isso, sobe um segundo conector disputando as mesmas sessões.

## Atualizar e migrar do Chatwoot oficial

### Atualizar

1. Faça backup do banco antes de trocar a imagem.
2. Baixe a nova imagem e reinicie os serviços pelo painel onde o Chatwoot roda.

Para fixar uma versão, use a tag da release no lugar de `latest`.

As tags `-ee` não são mais publicadas; quem usa uma delas continua funcionando, mas fica na última versão publicada, sem atualizações. Para continuar recebendo atualizações, troque para `ghcr.io/fazer-ai/chatwoot`, com `latest` ou uma tag de versão sem `-ee`, e defina `CW_EDITION=ee` no web e no Sidekiq. Com essa configuração, o primeiro boot de cada versão baixa o código Enterprise da tag oficial do Chatwoot e leva alguns segundos a mais: precisa de acesso de saída ao GitHub e de `/app/storage` em um volume persistente compartilhado entre web e Sidekiq, como já ocorre nos composes de exemplo e no instalador. Quem usa a imagem padrão sem Enterprise não precisa mudar nada; veja os detalhes em [Chatwoot Enterprise](#chatwoot-enterprise).

### Migrar do Chatwoot oficial

1. Escolha uma versão do fork igual ou mais nova que a instalada.
2. Faça backup do banco antes de trocar a imagem.
3. Substitua a imagem oficial por `ghcr.io/fazer-ai/chatwoot`, com a tag escolhida, e reinicie os serviços.

O banco e os anexos são mantidos, assim como as configurações.

## Suporte e comunidade

- Dúvidas de instalação e uso: [perguntas e respostas da Comunidade Lucas Moreira](https://www.lucasmoreira.ai/c/perguntas-e-respostas).
- Bugs e pedidos de funcionalidade: [issues no GitHub](https://github.com/fazer-ai/chatwoot/issues).
- Vídeos em português: [canal Lucas Moreira](https://youtube.com/@eulucassmoreira).
- Documentação da API, inclusive Kanban: [docs-chatwoot.fazer.ai](https://docs-chatwoot.fazer.ai).

## Licença

O Chatwoot original tem copyright (c) 2017-2026 Chatwoot Inc. e usa a licença MIT, exceto o conteúdo de `enterprise/`. Esse diretório segue os termos de [enterprise/LICENSE](enterprise/LICENSE).

As alterações e adições do fork têm copyright (c) 2025-2026 FAZER.AI LTDA. Elas seguem os mesmos termos do código que estendem, com licença MIT fora de `enterprise/`. Componentes de terceiros mantêm suas respectivas licenças.

Ao redistribuir o software ou partes substanciais dele, mantenha os dois avisos de copyright e o aviso de permissão. A exigência também se aplica a cópias de arquivos individuais.

Consulte [NOTICE](NOTICE) e [LICENSE](LICENSE) para os termos completos.

## Links

- [Chatwoot fazer.ai](https://fazer.ai/chatwoot)
- [Licenças fazer.ai](https://app.fazer.ai)
- [Chatwoot oficial](https://www.chatwoot.com)
- [Código do Chatwoot oficial](https://github.com/chatwoot/chatwoot)

Mantido pela fazer.ai.
