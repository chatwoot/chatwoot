# Correção: Limites de Caracteres para Instagram

## Problema Identificado

O envio de mensagens para o Instagram estava falando com erro **Status 400 (Bad Request)** quando o texto excedia os limites de caracteres impostos pela API do Instagram:

```
"Die Länge der gesendeten Nachricht überschreitet 1.000 Zeichen"
(O comprimento da mensagem enviada excede 1.000 caracteres)
```

### Cenário do Erro
- **Tipo de mensagem**: QUICK_REPLIES do Dialogflow
- **Tamanho do texto**: 1024 caracteres (excedeu o limite de 1000)
- **Resultado**: API do Instagram rejeitou com erro 400
- **Status da mensagem**: Marcada como "failed"

## Solução Implementada

### Limites por Tipo de Template

A correção implementa validação e truncamento automático para os três tipos de template:

1. **QUICK_REPLIES**: 1000 caracteres para texto
2. **BUTTON_TEMPLATE**: 640 caracteres para texto  
3. **GENERIC_TEMPLATE**: 80 caracteres para títulos e subtítulos

### Funcionalidades Adicionadas

#### 1. Método Principal: `apply_character_limits`
- Aplica limites específicos baseados no tipo de template
- Preserva a funcionalidade existente
- Adiciona logs detalhados para monitoramento

#### 2. Métodos Específicos por Template
- `apply_quick_replies_limits`: Valida texto de Quick Replies
- `apply_button_template_limits`: Valida texto de Button Template
- `apply_generic_template_limits`: Valida títulos e subtítulos de Generic Template

#### 3. Método de Truncamento: `truncate_text`
- Trunca texto preservando espaço para aviso
- Adiciona "(mensagem truncada)" ao final
- Garante que o texto final não exceda o limite

### Integração no Código

A validação foi integrada nos métodos de construção de payload:

```ruby
# Em build_quick_replies_payload
processed_payload = apply_character_limits(payload, 'QUICK_REPLIES')

# Em build_button_template_payload  
processed_payload = apply_character_limits(payload, 'BUTTON_TEMPLATE')

# Em build_generic_template_payload
processed_payload = apply_character_limits(payload, 'GENERIC_TEMPLATE')
```

## Comportamento da Correção

### Antes da Correção
```
Texto: 1024 caracteres → Erro 400 → Mensagem falha
```

### Após a Correção
```
Texto: 1024 caracteres → Truncado para 1000 → Enviado com sucesso
Texto final: "...texto original... (mensagem truncada)"
```

### Logs Gerados

```
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Applying character limits for format: QUICK_REPLIES
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies text truncated from 1024 to 1000 characters
```

## Casos de Teste Validados

✅ **Cenário 1**: Texto com 1024 chars → Truncado para 1000 chars  
✅ **Cenário 2**: Texto com 500 chars → Mantido inalterado  
✅ **Cenário 3**: Texto com 1000 chars → Mantido inalterado  

## Impacto

### Positivo
- ✅ Elimina erros 400 do Instagram por excesso de caracteres
- ✅ Mantém a funcionalidade existente intacta
- ✅ Adiciona logs para monitoramento
- ✅ Usuário recebe mensagem (mesmo que truncada) ao invés de falha

### Considerações
- ⚠️ Mensagens muito longas serão truncadas com aviso
- ⚠️ Usuário saberá que a mensagem foi cortada pelo aviso "(mensagem truncada)"

## Arquivos Modificados

- `lib/integrations/socialwise/instagram_response_processor.rb`
  - Adicionados métodos de validação de caracteres
  - Integração nos métodos de build de payload
  - Logs detalhados para monitoramento

## Conclusão

A correção resolve o problema específico do erro 400 do Instagram mantendo a experiência do usuário. Mensagens que excedem os limites são automaticamente truncadas com aviso, evitando falhas no envio e garantindo que a comunicação continue fluindo.