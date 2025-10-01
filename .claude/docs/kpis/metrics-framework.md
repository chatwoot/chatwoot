# GP Bikes AI Assistant - Metrics Framework

**Owner:** Daniela (Product Owner)
**Versión:** 1.0
**Fecha:** 30 de septiembre de 2025

---

## 📊 Overview

Este documento define el framework completo de métricas para medir el éxito del GP Bikes AI Assistant. Las métricas están organizadas en tres niveles de prioridad con frecuencias de monitoreo específicas.

---

## 🎯 Objetivos de Negocio

| Objetivo | Baseline (Sin IA) | Meta Mes 6 | Métrica KPI |
|----------|-------------------|------------|-------------|
| Automatizar conversaciones | 0% | 80% | Tasa de Automatización |
| Mejorar calidad de leads | N/A | 85%+ | Precisión Lead Score |
| Reducir tiempo de respuesta | 15 min | <30 seg | Tiempo de Respuesta |
| Incrementar conversión | 15% | 20% | Tasa de Conversión |
| Mejorar satisfacción | 3.5/5 | 4.5/5 | NPS |

---

## 📈 KPIs Primarios (P0)

### 1. Tasa de Automatización

**Definición:** Porcentaje de conversaciones manejadas 100% por IA sin intervención humana.

**Fórmula:**
```
Tasa Automatización = (Conversaciones 100% IA / Total Conversaciones) * 100
```

**Queries SQL (PostgreSQL):**

```sql
-- Tasa de automatización diaria
SELECT
  DATE(created_at) as fecha,
  COUNT(CASE WHEN assignee_id IS NULL AND status = 'resolved' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as tasa_automatizacion
FROM conversations
WHERE created_at >= NOW() - INTERVAL '30 days'
  AND inbox_id = (SELECT id FROM inboxes WHERE name = 'WhatsApp GP Bikes')
GROUP BY DATE(created_at)
ORDER BY fecha DESC;

-- Tasa de automatización por worker
SELECT
  ca.value->>'last_active_worker' as worker_name,
  COUNT(*) as conversations_count,
  COUNT(CASE WHEN c.assignee_id IS NULL THEN 1 END) * 100.0 / COUNT(*) as automation_rate
FROM conversations c
JOIN contacts ct ON c.contact_id = ct.id
CROSS JOIN LATERAL jsonb_each(ct.custom_attributes) ca(key, value)
WHERE c.created_at >= NOW() - INTERVAL '7 days'
  AND ca.key = 'last_active_worker'
GROUP BY worker_name
ORDER BY automation_rate DESC;
```

**Metas:**
- Mes 1: 60%
- Mes 3: 75%
- Mes 6: **80%**

**Dashboard Grafana Panel:**
```
┌────────────────────────────────────────┐
│ Tasa de Automatización (Última Semana) │
│                                        │
│  [██████████████████] 78.3%           │
│                                        │
│  Target: 75%  ✅                       │
│  Trend: ↗ +3.2% vs semana anterior    │
└────────────────────────────────────────┘
```

**Alerts:**
- Warning: < 70% (1 hora sostenido)
- Critical: < 60% (30 min sostenido)

---

### 2. Precisión de Lead Score

**Definición:** Porcentaje de leads con score predicho correctamente, validado con conversión real.

**Fórmula:**
```
Precisión = (Leads correctamente clasificados / Total leads evaluados) * 100

Correcto si:
  - Score >= 8 Y convirtió en venta = TRUE POSITIVE
  - Score < 8 Y NO convirtió = TRUE NEGATIVE

Incorrecto si:
  - Score >= 8 Y NO convirtió = FALSE POSITIVE
  - Score < 8 Y convirtió = FALSE NEGATIVE
```

**Query SQL:**

```sql
-- Matriz de confusión
WITH lead_outcomes AS (
  SELECT
    c.id as contact_id,
    (c.custom_attributes->>'lead_score')::int as predicted_score,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM deals d
        WHERE d.contact_id = c.id
          AND d.stage = 'won'
          AND d.created_at >= c.created_at
      ) THEN 1
      ELSE 0
    END as actual_converted
  FROM contacts c
  WHERE c.custom_attributes->>'lead_score' IS NOT NULL
    AND c.created_at >= NOW() - INTERVAL '30 days'
)
SELECT
  COUNT(*) as total_leads,
  SUM(CASE WHEN predicted_score >= 8 AND actual_converted = 1 THEN 1 ELSE 0 END) as true_positives,
  SUM(CASE WHEN predicted_score < 8 AND actual_converted = 0 THEN 1 ELSE 0 END) as true_negatives,
  SUM(CASE WHEN predicted_score >= 8 AND actual_converted = 0 THEN 1 ELSE 0 END) as false_positives,
  SUM(CASE WHEN predicted_score < 8 AND actual_converted = 1 THEN 1 ELSE 0 END) as false_negatives,
  ((SUM(CASE WHEN predicted_score >= 8 AND actual_converted = 1 THEN 1 ELSE 0 END) +
    SUM(CASE WHEN predicted_score < 8 AND actual_converted = 0 THEN 1 ELSE 0 END)) * 100.0 / COUNT(*)) as precision
FROM lead_outcomes;
```

