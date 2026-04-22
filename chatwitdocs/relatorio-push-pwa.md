# Relatório — Notificações Push do PWA no Chatwit

Data: 2026-04-22

## Objetivo

Este documento explica como funciona o push notification do PWA do Chatwit, com foco no fluxo real implementado no fork, no comportamento do mobile/PWA e nas diferenças práticas entre Android, iPhone e iPad.

## Resumo executivo

O Chatwit usa **Web Push padrão via VAPID** para o PWA. No mobile, o módulo apenas **conecta** a infraestrutura já existente do desktop ao layout mobile, sem recriar a lógica. O fluxo é:

1. O frontend registra o service worker `public/sw.js`.
2. O usuário concede permissão de notificação.
3. O navegador cria uma `PushSubscription`.
4. O frontend envia `endpoint`, `p256dh` e `auth` para o backend.
5. O backend salva a subscription como `browser_push`.
6. Quando o Chatwit gera uma notificação interna, o backend envia Web Push assinado com VAPID.
7. O service worker exibe a notificação.
8. Ao tocar na notificação, o app abre ou foca a conversa correta.

## Arquitetura adotada no Chatwit

- Sem Firebase para o PWA mobile.
- Sem FCM para o fluxo de browser push do PWA.
- Sem serviço terceiro para entregar push web.
- O servidor do próprio Chatwit gera e mantém as chaves VAPID.
- O mobile reutiliza o mesmo fluxo compartilhado do desktop.

Isso está alinhado com a documentação do módulo mobile do fork, que define explicitamente:

- Push via `pushHelper.js`, `sw.js`, VAPID e API de `NotificationSubscriptions`
- PWA instalável via `manifest.json` + meta tags + service worker
- Mobile como camada visual isolada, sem recriar regra de negócio

## Como o fluxo funciona no código

### 1. Registro do service worker

O frontend registra `'/sw.js'` e só segue se houver suporte a:

- `serviceWorker`
- `PushManager`
- `Notification`

Isso acontece no helper compartilhado:

- `/home/wital/chatwit/app/javascript/dashboard/helper/pushHelper.js`

## 2. Geração da subscription no navegador

Quando o usuário aceita notificações, o frontend chama:

- `Notification.requestPermission()`
- `serviceWorkerRegistration.pushManager.subscribe(...)`

Essa subscription usa a `vapidPublicKey` que o backend injeta no HTML.

Arquivos envolvidos:

- `/home/wital/chatwit/app/javascript/dashboard/helper/pushHelper.js`
- `/home/wital/chatwit/app/views/layouts/vueapp.html.erb`
- `/home/wital/chatwit/lib/vapid_service.rb`

## 3. Envio da subscription para o backend

Depois de criar a subscription, o frontend envia ao backend:

- `endpoint`
- `p256dh`
- `auth`

O payload é salvo como `subscription_type: 'browser_push'`.

Arquivos envolvidos:

- `/home/wital/chatwit/app/javascript/dashboard/helper/pushHelper.js`
- `/home/wital/chatwit/app/javascript/dashboard/api/notificationSubscription.js`
- `/home/wital/chatwit/app/controllers/api/v1/notification_subscriptions_controller.rb`
- `/home/wital/chatwit/app/builders/notification_subscription_builder.rb`
- `/home/wital/chatwit/app/models/notification_subscription.rb`

## 4. Persistência e identificação da subscription

O backend usa o `endpoint` como identificador da subscription de browser push. Se a mesma subscription já existir, ele atualiza; se pertencer a outro usuário logado naquele browser, ele move para o usuário atual.

Isso evita criar múltiplos registros iguais para o mesmo endpoint.

Arquivo principal:

- `/home/wital/chatwit/app/builders/notification_subscription_builder.rb`

## 5. Envio do push pelo backend

Quando uma notificação interna do Chatwit é gerada, o serviço:

- verifica se o usuário habilitou push para aquele tipo de notificação
- monta `title`, `body`, `tag` e `url`
- envia o payload com `WebPush.payload_send`
- assina com `public_key` e `private_key` VAPID

Arquivo principal:

- `/home/wital/chatwit/app/services/notification/push_notification_service.rb`

## 6. Exibição da notificação no service worker

O `public/sw.js`:

- recebe o evento `push`
- lê o JSON enviado pelo backend
- monta as opções da notificação
- chama `self.registration.showNotification(...)`
- salva uma chave recente para evitar duplicidade visual

Também há:

- `tag`
- `icon`
- `badge`
- `vibrate`
- `data.url`
- `renotify: false`

Arquivo principal:

- `/home/wital/chatwit/public/sw.js`

## 7. Clique na notificação

Quando o usuário toca na notificação, o `sw.js` tenta:

1. focar uma janela já aberta com a mesma URL
2. focar qualquer janela existente e navegar para a URL
3. abrir nova janela como fallback

Assim, a notificação leva a conversa correta do Chatwit.

Arquivo principal:

- `/home/wital/chatwit/public/sw.js`

## Chaves VAPID

O Chatwit gera as chaves automaticamente se ainda não existirem. Elas ficam persistidas em `InstallationConfig`, com possibilidade de fallback por variável de ambiente.

Fluxo:

- lê `GlobalConfig.get('VAPID_KEYS')`
- se não existir, executa `WebPush.generate_key`
- salva `public_key` e `private_key`
- expõe apenas a pública ao frontend

Arquivo principal:

- `/home/wital/chatwit/lib/vapid_service.rb`

## Como isso aparece no PWA mobile

No mobile, o push aparece na tela de **Configurações**, dentro da seção **Notificações**, com um toggle de ativação. Essa é a interface mostrada no print enviado.

