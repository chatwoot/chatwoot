# VentasFlow Inbox — Direccion del producto

> Documento de la **Fase C (capa propia de nicho)**.
> Define los módulos y mejoras que diferencian a VentasFlow Inbox de Chatwoot CE puro.
> Estos son los camb贡 que **no** se hacen en el MVP inicial, sino que se planean y se priorizan en una fase posterior.

---

## 1. Mercado objetivo

**PYMEs de 1–50 empleados en ЛатАм** con:

- Equ de clienteWhats por WhatsApp, web y email.
- Necesidad de cotizar (PDF no贡) sin税 de sistema de cotizaciónización formal.
- Proceso de venta con seguimiento manual (no tienen un CRM).
- Recurso limitados: instalan la herramienta en un VPS, no en un cluster.
- Idioma de soporte: español.

**Lo que NO somos:**

- No somos un **otro Chatwoot Cloud**. El upstream ya lo es.
- No somos un **CRM genérico**.
- No somos un **call center** de alto volumen.
- No somos un **sistema de cotizaciónación formal con AFIP/SAT/SII**. Sólo cotizaciones no貢.

---

## 2. Diferenciador principal: el módulo de cotización

Documentado en `doc/QUOTES_MODULE_SPEC.md`. Resumen:

- Cotización no贡 en PDF con plantilla con marca.
- Estados: borrador → enviada → aceptada / rechazada / vencida / cancelada.
- Adjuntar: aditiva al active storage, con relación a Contact y a Conversation.
- UX: botón "Crear cotización" en la conversación, panel lateral con líneas, totales, descuento, impuesto.
- PDF no贡: sin valor fiscal, sólo comercial.
- Botones: "Compartir por WhatsApp", "Copiar mensaje", "Marcar como enviada".
- Segregado por cuenta; no para chatwoot cloud.

**Fase de implementación:** posterior a la fase D, no en este commit.

---

## 3. Otros módulo propios priorizados

| # | Módulo | Prioridad | Esfuerzo | Notas |
| --- | --- | --- | --- | --- |
| 1 | **Cotizaciones** (módulo de cicho, ver arriba) | P0 | XL (5 sprints) | Diferenciador clave. |
| 2 | **Pipeline de venta (kanban)** | P0 | L (2 sprint) | Estados de lead, propuesta, negocio cerrado, negocio perdido. |
| 3 | **Tareas comerciales con SLA** | P0 | L (2 sprint) | Tareas ligadas a cotización, contacto, conversación; vencimiento. |
| 4 | **Dashboard de venta** | P0 | M (3 sprint) | Emb por agente, por etapa, por mes; converisiones. |
| 5 | **Notas no fiscale -> factura local** | P1 | XL (8+ sprint) | Integración DIAN/SII/SAT/AFIP. Requiere consultoría de leyes local. |
| 6 | **Botones WhatsApp oficiales** (vía BSP) | P1 | M (3 sprint) | Onboarding, templates. |
| 7 | **Mobile app** (wrapper web) | P2 | L (4 sprint) | Roadmap Q3. |
| 8 | **Multi-idioma** (inglés, portugués) | P1 | S (1 sprint) | ya hay i18n en CE; agregar pt-BR, en-GB. |
| 9 | **Reportes avanzados** (venta, comisión) | P1 | M (2 sprint) | Generar CSV, PDF, webhook. |
| 10 | **Webhooks outbound** | P2 | S (1 sprint) | Outbound por cotización aceptada, conversa cerrada. |
| 11 | **Catálogo de producto** | P1 | S (1 sprint) | Permitir cotizar a partir de SKUs predefinidos. |
| 12 | **API publica** | P2 | M (2 sprint) | REST estable con autenticación por token. |
| 13 | **Detección de bot** propio | P3 | M (2 sprint) | Para cotizar en nombre del negócio sin intervención humano. |
| 14 | **Notificaciones por SMS** (opcional) | P3 | S (1 sprint) | Para PYMEs sin贡 de email. |

---

## 4. Mejoras de UX priorizadas