**Metas:**
- Mes 1: 80%
- Mes 3: **85%**
- Mes 6: 90%

**Dashboard Panel:**
```
┌────────────────────────────────────────┐
│ Precisión Lead Score (Último Mes)      │
│                                        │
│  Precisión Global: 87.2% ✅            │
│                                        │
│  True Positives:  142 (32%)           │
│  True Negatives:  245 (55%)           │
│  False Positives:  31 (7%)            │
│  False Negatives:  27 (6%)            │
│                                        │
│  Tendencia: ↗ +2.1% vs mes anterior   │
└────────────────────────────────────────┘
```

**Alerts:**
- Warning: < 80% (validación semanal)
- Critical: < 75% (validación semanal)

---

### 3. Tasa de Handoff

**Definición:** Porcentaje de conversaciones que requieren transferencia a agente humano.

**Fórmula:**
```
Tasa Handoff = (Conversaciones transferidas / Total conversaciones) * 100
```

**Query SQL:**

```sql
-- Tasa de handoff general
SELECT
  COUNT(CASE WHEN assignee_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*) as handoff_rate,
  COUNT(*) as total_conversations,
  COUNT(CASE WHEN assignee_id IS NOT NULL THEN 1 END) as handoffs
FROM conversations
WHERE created_at >= NOW() - INTERVAL '24 hours'
  AND inbox_id = (SELECT id FROM inboxes WHERE name = 'WhatsApp GP Bikes');

-- Tasa de handoff por razón
SELECT
  ct.custom_attributes->>'handoff_reason' as reason,
  COUNT(*) as count,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM conversations c
JOIN contacts ct ON c.contact_id = ct.id
WHERE c.assignee_id IS NOT NULL
  AND c.created_at >= NOW() - INTERVAL '7 days'
GROUP BY reason
ORDER BY count DESC;
```

**Metas:**
- Mes 1: 40%
- Mes 3: 25%
- Mes 6: **20%**

**Triggers de Handoff Válidos:**
- Lead score >= 8 (handoff intencional, deseable)
- Cliente pide explícitamente "hablar con persona"
- Worker no puede responder después de 2 intentos
- Detección de frustración (sentiment score < 3)

**Dashboard Panel:**
```
┌────────────────────────────────────────┐
│ Tasa de Handoff (Hoy)                  │
│                                        │
│  [█████     ] 22.5%                    │
│  Target: 25%  ✅                       │
│                                        │
│  Por razón:                            │
│    High Lead Score: 58% (deseable)    │
│    Client Request:  21%               │
│    Worker Error:     12%              │
│    Frustration:       9%              │
└────────────────────────────────────────┘
```

**Alerts:**
- Warning: > 30% (1 hora)
- Critical: > 40% (30 min)

---

### 4. Tiempo de Respuesta

**Definición:** Tiempo promedio desde mensaje cliente hasta respuesta IA.

**Fórmula:**
```
Tiempo Respuesta Avg = SUM(timestamp_respuesta - timestamp_mensaje) / COUNT(mensajes)
```

**Query SQL:**

```sql
-- Tiempo de respuesta promedio por worker
WITH message_pairs AS (
  SELECT
    m1.id as user_message_id,
    m1.created_at as user_timestamp,
    m2.created_at as bot_timestamp,
    EXTRACT(EPOCH FROM (m2.created_at - m1.created_at)) as response_time_seconds,
    m1.conversation_id,
    ct.custom_attributes->>'last_active_worker' as worker_name
  FROM messages m1
  JOIN messages m2 ON m2.conversation_id = m1.conversation_id
    AND m2.created_at > m1.created_at
    AND m2.message_type = 1  -- outgoing
  JOIN conversations c ON c.id = m1.conversation_id
  JOIN contacts ct ON ct.id = c.contact_id
  WHERE m1.message_type = 0  -- incoming
    AND m1.created_at >= NOW() - INTERVAL '1 hour'
    AND m2.id = (
      SELECT id FROM messages
      WHERE conversation_id = m1.conversation_id
        AND created_at > m1.created_at
        AND message_type = 1
      ORDER BY created_at ASC
      LIMIT 1
    )
)
SELECT
  worker_name,
  COUNT(*) as message_count,
  ROUND(AVG(response_time_seconds)::numeric, 2) as avg_response_time,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_seconds)::numeric, 2) as p95,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time_seconds)::numeric, 2) as p99
FROM message_pairs
WHERE worker_name IS NOT NULL
GROUP BY worker_name
ORDER BY avg_response_time ASC;
```

**SLA por Worker:**

| Worker | Target | P95 | P99 |
|--------|--------|-----|-----|
| GreetingWorker | 2s | 3s | 5s |
| LeadQualificationWorker | 5s | 8s | 12s |
| ProductCatalogWorker | 8s | 12s | 20s |
| ServiceSchedulingWorker | 10s | 15s | 25s |
| FinancingWorker | 15s | 20s | 30s |

