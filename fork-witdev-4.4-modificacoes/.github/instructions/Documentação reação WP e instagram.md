## instagram
React or unreact to a message
To send a reaction, send a POST request to the /<IG_ID>/messages endpoint with the recipient parameter containing the Instagram-scoped ID (<IGSID>) and the sender_action parameter set to react and payload containing the message_id set to the ID for the message to apply the reaction to and reaction set to love.

To remove a reaction, repeat this request with the sender_action parameter to unreact with the payload containing message_id parameter only. Omit reaction.

Sample Request
Formatted for readability.

curl -X POST "https://graph.instagram.com/v23.0/<IG_ID>/messages"
     -H "Authorization: Bearer <INSTAGRAM_USER_ACCESS_TOKEN>" 
     -H "Content-Type: application/json" 
     -d '{
           "recipient":{
               "id":"<IGSID>"
           },
           "sender_action":"react",  // Or set to unreact to remove the reaction
           "payload":{
             "message_id":"<MESSAGE_ID>",
             "reaction":"love",      // Omit if removing a reaction
           }
         }' 

## WHATSAPP
Mensagens de reação
As mensagens de reação são reações com emojis que você pode aplicar a uma mensagem recebida anteriormente no WhatsApp.


Limitações
Ao enviar uma mensagem de reação, apenas um webhook de mensagem enviada (com status definido como sent) será disparado. O disparo não ocorrerá para webhooks de mensagens entregues e lidas.

Sintaxe da solicitação
Use o ponto de extremidade POST /<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>/messages para aplicar uma reação de emoji a uma mensagem que você recebeu de um usuário do WhatsApp.

curl 'https://graph.facebook.com/<API_VERSION>/<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>/messages' \ -H 'Content-Type: application/json' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -d ' { "messaging_product": "whatsapp", "recipient_type": "individual", "to": "<WHATSAPP_USER_PHONE_NUMBER>", "type": "reaction", "reaction": { "message_id": "<WHATSAPP_MESSAGE_ID>", "emoji": "<EMOJI>" } }' 
Parâmetros da solicitação
Espaço reservado	Descrição	Exemplo de valor
<ACCESS_TOKEN>

String

Required.

System token or business token.

EAAAN6tcBzAUBOZC82CW7iR2LiaZBwUHS4Y7FDtQxRUPy1PHZClDGZBZCgWdrTisgMjpFKiZAi1FBBQNO2IqZBAzdZAA16lmUs0XgRcCf6z1LLxQCgLXDEpg80d41UZBt1FKJZCqJFcTYXJvSMeHLvOdZwFyZBrV9ZPHZASSqxDZBUZASyFdzjiy2A1sippEsF4DVV5W2IlkOSr2LrMLuYoNMYBy8xQczzOKDOMccqHEZD

<API_VERSION>

String

Optional.

Graph API version.

v23.0
<EMOJI>

String

Obrigatório.

A sequência de escape Unicode do emoji, ou o próprio emoji, a ser aplicado à mensagem do usuário.

Exemplo de sequência de escape Unicode:

\uD83D\uDE00

Exemplo de emoji:

😀

<WHATSAPP_MESSAGE_ID>

String

Obrigatório.

A identificação da mensagem do WhatsApp para aplicação do emoji.

Se a mensagem à qual se destina a reação tiver mais de 30 dias, não corresponder a nenhuma mensagem na conversa, tiver sido excluída ou já for uma mensagem de reação, sua reação não será entregue e você receberá um webhook de mensagens com o código de erro 131009.

wamid.HBgLMTY0NjcwNDM1OTUVAgASGBQzQUZCMTY0MDc2MUYwNzBDNTY5MAA=

<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>

String

Required.

WhatsApp business phone number ID.

106540352242922

<WHATSAPP_USER_PHONE_NUMBER>

String

Required.

WhatsApp user phone number.

+16505551234

Exemplo de solicitação
Exemplo de solicitação para aplicar o emoji de rosto sorridente (😀) a uma mensagem recebida anteriormente.

curl 'https://graph.facebook.com/v23.0/106540352242922/messages' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer EAAJB...' \
-d '
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "+16505551234",
  "type": "reaction",
  "reaction": {
    "message_id": "wamid.HBgLMTY0NjcwNDM1OTUVAgASGBQzQUZCMTY0MDc2MUYwNzBDNTY5MAA=",
    "emoji": "\uD83D\uDE00"
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

## WHATAPP MESSAGEM EM CONTEXTO

Contextual replies
Contextual replies are a special way of responding to a WhatsApp user message. Sending a message as a contextual reply makes it clearer to the user which message you are replying to by quoting the previous message in a contextual bubble:


Limitations
You cannot send a reaction message as a contextual reply.
The contextual bubble will not appear at the top of the delivered message if:

The previous message has been deleted or moved to long term storage (messages are typically moved to long term storage after 30 days, unless you have enabled local storage).
You reply with an audio, image, or video message and the WhatsApp user is running KaiOS.
You use the WhatsApp client to reply with a push-to-talk message and the WhatsApp user is running KaiOS.
You reply with a template message.
Request Syntax
POST /<WHATSAPP_BUSINESS_PHONE_NUMBER_ID>/messages
Post Body
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "<WHATSAPP_USER_PHONE_NUMBER>",
  "context": {
    "message_id": "WAMID_TO_REPLY_TO"
  },

  /* Message type and type contents goes here */

}
Post Body Parameters
Placeholder	Description	Example Value
<WAMID_TO_REPLY_TO>

String

Required.

WhatsApp message ID (wamid) of the previous message you want to reply to.

wamid.HBgLMTY0NjcwNDM1OTUVAgASGBQzQTdCNTg5RjY1MEMyRjlGMjRGNgA=

<WHATSAPP_USER_PHONE_NUMBER>

String

Required.

WhatsApp user phone number.

+16505551234

Example Request
Example of a text message sent as a reply to a previous message.

curl 'https://graph.facebook.com/v19.0/106540352242922/messages' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer EAAJB...' \
-d '
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "+16505551234",
  "context": {
    "message_id": "wamid.HBgLMTY0NjcwNDM1OTUVAgASGBQzQTdCNTg5RjY1MEMyRjlGMjRGNgA="
  },
  "type": "text",
  "text": {
    "body": "You'\''re welcome, Pablo!"
  }
}'