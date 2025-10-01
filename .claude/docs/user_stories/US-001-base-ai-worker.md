# US-001: BaseAiWorker

**Sprint:** 1 (Semana 2)
**Prioridad:** P0 - Bloqueante
**Estimación:** 18 horas
**Owner:** Bolívar + María

---

## User Story

```
Como desarrollador backend,
Quiero una clase base BaseAiWorker con métodos comunes,
Para implementar nuevos AI workers de forma consistente y rápida sin duplicar código.
```

---

## Acceptance Criteria

### 1. Estructura de Clase

- [ ] Clase `BaseAiWorker` en `app/services/ai_workers/base_ai_worker.rb`
- [ ] Namespace `module AiWorkers`
- [ ] Clase abstracta (no instanciable directamente)
- [ ] Requiere implementación de `should_trigger?` y `process` en subclases

### 2. Métodos Core

#### `should_trigger?(conversation, message)`
- [ ] Método abstracto (debe ser implementado por subclases)
- [ ] Retorna boolean
- [ ] Recibe `conversation` y `message` como parámetros
- [ ] Lanza `NotImplementedError` si no está implementado

#### `process(conversation, message)`
- [ ] Método abstracto (debe ser implementado por subclases)
- [ ] Ejecuta lógica principal del worker
- [ ] Retorna hash con resultado (status, data, error)
- [ ] Lanza `NotImplementedError` si no está implementado

#### `call_openai(system_prompt:, user_message:, **options)`
- [ ] Wrapper para OpenAI API client
- [ ] Retry logic con exponential backoff (max 3 intentos)
- [ ] Reintentos: 2s, 4s, 8s (2^n segundos)
- [ ] Maneja errores: `Timeout`, `RateLimitError`, `AuthenticationError`
- [ ] Logging de request y response (nivel DEBUG)
- [ ] Logging de errores (nivel ERROR)
- [ ] Parámetros configurables: `temperature`, `max_tokens`, `model`
- [ ] Valores por defecto: `temperature: 0.7`, `max_tokens: 500`, `model: gpt-4-turbo`

#### `update_contact_memory(contact, key, value)`
- [ ] Actualiza `contact.custom_attributes[key] = value`
- [ ] Valida schema antes de guardar (via `GpBikesContactAttributes::SCHEMA`)
- [ ] Logging de actualización (nivel INFO)
- [ ] Timestamp automático: `updated_at_#{key}`
- [ ] Source tracking: `source_#{key}` = nombre del worker
- [ ] Retorna true/false según éxito

#### `send_message(conversation, content)`
- [ ] Wrapper para Chatwoot message API
- [ ] Crea mensaje en conversation
- [ ] Message type: `outgoing`
- [ ] Sender: `bot` (no agente humano)
- [ ] Logging de mensaje enviado
- [ ] Retorna mensaje creado o nil si error

#### `extract_data_from_response(openai_response, expected_keys: [])`
- [ ] Parsea JSON de respuesta OpenAI
- [ ] Maneja `JSON::ParserError` gracefully
- [ ] Valida presencia de `expected_keys` si se especifican
- [ ] Retorna hash con datos extraídos
- [ ] Retorna hash vacío si parsing falla

### 3. Error Handling

- [ ] Rescue `OpenAI::Error` con retry logic
- [ ] Rescue `JSON::ParserError` en extract_data_from_response
- [ ] Rescue `ActiveRecord::RecordInvalid` en update_contact_memory
- [ ] Logging estructurado de todos los errores
- [ ] Never crash conversation flow (graceful degradation)

### 4. Logging

- [ ] `Rails.logger.debug` para OpenAI requests
- [ ] `Rails.logger.info` para operaciones exitosas
- [ ] `Rails.logger.warn` para reintentos
- [ ] `Rails.logger.error` para fallos después de max reintentos
- [ ] Incluir contexto: `worker_name`, `conversation_id`, `contact_id`

### 5. Tests (RSpec)

#### Unit Tests (`spec/services/ai_workers/base_ai_worker_spec.rb`)

- [ ] Test: `should_trigger?` lanza `NotImplementedError`
- [ ] Test: `process` lanza `NotImplementedError`
- [ ] Test: `call_openai` exitoso con respuesta válida
- [ ] Test: `call_openai` con timeout (3 reintentos)
- [ ] Test: `call_openai` con rate limit (3 reintentos)
- [ ] Test: `call_openai` con error auth (no reintenta, falla inmediato)
- [ ] Test: `update_contact_memory` exitoso
- [ ] Test: `update_contact_memory` con schema inválido (falla validation)
- [ ] Test: `send_message` exitoso
- [ ] Test: `extract_data_from_response` con JSON válido
- [ ] Test: `extract_data_from_response` con JSON malformado
- [ ] Test: logging de cada operación

#### Coverage

- [ ] SimpleCov: 100% coverage
- [ ] Todos los métodos públicos testeados
- [ ] Todos los paths de error testeados
- [ ] Mocks para OpenAI (no API calls reales en tests)

### 6. Documentation

- [ ] YARD comments en cada método público
- [ ] Ejemplos de uso en comments
- [ ] README con ejemplo de implementación de subclase

---

## Technical Implementation

### Exponential Backoff Logic

```ruby
def call_openai_with_retry(system_prompt:, user_message:, **options)
  retries = 0
  max_retries = 3

  begin
    call_openai_internal(system_prompt: system_prompt, user_message: user_message, **options)
  rescue OpenAI::TimeoutError, OpenAI::RateLimitError => e
    retries += 1
    if retries < max_retries
      sleep_time = 2 ** retries
      Rails.logger.warn "OpenAI #{e.class.name}, retry #{retries}/#{max_retries} after #{sleep_time}s"
      sleep(sleep_time)
      retry
    else
      Rails.logger.error "OpenAI failed after #{max_retries} attempts: #{e.message}"
      raise
    end
  rescue OpenAI::AuthenticationError => e
    Rails.logger.error "OpenAI authentication failed: #{e.message}"
    raise
  end
end
```

### Schema Validation Example

```ruby
def update_contact_memory(contact, key, value)
  schema = GpBikesContactAttributes::SCHEMA[key]

  if schema && !validate_value(value, schema)
    Rails.logger.error "Invalid value for #{key}: #{value} (expected #{schema[:type]})"
    return false
  end

  contact.custom_attributes[key] = value
  contact.custom_attributes["updated_at_#{key}"] = Time.current.iso8601
  contact.custom_attributes["source_#{key}"] = self.class.name

  contact.save!
  Rails.logger.info "Updated #{key} for contact #{contact.id}"
  true
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error "Failed to update contact memory: #{e.message}"
  false
end
```

---

## Definition of Done

- [ ] Código implementado según acceptance criteria
- [ ] Tests RSpec pasando (100% coverage)
- [ ] Rubocop sin offenses
- [ ] YARD documentation completa
- [ ] PR aprobado por Simón (architect review)
- [ ] Merged a `gp-bikes-main` branch

---

## Dependencies

- OpenAI API key configurado en `.env.development`
- Gem `ruby-openai` instalado
- Schema `GpBikesContactAttributes::SCHEMA` definido

---

## Notes

- Esta clase es la **base crítica** para todos los 8 AI workers
- Cualquier cambio aquí impacta a todos los workers derivados
- Prioritar estabilidad y robustez sobre features avanzadas
- Documentación exhaustiva es esencial