**Metas Globales:**
- Mes 1: < 2 minutos
- Mes 3: < 1 minuto
- Mes 6: **< 30 segundos**

**Alerts:**
- Warning: P95 > 30s (10 min sostenido)
- Critical: P95 > 60s (5 min sostenido)

---

## 📊 KPIs Secundarios (P1)

### 5. Tasa de Conversión Lead-a-Venta

**Baseline:** 15% (actual sin IA)
**Meta Mes 6:** 20% (incremento del 33%)

**Query SQL:**

```sql
SELECT
  COUNT(DISTINCT c.id) as total_leads,
  COUNT(DISTINCT CASE WHEN d.stage = 'won' THEN c.id END) as converted_leads,
  COUNT(DISTINCT CASE WHEN d.stage = 'won' THEN c.id END) * 100.0 / COUNT(DISTINCT c.id) as conversion_rate
FROM contacts c
LEFT JOIN deals d ON d.contact_id = c.id
WHERE c.custom_attributes->>'lead_score' IS NOT NULL
  AND c.created_at >= NOW() - INTERVAL '30 days';
```

---

### 6. NPS (Net Promoter Score)

**Fórmula:**
```
NPS = % Promotores (9-10) - % Detractores (0-6)
```

**Pregunta (enviada por PostSaleWorker):**
> "En una escala de 0 a 10, ¿qué tan probable es que recomiendes GP Bikes a un amigo?"

**Metas:**
- Mes 1: 30
- Mes 3: 45
- Mes 6: **60**

---

### 7. Costo por Lead Calificado

**Meta:** < $2,000 COP/lead (vs $8,000 COP manual)

**Fórmula:**
```
Costo/Lead = (OpenAI API costs + Infrastructure costs) / Leads calificados
```

**Query:**

```sql
-- Calcular leads calificados en período
SELECT COUNT(*) as leads_calificados
FROM contacts
WHERE custom_attributes->>'lead_qualification_completed' = 'true'
  AND created_at >= DATE_TRUNC('month', NOW());

-- Costos mensuales (manual input desde dashboards)
-- OpenAI: $500 USD
-- Infrastructure: $200 USD
-- Total: $700 USD = $3,010,000 COP (tasa: 4,300 COP/USD)
-- Leads calificados: 1,500
-- Costo/Lead: $3,010,000 / 1,500 = $2,007 COP ✅
```

---

## 🔔 Alerting Strategy

### PagerDuty Alert Levels

**P1 - Critical (Immediate Response):**
- Tasa de errores > 10% en cualquier worker (5 min window)
- Tiempo de respuesta P95 > 30s (sustained 10 min)
- Uptime < 99% (24h window)
- OpenAI API errors > 20/min

**P2 - Warning (Response within 1h):**
- Tasa automatización < 70% (1h window)
- Lead score precision < 80% (daily calculation)
- Handoff rate > 30% (1h window)

**P3 - Info (Review next day):**
- NPS < 40 (weekly calculation)
- Cost per lead > $3,000 COP (weekly)

---

## 📈 Reporting Schedule

### Daily Reports (9am COT)

**Slack #gp-bikes-metrics:**
```
🤖 GP Bikes AI Assistant - Daily Report

📊 Yesterday (Sep 29):
• Conversations: 247
• Automation Rate: 78.3% ✅ (target: 75%)
• Avg Response Time: 4.2s ✅ (target: <30s)
• Handoffs: 22.5% ✅ (target: 25%)
• Workers Active: 8/8 ✅

🔥 Top Performers:
1. LeadQualificationWorker: 89 leads scored
2. ProductCatalogWorker: 67 recommendations
3. GreetingWorker: 112 first contacts

⚠️ Issues:
• FinancingWorker: 3 errors (P95 response time: 25s)
```

### Weekly Reports (Lunes 10am)

**Email a stakeholders:**
- Métricas primarias vs targets
- Trends semana vs semana anterior
- False positives/negatives en lead scoring
- Customer feedback highlights (NPS comments)
- Action items para la semana

### Monthly Reports (Primer Viernes del mes)

**Presentation deck:**
- Executive summary (1 slide)
- KPIs primarios con trends (4 slides)
- Worker performance deep-dive (2 slides)
- Customer testimonials (1 slide)
- Roadmap next month (1 slide)

---

## 🎯 Success Criteria por Fase

### Mes 1 (Foundation)
- [ ] Automation Rate: >= 60%
- [ ] Lead Score Precision: >= 80%
- [ ] Response Time: < 2 min
- [ ] System Uptime: >= 99%

### Mes 3 (Optimization)
- [ ] Automation Rate: >= 75%
- [ ] Lead Score Precision: >= 85%
- [ ] Response Time: < 1 min
- [ ] NPS: >= 45

### Mes 6 (Scale)
- [ ] Automation Rate: >= 80%
- [ ] Lead Score Precision: >= 90%
- [ ] Response Time: < 30 sec
- [ ] NPS: >= 60
- [ ] Conversion Rate: >= 20%

---

**Última actualización:** 30 de septiembre de 2025
**Próxima revisión:** Mensual (primera semana del mes)
