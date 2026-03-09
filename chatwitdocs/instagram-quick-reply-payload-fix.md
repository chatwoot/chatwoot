# Correção: Perda de quick_reply payload no Instagram (SocialWise Flow)

**Data:** 2026-02-05
**Versão:** Chatwit 4.10
**Problema:** Payload do botão quick_reply do Instagram não era enviado ao SocialWise Flow

---

## Problema Identificado

O webhook da Meta entregava o payload do botão corretamente dentro do objeto `quick_reply`:

```ruby
# Webhooks::InstagramEventsJob - ENTRADA
Instagram Events Job Messaging: {
  "sender" => {"id" => "1002859634954741"},
  "message" => {
    "mid" => "aWdfZAG1faXRlbToxOklHTWVzc2FnZAUlEOjE3ODQxNDQ3...",
    "text" => "Saber Mais",
    "quick_reply" => {
      "payload" => "ig_btn_1770285402694_2_60600_2ra4679p"  # <--- O ID ESTAVA AQUI
    }
  }
}
```

Mas o sistema enviava ao SocialWise apenas o texto, sem o payload:

```ruby
# SocialwiseDebounceJob - SAÍDA PARA O SOCIALWISE
PAYLOAD: {
  "session_id": "1002859634954741",
  "message": "Saber Mais",             # <--- SEM O PAYLOAD
  "channel_type": "Channel::Instagram",
  "context": {
    "message": {
      "id": 47619,
      "content": "Saber Mais",
      "content_type": "text"           # <--- O payload foi ignorado
    }
  }
}
```

---

## Causa Raiz

O Chatwoot 4.10 nativo **não extraía** o `quick_reply.payload` nem o `postback.payload` do webhook do Instagram/Facebook. Esses dados eram ignorados e não salvos nos `content_attributes` da mensagem.

O fork Witdev 4.4 tinha essa funcionalidade implementada, mas não foi portada para o Chatwit 4.10.

---

## Solução Implementada

### 1. Adicionados métodos de extração no Facebook MessageParser

**Arquivo:** `lib/integrations/facebook/message_parser.rb`

```ruby
def postback_payload
  @messaging&.dig('postback', 'payload')
end

def postback_title
  @messaging&.dig('postback', 'title')
end

def quick_reply_payload
  @messaging&.dig('message', 'quick_reply', 'payload')
end

def postback?
  @messaging&.key?('postback')
end

def quick_reply?
  @messaging&.dig('message', 'quick_reply').present?
end
```

### 2. Criado Instagram MessageParser

**Arquivo:** `lib/integrations/instagram/message_parser.rb`

Novo arquivo com os mesmos métodos do Facebook MessageParser, adaptados para a estrutura de dados do Instagram.

### 3. Modificado Facebook MessageBuilder

**Arquivo:** `app/builders/messages/facebook/message_builder.rb`

```ruby
def message_params
  params = {
    # ... params base ...
    content_attributes: {
      in_reply_to_external_id: response.in_reply_to_external_id
    }
  }

  # Add postback/quick_reply payload to content_attributes
  if response.postback?
    params[:content_attributes][:postback_payload] = response.postback_payload
  elsif response.quick_reply?
    params[:content_attributes][:quick_reply_payload] = response.quick_reply_payload
  end

  params
end

def message_content
  if response.postback?
    response.postback_title || response.postback_payload
  else
    response.content
  end
end
```

### 4. Modificado Instagram BaseMessageBuilder

**Arquivo:** `app/builders/messages/instagram/base_message_builder.rb`

Mesma lógica aplicada ao builder do Instagram, usando o `Integrations::Instagram::MessageParser`.

### 5. Atualizado ProcessorService do SocialWise Flow

**Arquivo:** `lib/integrations/socialwise_flow/processor_service.rb`

#### 5.1 Método `build_request_payload` atualizado

Novo método `extract_interaction_data` extrai os dados de interação diretamente do message:

```ruby
def extract_interaction_data(message)
  content_attrs = message.content_attributes.with_indifferent_access
  data = {}

  # WhatsApp button/list replies
  if content_attrs[:button_reply].present?
    data[:button_id] = content_attrs[:button_reply][:id]
    data[:button_title] = content_attrs[:button_reply][:title]
    data[:interaction_type] = 'button_reply'
  end

  # Instagram/Facebook quick_reply
  if content_attrs[:quick_reply_payload].present?
    data[:quick_reply_payload] = content_attrs[:quick_reply_payload]
    data[:interaction_type] = 'quick_reply'
  end

  # Instagram/Facebook postback
  if content_attrs[:postback_payload].present?
    data[:postback_payload] = content_attrs[:postback_payload]
    data[:interaction_type] = 'postback'
  end

  data
end
```

#### 5.2 Método `interactive_reply?` atualizado

Agora detecta também `quick_reply` e `postback` do Instagram/Facebook para processar imediatamente sem debounce.

---

## Payload Corrigido

Após a correção, o payload enviado ao SocialWise inclui os dados de interação:

```ruby
PAYLOAD: {
  "session_id": "1002859634954741",
  "message": "Saber Mais",
  "channel_type": "Channel::Instagram",
  "quick_reply_payload": "ig_btn_1770285402694_2_60600_2ra4679p",  # <--- AGORA INCLUÍDO
  "interaction_type": "quick_reply",                               # <--- TIPO DE INTERAÇÃO
  "context": {
    "message": {
      "id": 47619,
      "content": "Saber Mais",
      "content_type": "text"
    }
  }
}
```

---

## Arquivos Modificados

| Arquivo | Alteração |
|---------|-----------|
| `lib/integrations/facebook/message_parser.rb` | Adicionados métodos `postback_payload`, `quick_reply_payload`, `postback?`, `quick_reply?` |
| `lib/integrations/instagram/message_parser.rb` | **NOVO** - Parser para Instagram com mesmos métodos |
| `app/builders/messages/facebook/message_builder.rb` | Adicionada extração de payload em `message_params` |
| `app/builders/messages/instagram/base_message_builder.rb` | Adicionada extração de payload em `message_params` |
| `lib/integrations/socialwise_flow/processor_service.rb` | Novo método `extract_interaction_data`, atualizado `interactive_reply?` |

---

## Comportamento Após Correção

| Tipo de Interação | Canal | Campo no Payload |
|-------------------|-------|------------------|
| Quick Reply | Instagram/Facebook | `quick_reply_payload` |
| Postback | Instagram/Facebook | `postback_payload` |
| Button Reply | WhatsApp | `button_id`, `button_title` |
| List Reply | WhatsApp | `list_id`, `list_title`, `list_description` |

Todos os cliques de botão agora são processados **imediatamente** (sem debounce), independente do canal.

---

## Teste

Para verificar se a correção está funcionando:

1. Configure uma integração SocialWise Flow em uma inbox do Instagram
2. Envie uma mensagem com quick_reply buttons do SocialWise
3. Clique em um botão
4. Verifique nos logs do Rails se o payload está sendo extraído:

```log
[SOCIALWISE-FLOW] Extracted Instagram/Facebook quick_reply_payload: ig_btn_xxx
[SOCIALWISE-FLOW] Detected interactive reply: type=quick_reply
```

5. Verifique se o payload enviado ao SocialWise inclui `quick_reply_payload`
