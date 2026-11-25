# Implantar no Coolify como applications

Medido em 10/09/2026, no dia em que a instância de produção migrou de um service do Coolify para applications.

O `docker-compose.coolify.yaml` descreve a instalação como um **service** do Coolify, ou seja, um compose que o painel gerencia. Este documento descreve a outra forma, em que cada processo é uma **application** e cada banco é um **database**, todos na mesma rede Docker. As duas funcionam; a segunda evita as armadilhas listadas no fim.

## A forma

Cada recurso é declarado sozinho, com alias fixo, na rede do destino (`coolify`, por padrão). Não há compose, não há `depends_on`, e nada depende de nome curto interno de stack.

| papel | tipo de recurso | alias sugerido |
| --- | --- | --- |
| web | application (dockerimage) | `chatwoot` |
| worker | application (dockerimage) | `chatwoot-sidekiq` |
| banco | database postgresql | o uuid do recurso |
| fila | database redis | o uuid do recurso |
| conector WhatsApp (opcional) | application (dockerimage) | `whatsapp-connector` |

**Alias de application se declara em `custom_network_aliases`.** Não em `custom_docker_run_options: --network-alias`, que não tem efeito. Sem alias, o container de uma application se chama `<uuid>-<timestamp>`, e esse nome muda a cada deploy: qualquer coisa que aponte para ele quebra no deploy seguinte.

Database não precisa de alias: o container tem o nome do uuid e ele é estável entre deploys. É por isso que `POSTGRES_HOST` e `REDIS_URL` costumam carregar uuid em vez de nome amigável.

## O papel de cada container vem do entrypoint, não de `command`

Uma application de `dockerimage` **não recebe `command`** no compose que o Coolify gera, e esta imagem não declara `CMD`. Web e worker saem da mesma imagem por `--entrypoint` dentro de `custom_docker_run_options`:

```
web     --entrypoint "docker/entrypoints/rails.sh bundle exec rails s -p 3000 -b 0.0.0.0"
worker  --entrypoint "docker/entrypoints/sidekiq.sh bundle exec sidekiq -C config/sidekiq.yml"
```

O que o `post_start` do compose fazia depois do boot vira `post_deployment_command` na application (por exemplo `bundle exec rails branding:update`).

## A ordem entre web e worker não existe, e é por isso que o portão importa

Entre duas applications não há `depends_on`. As duas sobem ao mesmo tempo, e o `rails.sh` é quem roda `db:chatwoot_prepare`.

O que impede o worker de subir contra um schema velho é o portão em `docker/entrypoints/sidekiq.sh`, que segura até `db:abort_if_pending_migrations` passar. Desde a #573 ele também viaja no `ENTRYPOINT` da imagem, decidindo por argv, então vale mesmo se alguém esquecer o `--entrypoint`.

Neste modelo o portão deixou de ser cinto e virou pré-requisito. Sem ele, todo deploy que traga migração perde em silêncio o que chegar na janela: o ActiveRecord lê as colunas de um modelo uma vez por processo, e só quebra quem **cria** registro, então containers ficam saudáveis, filas ficam vazias, e mensagem some.

## Volume compartilhado entre web e worker

Os dois precisam do mesmo `/app/storage`, onde o Active Storage local guarda os anexos. O Coolify nomeia volume por recurso (`<uuid>-<nome>`), então **dois applications não compartilham volume nomeado**. A saída é `host_path`, que faz bind do mesmo diretório do host nos dois:

```
/data/<instalacao>/storage -> /app/storage   (nos dois recursos)
```

Instalações que usam S3 ou GCS não precisam disso para os anexos, mas o volume ainda serve à edição Enterprise: com `CW_EDITION=ee`, cada container guarda em `/app/storage/.cw-enterprise` o `enterprise/` que baixou e conferiu no boot. Sem esse volume, todo deploy baixa de novo, e um deploy sem acesso a `codeload.github.com` não sobe. O `/app` da imagem pode ser somente leitura, desde que `/app/tmp` continue gravável (o Rails já exige isso): cada container ativa o Enterprise para si num link em `/app/tmp/cw-enterprise`, e só um download escreve no volume. Se uma entrada do cache deixar de conferir com o hash, o boot falha com o caminho dela: pare web e worker, apague essa entrada e suba de novo.

## Envs

Web e worker carregam o mesmo conjunto, com `SIDEKIQ_CONCURRENCY` só no worker. Dois merecem atenção porque erram em silêncio:

**`INTERNAL_HOST_URL`** é o endereço pelo qual um provedor **busca** o arquivo de um anexo. Texto e reação viajam inteiros no comando; anexo não, porque isso colocaria um vídeo de 60 MB dentro do processo Rails e dentro do frame do comando. O `AttachmentAdapter` troca o host do `download_url` por este valor. Se ele não resolver do lado de quem busca, **só o envio de anexo quebra**, com `could not fetch the file to send`, e todo o resto segue funcionando. Em application, o valor é o alias: `http://chatwoot:3000`.