O comportamento dessa tela é:

- detectar suporte do navegador a push
- detectar se a permissão já foi negada
- detectar se o app está em modo standalone
- no iPhone/iPad, avisar quando o usuário precisa instalar na Tela de Início
- ativar ou desativar a subscription chamando o helper compartilhado

Arquivo principal da tela mobile:

- `/home/wital/chatwit/app/javascript/dashboard/components-next/mobile/MobileSettingsView.vue`

## Comportamento no iPhone e iPad

### Regra prática mais importante

No iOS e no iPadOS, o Web Push para web app funciona no contexto de **Home Screen web app**. Em termos práticos para o usuário:

1. abrir o Chatwit no navegador
2. usar **Adicionar à Tela de Início**
3. abrir o Chatwit pelo ícone instalado
4. entrar em Configurações
5. ativar push
6. aceitar a permissão

Se o usuário estiver apenas navegando no browser, sem usar o app instalado na Tela de Início, o fluxo pode não se comportar como um web app instalável com push habilitado.

### Como o próprio Chatwit trata isso

O `MobileSettingsView.vue` já tem lógica específica para iPhone/iPad:

- detecta `display-mode: standalone`
- usa `window.navigator.standalone`
- se for iOS e não estiver standalone, mostra texto de que é preciso instalar o app

Arquivo:

- `/home/wital/chatwit/app/javascript/dashboard/components-next/mobile/MobileSettingsView.vue`

### Compatibilidade Apple

Com base nas referências oficiais da Apple/WebKit, o suporte relevante é:

- **iOS/iPadOS 16.4 ou superior** para Web Push em web apps na Tela de Início
- pedido de permissão deve ocorrer por ação direta do usuário
- as notificações passam a aparecer no sistema como qualquer outro app

Observação operacional:

- Se houver regras de rede muito restritivas, é importante não bloquear endpoints Apple de push, como `*.push.apple.com`

## Comportamento no Android

No Android, o fluxo costuma ser mais simples:

- navegador compatível com Service Worker + Push API
- permissão concedida
- subscription criada e salva
- service worker exibe as notificações normalmente

O Android tende a ser menos restritivo que o iOS para esse fluxo de PWA.

## Tratamento de duplicidade

Havia um problema documentado no fork: ao desinstalar e reinstalar o PWA, o browser podia gerar nova subscription enquanto a antiga seguia registrada no backend.

Para corrigir isso, o Chatwit passou a:

- apagar o registro no backend ao desligar push
- aceitar remoção por `endpoint`
- ignorar no `sw.js` notificações duplicadas recentes com a mesma identidade

Documentação:

- `/home/wital/chatwit/chatwitdocs/mobile-fixes.md`

Arquivos envolvidos:

- `/home/wital/chatwit/app/javascript/dashboard/helper/pushHelper.js`
- `/home/wital/chatwit/app/controllers/api/v1/notification_subscriptions_controller.rb`
- `/home/wital/chatwit/public/sw.js`

## Limitações e observações importantes

- Push web depende de HTTPS.
- O navegador precisa suportar Service Worker, Push API e Notifications API.
- O usuário precisa conceder permissão.
- O backend remove subscriptions inválidas ou expiradas quando detecta erro no envio.
- O módulo mobile do Chatwit não possui stack própria de push; ele só conecta a stack compartilhada.
- O documento histórico do mobile contém uma linha antiga de MVP dizendo que não havia service worker, mas a implementação atual do fork já usa `public/sw.js`; portanto o estado atual do código deve prevalecer sobre esse trecho antigo da documentação.

## Endereços completos dos códigos de referência

### Documentação local

- `/home/wital/chatwit/chatwitdocs/Chatwoot-Chatwit-mobile.md`
- `/home/wital/chatwit/chatwitdocs/mobile-fixes.md`

### Frontend

- `/home/wital/chatwit/app/javascript/dashboard/helper/pushHelper.js`
- `/home/wital/chatwit/app/javascript/dashboard/api/notificationSubscription.js`
- `/home/wital/chatwit/app/javascript/dashboard/App.vue`
- `/home/wital/chatwit/app/javascript/dashboard/components-next/mobile/MobileSettingsView.vue`

### Service worker / PWA

- `/home/wital/chatwit/public/sw.js`
- `/home/wital/chatwit/public/manifest.json`
- `/home/wital/chatwit/app/views/layouts/vueapp.html.erb`

### Backend

- `/home/wital/chatwit/app/controllers/api/v1/notification_subscriptions_controller.rb`
- `/home/wital/chatwit/app/builders/notification_subscription_builder.rb`
- `/home/wital/chatwit/app/models/notification_subscription.rb`
- `/home/wital/chatwit/app/services/notification/push_notification_service.rb`
- `/home/wital/chatwit/lib/vapid_service.rb`
- `/home/wital/chatwit/app/controllers/dashboard_controller.rb`

## Referências externas

- Apple Developer: https://developer.apple.com/documentation/usernotifications/sending-web-push-notifications-in-web-apps-and-browsers
- WebKit: https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/
- MDN Notifications API: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API
- MDN Push / background operation: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Offline_and_background_operation

## Conclusão

O push do PWA do Chatwit está implementado de forma padrão e correta para web:

- subscription no navegador
- persistência no backend
- envio Web Push com VAPID
- renderização via service worker
- navegação para a conversa ao tocar

No iPhone e iPad, o ponto crítico é o modo de uso: o Chatwit deve ser usado como web app instalado na Tela de Início para entrar no fluxo esperado de Web Push do ecossistema Apple.