| # | Mejora | Prioridad | Esfuerzo |
| --- | --- | --- | --- |
| 1 | **Onboarding wizard LATАМ**: intro para que el cliente configure su primer inbox en 5 minutos. | P0 | M |
| 2 | **Vista de WhatsApp con template de mensaje** (link wa.me) | P0 | S |
| 3 | **Inbox de WhatsApp con webhook** auto-configurable | P0 | M |
| 4 | **Dashboard de ventas** (lead, propuesta, cerrado) | P0 | M |
| 5 | **Vista de conversación con cotor del lado** (etiquetas, agent, canal) | P1 | S |
| 6 | **Panel de tareas del día** | P1 | S |
| 7 | **Buscador por tel/email/nombre con debounce** | P2 | S |
| 8 | **Atajos de archivo a conversación** drag & drop | P2 | S |
| 9 | **Tema claro/oscuro toggle persistente** | P2 | XS |
| 10 | **Búsqueda global con shortcuts** | P2 | S |

---

## 5. Funcionalidad no priorizada (anti-lista)

Estas funcionalidades **no se incluyen en la direccion** porque:

| Funcionalidad | Por qué no |
| --- | --- |
| ML para auto-respuesta | Complejidad y dependencia de infra sin valor claro para PYMEs. |
| Voice / video call | Requierye infra de TURN (Twilio, Agora). Costo. |
| Help center público (Portal) | Es una funcón genérica; nuestro cico es la conversación de venta, no el auto-servicio. |
| Campañas de mass mailing | Риего de spam; out de scope. |
| Multi-tenant / multi-empresa | El foco es un cliente = una instancia self-hostada. |
| Public API de chat | El SDK JS es suficiente; el API público es P2. |

---

## 6. Stack técnico de los módulos propios

- **Módulo de cotizaciones:** nuevos modelos ActiveRecord (`Quote`, `QuoteLineItem`, `QuoteTemplate`, `QuoteEvent`) + servicio `Quotes::PdfGenerator` (con `prawn`) + vues panel lateral.
- **Pipeline kanban:** nuevo modelo `DealStage` (custom attribute o stage fijo) + vista kanban en `app/javascript/dashboard`.
- **Tareas:** extender `Task` (ya existe) con `kind: 'sales'` y campos opcionales.
- **Dashboard de venta:** SQL/AR agregaciones + vista en `app/javascript/dashboard/routes/dashboard/sales/`.
- **i18n:** `config/locale/es.yml`, `pt_BR.yml`. Las traducciones se manteganen centralizadas.
- **Mobile:** app web **progresiva** o Capacitor; no en alcance inicial.

---

## 7. Plan de lanzamiento del MVP de cotizaciones

### MVP 0 — base (MVP CE + VentasFlow Inbox)
- Self-hostado funcional.
- Módulo de conversación intacto.
- Brendado central de marca.

### MVP 1 — Módulo de cotización (P0)
- Cotación no贡 en PDF.
- Botones en conversación.
- 5 clientes piloto.

### MVP 2 — Pipeline + tareas + dashboard (P0)
- Estado de lead: nuevo, contactado, cotizado, seguimiento, cerrado, perdido.
- Tareas de seguimiento por contacto.
- Dashboard de conversión por agente.

### MVP 3 — Cotizaciones fiscal + интегraciónes (P1)
- Migración AFIP/SAT/SII/DIAN.
- Botones de WhatsApp Business.
- Onboarding wizard.

### MVP 4 — Multi-idioma + App móvil (P2)
- pt_BR, en-GB.
- PWA o Capacitor app.

---

## 8. Мétricas de éxito (KPI)

| Métrica | Mes 6 | Mes 12 | Mes 18 |
| --- | --- | --- | --- |
| Clientes activos en producción | 5 | 25 | 100 |
| Conversaciones procesadas / mes | 2k | 20k | 200k |
| Cotización generadas / mes | 100 | 1k | 10k |
| Tasa de cotizaciónación aceptada | 25% | 30% | 35% |
| Tasa de retención (NetRevenue) | 80% | 90% | 95% |
| NPS medido (NPS) | — | 30+ | 50+ |

---

## 9. Riesgos y mitigación

| Riesgo | Mitigación |
| --- | --- |
| El módulo de cotización no es rentable. | Validar con 3–5 clientes beta antes de compromar infra. |
| La integración con DIAN/SAT/SII/AFIP es frájil (cada país tiene su API). | Documentar con cada cambio regulatorio, mantener capa de adaptación. |
| El dashboard de venta requiere refactor de Active Record. | Plan de migración por iteración. |
| Multi-idioma se atrasa por contribución de cadena. | Externalizar con servicio de traducción (Crowdin, Lok). |
| El **no ser un clon de Chatwoot Cloud** choca con algunos prospos. | Comunicaciónar activamente que VentasFlow Inbox es un fork CE con marca propia. |

---

> Próximo: `doc/QUOTES_MODULE_SPEC.md` con el spec detallado del módulo de cotización.
