# US-003: Lead Qualification Worker

**Sprint:** 3 (Semana 3)
**Prioridad:** P0 - Crítica
**Estimación:** 42 horas
**Owner:** Bolívar + Daniela + María

---

## User Story

```
Como equipo de ventas de GP Bikes,
Quiero que los leads se califiquen automáticamente con un score 1-10,
Para enfocar mi tiempo en los leads de mayor potencial (score >= 8) y maximizar conversiones.
```

---

## Acceptance Criteria

### 1. Captura de Datos del Lead

#### Presupuesto (presupuesto_cop)
- [ ] Detecta mención de presupuesto en COP
- [ ] Maneja formatos: "$20M", "$20.000.000", "20 millones", "veinte millones"
- [ ] Pregunta directa si no se menciona: "¿Qué presupuesto tienes para tu moto?"
- [ ] Valida rango: 3M - 50M COP (motos Yamaha disponibles)
- [ ] Si fuera de rango, sugiere financiamiento o modelos alternativos

#### Urgencia (urgencia_compra)
- [ ] Detecta timeline de compra
- [ ] Patrones:
  - "Hoy", "esta semana", "urgente" → urgencia: 10
  - "Este mes", "próximas semanas" → urgencia: 8-9
  - "2-3 meses", "pronto" → urgencia: 6-7
  - "Estoy mirando", "evaluando" → urgencia: 4-5
  - "Solo información", "curiosidad" → urgencia: 1-3
- [ ] Pregunta directa: "¿Para cuándo necesitas la moto?"

#### Experiencia (experiencia_motociclista)
- [ ] Detecta nivel de experiencia
- [ ] Patrones:
  - "Tengo moto", "conductor experimentado", "años conduciendo" → experiencia: 10
  - "Tengo licencia", "conduzco regularmente" → experiencia: 8-9
  - "Licencia en trámite", "algo de experiencia" → experiencia: 6-7
  - "Recién saqué licencia", "principiante" → experiencia: 4-5
  - "No tengo licencia", "primera moto", "nunca he conducido" → experiencia: 1-3
- [ ] Pregunta directa: "¿Has conducido moto antes?"

### 2. Algoritmo de Lead Score

**Fórmula:**
```
Lead Score = (Presupuesto * 0.40) + (Urgencia * 0.35) + (Experiencia * 0.25)
```

**Componente: Presupuesto (peso 40%)**
```
Score Presupuesto (1-10):
  10: >= $30M COP (gama alta: MT-09, Ténéré 700, FJR1300)
  9:  $25M-29M COP (gama media-alta: Tracer 9, XSR900)
  8:  $20M-24M COP (XTZ 250, FZ25, R3)
  7:  $15M-19M COP (FZ-16, XTZ 125, Factor 125)
  6:  $10M-14M COP (Crypton, BWS, Ray)
  5:  $7M-9M COP (entrada + financiamiento ligero)
  4:  $5M-6M COP (requiere financiamiento moderado)
  3:  $3M-4M COP (requiere financiamiento fuerte)
  1-2: < $3M COP (fuera de rango Yamaha)
```

**Componente: Urgencia (peso 35%)**
```
Score Urgencia (1-10):
  10: Compra inmediata (hoy, esta semana)
  9:  Próximos 7-15 días
  8:  Este mes (30 días)
  7:  Próximos 2 meses
  6:  2-3 meses
  5:  3-6 meses
  4:  "Pronto", sin fecha específica
  3:  "Estoy evaluando"
  2:  "Solo información"
  1:  "Curiosidad", sin intención clara
```

**Componente: Experiencia (peso 25%)**
```
Score Experiencia (1-10):
  10: Conductor experimentado, tiene moto actualmente (upgrade)
  9:  5+ años de experiencia, sin moto actual
  8:  2-5 años de experiencia
  7:  Tiene licencia C (>150cc), <2 años experiencia
  6:  Tiene licencia B (<=150cc), <1 año experiencia
  5:  Licencia en trámite, algo de experiencia informal
  4:  Licencia recién obtenida, muy poca experiencia
  3:  Sin licencia, sin experiencia
  2:  Sin licencia, sin interés en sacarla pronto
  1:  Sin licencia, no sabe si quiere conducir (exploración)
```

**Ejemplos de Cálculo:**

```
Ejemplo 1: Lead HOT
Presupuesto: $28M (score: 9)
Urgencia: "Esta semana" (score: 10)
Experiencia: "Tengo una FZ16 hace 3 años" (score: 9)

Lead Score = (9 * 0.40) + (10 * 0.35) + (9 * 0.25)
           = 3.6 + 3.5 + 2.25
           = 9.35 ≈ 9 ✅ HANDOFF INMEDIATO

Ejemplo 2: Lead MEDIO
Presupuesto: $12M (score: 6)
Urgencia: "Próximos 2 meses" (score: 7)
Experiencia: "Licencia recién salida" (score: 4)

Lead Score = (6 * 0.40) + (7 * 0.35) + (4 * 0.25)
           = 2.4 + 2.45 + 1.0
           = 5.85 ≈ 6 → Continúa con ProductCatalogWorker

Ejemplo 3: Lead BAJO
Presupuesto: $8M (score: 5)
Urgencia: "Solo información" (score: 2)
Experiencia: "Nunca he conducido" (score: 3)

Lead Score = (5 * 0.40) + (2 * 0.35) + (3 * 0.25)
           = 2.0 + 0.7 + 0.75
           = 3.45 ≈ 3 → FollowUpWorker programado
```

