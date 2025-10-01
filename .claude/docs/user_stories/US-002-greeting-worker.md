# US-002: GreetingWorker

**Sprint:** 1 (Semana 2)
**Prioridad:** P0 - Bloqueante
**Estimación:** 13 horas
**Owner:** Bolívar + María

---

## User Story

```
Como cliente nuevo en WhatsApp,
Quiero recibir un saludo automático al iniciar conversación,
Para sentirme atendido inmediatamente incluso fuera de horario laboral.
```

---

## Acceptance Criteria

### 1. Activación del Worker

- [ ] Worker se activa SOLO en el primer mensaje de una conversación (`messages_count == 1`)
- [ ] NO se activa en mensajes subsecuentes (`messages_count > 1`)
- [ ] Implementa `should_trigger?` correctamente
- [ ] Test con múltiples escenarios de activación

### 2. Respuesta Automática

- [ ] Responde en **menos de 2 segundos** (P95: 3s, P99: 5s)
- [ ] Mensaje incluye:
  - Saludo cordial en español colombiano
  - Nombre de la empresa: "GP Bikes"
  - Mención de "motocicletas Yamaha"
  - Horarios de atención: "Lunes a Viernes 9am-6pm, Sábados 9am-2pm"
  - Pregunta abierta: "¿En qué te puedo ayudar hoy?"
- [ ] Tono: amigable, profesional, conversacional (no formal/robótico)

### 3. Captura de Nombre

- [ ] Detecta si el cliente menciona su nombre en el primer mensaje
- [ ] Patrones a detectar:
  - "Hola soy [Nombre]"
  - "Mi nombre es [Nombre]"
  - "Me llamo [Nombre]"
  - "[Nombre] acá" / "[Nombre] aquí"
- [ ] Almacena nombre en `contact.custom_attributes['nombre_capturado']`
- [ ] Si nombre detectado, personaliza saludo: "¡Hola [Nombre]!"
- [ ] Si NO detectado, saludo genérico: "¡Hola! ¿Cómo estás?"

### 4. Memory Persistence

- [ ] Almacena `timestamp_first_contact` en custom_attributes (ISO8601 format)
- [ ] Almacena `nombre_capturado` si se detectó
- [ ] Almacena `greeting_sent: true` para tracking
- [ ] Usa `update_contact_memory` de BaseAiWorker

### 5. Integration con ConversationRouter

- [ ] Router detecta mensaje nuevo
- [ ] Llama a `GreetingWorker.should_trigger?`
- [ ] Ejecuta `GreetingWorker.process` si trigger = true
- [ ] NO ejecuta otros workers después (GreetingWorker es exclusivo para primer mensaje)

### 6. System Prompt (config/ai_workers/prompts.yml)

```yaml
greeting_worker:
  system: |
    Eres un asistente virtual de GP Bikes, distribuidor oficial de motocicletas Yamaha en Colombia.

    Tu tarea es dar la bienvenida al cliente de forma amigable y profesional.

    INSTRUCCIONES:
    1. Saluda cordialmente en español colombiano (tuteo, no ustedeo)
    2. Presenta a GP Bikes como "tu distribuidor Yamaha de confianza"
    3. Menciona horarios: Lunes a Viernes 9am-6pm, Sábados 9am-2pm
    4. Si el cliente mencionó su nombre, úsalo en el saludo
    5. Pregunta: "¿En qué te puedo ayudar hoy?"
    6. Tono: amigable, cercano, entusiasta (evita ser robótico o demasiado formal)

    DETECCIÓN DE NOMBRE:
    Si detectas que el cliente mencionó su nombre (ej: "Hola soy Juan"), extrae el nombre.
    Responde en JSON:
    {
      "nombre_detectado": "Juan" o null,
      "mensaje_saludo": "texto del saludo personalizado"
    }
```

### 7. Tests (RSpec)

#### Unit Tests (`spec/services/ai_workers/greeting_worker_spec.rb`)

**should_trigger? tests:**
- [ ] Test: `messages_count == 1` → true
- [ ] Test: `messages_count == 0` → false (edge case, no debería ocurrir)
- [ ] Test: `messages_count > 1` → false

