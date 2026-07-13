import type { AppConfig } from './config.js';

const escapeForInlineScript = (value: string): string =>
  JSON.stringify(value).replaceAll('<', '\\u003c');

export const renderWidgetPage = (config: AppConfig): string => {
  if (!config.CHATWOOT_WEBSITE_TOKEN) {
    return `<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><title>AgentBot Lab</title></head>
<body><h1>AgentBot Lab</h1><p>CHATWOOT_WEBSITE_TOKEN이 아직 설정되지 않았습니다.</p></body></html>`;
  }

  return `<!doctype html>
<html lang="ko">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chatwoot AgentBot Lab</title>
  </head>
  <body>
    <main>
      <h1>Chatwoot AgentBot Lab</h1>
      <p id="customer">테스트 고객 식별정보를 Widget에 설정하고 있습니다.</p>
      <p>오른쪽 아래 Widget에서 메시지를 보내세요.</p>
    </main>
    <script>
      window.chatwootSettings = { hideMessageBubble: false, position: 'right', locale: 'ko' };
      (function(d,t) {
        const BASE_URL=${escapeForInlineScript(config.CHATWOOT_PUBLIC_URL)};
        const g=d.createElement(t),s=d.getElementsByTagName(t)[0];
        g.src=BASE_URL + '/packs/js/sdk.js';
        g.async=true;
        s.parentNode.insertBefore(g,s);
        g.onload=function(){
          window.chatwootSDK.run({
            websiteToken: ${escapeForInlineScript(config.CHATWOOT_WEBSITE_TOKEN)},
            baseUrl: BASE_URL
          });
        };
      })(document,'script');

      window.addEventListener('chatwoot:ready', function() {
        window.$chatwoot.setUser(${escapeForInlineScript(config.DEMO_CUSTOMER_IDENTIFIER)}, {
          name: ${escapeForInlineScript(config.DEMO_CUSTOMER_NAME)},
          email: ${escapeForInlineScript(config.DEMO_CUSTOMER_EMAIL)},
          phone_number: ${escapeForInlineScript(config.DEMO_CUSTOMER_PHONE)}
        });
        document.getElementById('customer').textContent =
          '테스트 고객 식별정보가 설정되었습니다: ' + ${escapeForInlineScript(config.DEMO_CUSTOMER_IDENTIFIER)};
      });
    </script>
  </body>
</html>`;
};