### 3. Routing Logic

**Score >= 8 (Lead HOT):**
- [ ] **HANDOFF INMEDIATO** a agente humano disponible
- [ ] Mensaje a cliente: "¡Perfecto! Veo que estás listo para tu nueva Yamaha. Un asesor especializado te contactará en los próximos 5 minutos. 🏍️"
- [ ] Notificación a agente en dashboard (popup + sound)
- [ ] Asignación automática al agente con menor carga actual
- [ ] Summary en conversation notes: presupuesto, urgencia, experiencia, score

**Score 5-7 (Lead MEDIO):**
- [ ] Continúa automáticamente con **ProductCatalogWorker**
- [ ] NO handoff inmediato
- [ ] Puede handoff después si cliente muestra interés fuerte en modelo

**Score 1-4 (Lead BAJO):**
- [ ] NO continúa con ProductCatalogWorker
- [ ] Mensaje educativo: información sobre proceso, financiamiento, licencias
- [ ] Programar FollowUpWorker para 7 días después
- [ ] NO handoff a agente (no es eficiente uso de tiempo)

### 4. Memory Persistence

**Custom Attributes a almacenar:**
```ruby
{
  # Datos capturados
  presupuesto_cop: 28000000,                    # Integer
  urgencia_compra: "esta_semana",                # String (enum)
  urgencia_score: 10,                            # Integer 1-10
  experiencia_motociclista: "conductor_experimentado", # String (enum)
  experiencia_score: 9,                          # Integer 1-10

  # Lead Score
  lead_score: 9,                                 # Integer 1-10 (final)
  lead_score_presupuesto: 3.6,                   # Float (componente)
  lead_score_urgencia: 3.5,                      # Float (componente)
  lead_score_experiencia: 2.25,                  # Float (componente)
  lead_score_calculated_at: "2025-10-01T10:30:00Z", # ISO8601

  # Routing
  lead_qualification_completed: true,            # Boolean
  handoff_triggered: true,                       # Boolean (si score >= 8)
  handoff_reason: "high_lead_score",             # String
  assigned_agent_id: 42,                         # Integer (si handoff)
}
```

### 5. Conversational Flow

**Conversación Ejemplo (Lead HOT):**

```
Cliente: Hola, quiero comprar una moto deportiva

GreetingWorker: ¡Hola! ¿Cómo estás? 👋 Bienvenido a GP Bikes...

Cliente: Tengo presupuesto de 30 millones, la necesito para esta semana porque mi moto actual se dañó

LeadQualificationWorker (detecta: presupuesto=30M, urgencia=alta):
"¡Excelente! ¿Has conducido moto antes? ¿Qué experiencia tienes?"

Cliente: Sí, tengo una FZ25 hace 2 años, conduzco todos los días

LeadQualificationWorker (calcula score = 9.5):
"¡Perfecto! Veo que estás listo para tu nueva Yamaha. Un asesor especializado te contactará en los próximos 5 minutos para ayudarte a encontrar la moto perfecta. 🏍️"

[HANDOFF A AGENTE]
```

### 6. Tests (RSpec)

#### Unit Tests

- [ ] Test: Detecta presupuesto en diferentes formatos
- [ ] Test: Detecta urgencia en diferentes frases
- [ ] Test: Detecta experiencia en diferentes contextos
- [ ] Test: Cálculo correcto de lead_score (10+ escenarios)
- [ ] Test: Componentes del score (presupuesto, urgencia, experiencia)
- [ ] Test: Routing correcto según score (8+, 5-7, 1-4)
- [ ] Test: Custom attributes almacenados correctamente
- [ ] Test: Handoff triggered si score >= 8
- [ ] Test: ProductCatalogWorker llamado si score 5-7

#### Integration Tests

- [ ] Test: Flow completo Lead HOT (score 9) → handoff
- [ ] Test: Flow completo Lead MEDIO (score 6) → ProductCatalog
- [ ] Test: Flow completo Lead BAJO (score 3) → FollowUp
- [ ] Test: Dashboard notification recibida por agente

#### VCR Cassettes

- [ ] `lead_qualification/high_score_9.yml`
- [ ] `lead_qualification/medium_score_6.yml`
- [ ] `lead_qualification/low_score_3.yml`

---

## Definition of Done

- [ ] Algoritmo de scoring implementado y validado
- [ ] Tests con 15+ escenarios de diferentes scores
- [ ] Handoff logic funcional
- [ ] Dashboard notification implementada
- [ ] Custom attributes schema definido
- [ ] Documentación de algoritmo en YARD
- [ ] Validación con 50 leads históricos (precisión >= 85%)
- [ ] PR aprobado por Daniela (business logic) y Bolívar (code)

---

## Validation con Datos Históricos

Antes de go-live, validar con muestra de **50 leads históricos** de GP Bikes:
- Calcular score automático
- Comparar con conversión real (compró o no)
- Medir precisión:
  - True Positives: score >= 8 Y compró
  - True Negatives: score < 8 Y NO compró
  - False Positives: score >= 8 Y NO compró
  - False Negatives: score < 8 Y compró

**Target:** Precisión >= 85%

Si precisión < 85%: ajustar pesos del algoritmo o agregar componentes adicionales.

---

## Notes

- Este worker es **el corazón del ROI del sistema**
- Incorrecta calificación = pérdida de ventas (false negatives) o tiempo desperdiciado (false positives)
- Considerar ML model en Fase 6 si reglas no alcanzan 90% precisión
- A/B testing de diferentes fórmulas en las primeras 2 semanas post-launch