**process tests:**
- [ ] Test: Cliente dice "Hola" (sin nombre) → saludo genérico
- [ ] Test: Cliente dice "Hola soy María" → saludo personalizado "¡Hola María!"
- [ ] Test: Cliente dice "Mi nombre es Carlos" → saludo personalizado "¡Hola Carlos!"
- [ ] Test: Cliente dice "Me llamo Ana" → saludo personalizado "¡Hola Ana!"
- [ ] Test: Mensaje largo con nombre en medio → detecta nombre correctamente
- [ ] Test: `timestamp_first_contact` se almacena en custom_attributes
- [ ] Test: `greeting_sent: true` se almacena
- [ ] Test: Respuesta enviada con `send_message`
- [ ] Test: Tiempo de respuesta < 2 segundos (con VCR cassette)

#### Integration Test (`spec/integration/greeting_flow_spec.rb`)

- [ ] Test: Mensaje nuevo → listener activa → router llama GreetingWorker → respuesta enviada
- [ ] Test: Verificar custom_attributes actualizados en Contact
- [ ] Test: Segundo mensaje NO activa GreetingWorker

#### VCR Cassettes

- [ ] `fixtures/vcr_cassettes/greeting_worker/generic_greeting.yml`
- [ ] `fixtures/vcr_cassettes/greeting_worker/personalized_greeting_juan.yml`
- [ ] `fixtures/vcr_cassettes/greeting_worker/personalized_greeting_maria.yml`

---

## Technical Implementation

### Nombre Detection Logic

```ruby
# Option 1: Regex (simple, fast)
def extract_nombre_from_message(message_text)
  patterns = [
    /(?:soy|nombre es|me llamo|llamo)\s+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)/i,
    /^([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)\s+(?:acá|aquí|aca|aki)/i
  ]

  patterns.each do |pattern|
    match = message_text.match(pattern)
    return match[1].capitalize if match
  end

  nil
end

# Option 2: OpenAI (más robusto, más lento)
# Usar system prompt con instrucción de detección
```

### Example Response

**Scenario 1: Sin nombre**
```
¡Hola! ¿Cómo estás? 👋

Soy el asistente virtual de GP Bikes, tu distribuidor Yamaha de confianza en Colombia.

Estamos disponibles:
📅 Lunes a Viernes: 9am - 6pm
📅 Sábados: 9am - 2pm

¿En qué te puedo ayudar hoy? 🏍️
```

**Scenario 2: Con nombre (ej: "Hola soy Carlos")**
```
¡Hola Carlos! ¿Cómo estás? 👋

Bienvenido a GP Bikes, tu distribuidor Yamaha de confianza en Colombia.

Estamos disponibles:
📅 Lunes a Viernes: 9am - 6pm
📅 Sábados: 9am - 2pm

¿En qué te puedo ayudar hoy? 🏍️
```

---

## Definition of Done

- [ ] Código implementado según acceptance criteria
- [ ] Tests RSpec pasando (coverage >= 95%)
- [ ] VCR cassettes grabados (3 scenarios)
- [ ] Integration test pasando
- [ ] Manual test en desarrollo (docker-compose up + WhatsApp sandbox)
- [ ] System prompt en `config/ai_workers/prompts.yml`
- [ ] Rubocop sin offenses
- [ ] PR aprobado por Simón
- [ ] Documentación en YARD

---

## Dependencies

- BaseAiWorker completamente funcional (US-001)
- ConversationRouter implementado
- GpBikesMessageListener configurado
- OpenAI API key

---

## Performance Requirements

| Métrica | Target | P95 | P99 |
|---------|--------|-----|-----|
| Tiempo de respuesta | <2s | 3s | 5s |
| OpenAI API latency | <1s | 1.5s | 2s |
| DB write (custom_attributes) | <100ms | 150ms | 200ms |

---

## Notes

- Este es el **primer worker funcional** del sistema
- Establece el patrón de implementación para los otros 7 workers
- La experiencia del primer mensaje es **crítica** para engagement
- Emoji usage es aceptable para tono amigable (revisar con Daniela)
- Considerar A/B testing de diferentes tonos/mensajes en Fase 6