**`WHATSAPP_CONNECTOR_EVENT_SHARDS`** não é opcional com o conector ligado, que é o padrão: o `config/database.yml` **soma** esse número ao pool de todo processo. O valor tem que bater com o `WAC_EVENT_SHARDS` do conector, senão o consumo abre mais threads do que o pool comporta.

## O conector WhatsApp

O canal WhatsApp (nativo) vem ligado em toda instalação e toda conta; `WHATSAPP_CONNECTOR_ENABLED=false` desliga a integração inteira, e `whatsapp_native_disabled` nos settings de uma conta (pelo console) tira o provedor só dela. Por padrão o conector roda **dentro do worker**: a imagem traz o binário numa versão fixa e o `sidekiq.sh` sobe o conector ao lado do Sidekiq, com o store no schema `whatsapp_connector` do próprio banco do Chatwoot (criado por uma migration do Chatwoot, então o usuário do banco não precisa de permissão para criar banco), diretório de mídia local do container e token de mídia gerado no start. Instalação que já tem o banco `<POSTGRES_DATABASE>_whatsapp_connector`, de antes do schema, continua nele, com os pareamentos. `WAC_DATABASE_URL` aponta o store para outro banco, que precisa existir: nada é criado em runtime, para que um nome digitado errado não suba o conector vazio e derrube os pareamentos. Quando o conector não sobe, o motivo e o comando para resolver aparecem no log do worker, na página de saúde do Super Admin e na opção desabilitada "WhatsApp (nativo)" do seletor de canal. Nesse modo não existe a application `whatsapp-connector`. Detalhes e um compose de exemplo de cada modo em [docs/deployment.md](https://github.com/fazer-ai/whatsapp-connector/blob/main/docs/deployment.md) do repositório do conector.

**Instalação que já roda o conector como application separada põe `WHATSAPP_CONNECTOR_EMBEDDED=false` no worker antes de atualizar a imagem, mesmo que nunca tenha definido `WHATSAPP_CONNECTOR_ENABLED`.** Sem isso sobe um segundo conector dentro do worker, com um store sem os pareamentos, disputando as mesmas sessões pelo mesmo Redis.

**Chamadas de WhatsApp na caixa nativa precisam de uma porta UDP.** A voz das ligações passa pelo conector numa porta UDP só, e o navegador dos agentes manda o áudio direto para ela. Defina `WAC_CALLS_UDP_PORT` (por exemplo `40000`) no container onde o conector roda (o worker, no modo embutido; a application `whatsapp-connector`, no modo separado) e publique essa porta em UDP no container, com o firewall do servidor liberando a mesma porta. Atrás de NAT, defina também `WAC_CALLS_PUBLIC_IP` com o IPv4 público do servidor. Sem a porta, as chamadas ficam desligadas, e a tela de chamadas da caixa diz o que falta.

Como application separada, o conector tem imagem e trem de release próprios, o que serve para atualizá-lo sem esperar uma release do Chatwoot (o whatsmeow muda a cada duas semanas). O resto desta seção vale para esse modo.

- **`REDIS_URL` e `REDIS_PASSWORD` são sem prefixo `WAC_`, de propósito:** os dois lados leem a mesma variável, então não dá para apontá-los para servidores diferentes. Redis separado produziria silêncio, não erro.
- **`WAC_ADVERTISE_URL` fica vazia.** O conector deriva o valor do próprio hostname, o que acompanha o container a cada deploy; um valor fixo apontaria para um container que deixou de existir.
- **Banco próprio**, onde ficam as credenciais de pareamento. É por isso que reiniciar o conector não desfaz o pareamento.
- **Healthcheck do Coolify desligado:** a imagem é distroless e não tem `/bin/sh`, então o healthcheck do painel falha mesmo com o serviço de pé. A imagem carrega o próprio `HEALTHCHECK`.

## Armadilhas medidas

**Service do Coolify perde a rede `coolify` no deploy pela API.** A flag `connect_to_docker_network` está certa, mas quem executa o `docker network connect` é o `StartService`, e o deploy pela API não chama. O sintoma é um recurso vizinho deixar de resolver o nome da stack, sem erro no painel. Applications não têm esse problema: elas entram na rede do destino por construção.

**Redis do Coolify sobe com `appendonly yes`.** Copiar um `dump.rdb` para dentro não restaura nada, porque ele carrega do AOF. Para migrar dados entre duas instâncias, use `MIGRATE` chave a chave.

**Application de `dockerimage` sem `command` e sem `CMD` na imagem não sobe.** É o `--entrypoint` que resolve.
