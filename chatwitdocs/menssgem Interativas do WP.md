Mensagens do botão de URL de chamada para ação interativo
Updated: 3 de nov de 2025
Os usuários do WhatsApp talvez hesitem em tocar em URLs brutos com strings longas ou obscuras recebidos por mensagem de texto. Nessas situações, você pode optar por enviar uma mensagem com um botão de URL de chamada para ação (CTA) interativo. As mensagens com botões URL de CTA permitem representar qualquer URL em um botão. Dessa forma, não será preciso incluir o URL bruto no corpo da mensagem.

Sintaxe da solicitação
Ponto de extremidade: POST /<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>/messages
curl 'https://graph.facebook.com/<API_VERSION>/<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>/messages' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer <ACCESS_TOKEN>' \
-d '
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "<WHATSAPP_USER_PHONE_NUMBER>",
  "type": "interactive",
  "interactive": {
    "type": "cta_url",

    <!-- If using document header, otherwise omit -->
    "header": {
      "type": "document",
      "document": {
        "link": "<ASSET_URL>"
      }
    },

    <!-- If using image header, otherwise omit -->
    "header": {
      "type": "image",
      "image": {
        "link": "<ASSET_URL>"
      }
    },

    <!-- If using text header, otherwise omit -->
    "header": {
      "type": "text",
      "text": "<HEADER_TEXT>"
      }
    },

    <!-- If using video header, otherwise omit -->
    "header": {
      "type": "video",
      "video": {
        "link": "<ASSET_URL>"
      }
    },

    "body": {
      "text": "<BODY_TEXT>"
    },
    "action": {
      "name": "cta_url",
      "parameters": {
        "display_text": "<BUTTON_LABEL_TEXT>",
        "url": "<BUTTON_URL>"
      }
    },

    <!-- If using footer text, otherwise omit -->
    "footer": {
      "text": "<FOOTER_TEXT>"
    }
  }
}'
Parâmetros de solicitação
Espaço reservado	Descrição	Valor de exemplo
<ACCESS_TOKEN>
String
Obrigatório.
Token do sistema ou token da empresa.
EAAAN6tcBzAUBOZC82CW7iR2LiaZBwUHS4Y7FDtQxRUPy1PHZClDGZBZCgWdrTisgMjpFKiZAi1FBBQNO2IqZBAzdZAA16lmUs0XgRcCf6z1LLxQCgLXDEpg80d41UZBt1FKJZCqJFcTYXJvSMeHLvOdZwFyZBrV9ZPHZASSqxDZBUZASyFdzjiy2A1sippEsF4DVV5W2IlkOSr2LrMLuYoNMYBy8xQczzOKDOMccqHEZD
<API_VERSION>
String
Opcional.
Versão da Graph API.
v25.0
<ASSET_URL>
String
Obrigatório se um cabeçalho com ativo de mídia for usado.
URL do ativo em um servidor público.
https://www.luckyshrub.com/assets/lucky-shrub-banner-logo-v1.png
<BODY_TEXT>
String
Obrigatório.
Corpo de texto. Os URLs são inseridos automaticamente como hiperlinks.
Máximo de 1.024 caracteres.
Tap the button below to see available dates.
<BUTTON_LABEL_TEXT>
String
Obrigatório.
Texto do rótulo do botão. Se houver vários botões, o ID deve ser único.
Máximo de 20 caracteres.
See Dates
<BUTTON_URL>
Obrigatório.
O URL que será carregado no navegador da web padrão do dispositivo após o toque do usuário do WhatsApp.
https://www.luckyshrub.com?clickID=kqDGWd24Q5TRwoEQTICY7W1JKoXvaZOXWAS7h1P76s0R7Paec4
<FOOTER_TEXT>
String
Obrigatório ao usar um rodapé.
Texto do rodapé. Os URLs são inseridos automaticamente como hiperlinks.
Máximo de 60 caracteres.
Dates subject to change.
<HEADER_TEXT>
String
Obrigatório ao usar um cabeçalho de texto.
Texto do cabeçalho.
Máximo de 60 caracteres.
New workshop dates announced!
<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>
String
Obrigatório.
Identificação do número de telefone do WhatsApp Business.
106540352242922
<WHATSAPP_USER_PHONE_NUMBER>
String
Obrigatório.
Número de telefone do usuário do WhatsApp.
+16505551234
Exemplo de pedido
curl 'https://graph.facebook.com/v25.0/106540352242922/messages' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer EAAJB...' \
-d '
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "+16505551234",
  "type": "interactive",
  "interactive": {
    "type": "cta_url",
    "header": {
      "type": "image",
      "image": {
        "link": "https://www.luckyshrub.com/assets/lucky-shrub-banner-logo-v1.png"
      }
    },
    "body": {
      "text": "Tap the button below to see available dates."
    },
    "action": {
      "name": "cta_url",
      "parameters": {
        "display_text": "See Dates",
        "url": "https://www.luckyshrub.com?clickID=kqDGWd24Q5TRwoEQTICY7W1JKoXvaZOXWAS7h1P76s0R7Paec4"
      }
    },
    "footer": {
      "text": "Dates subject to change."
    }
  }
}'
Exemplo de resposta
{
  "messaging_product": "whatsapp",
  "contacts": [
    {
      "input": "+16505551234",
      "wa_id": "16505551234"
    }
  ],
  "messages": [
    {
      "id": "wamid.HBgLMTY0NjcwNDM1OTUVAgARGBI1RjQyNUE3NEYxMzAzMzQ5MkEA"
    }
  ]
}
