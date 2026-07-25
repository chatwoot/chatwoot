# Sidebar Compact UI — Visibilidad y categorías

**Fecha:** 2026-07-24  
**Rama:** `feat/sidebar-compact-ui`  
**Objetivo:** Compactar el panel derecho de conversación y dejar que cada agente muestre, oculte y reordene secciones y categorías de atributos personalizados.

---

## Qué hace

### Menú de visibilidad (3 puntos junto a la X)

Componente: `SidebarVisibilityMenu.vue` en el slot `#actions` de `SidebarActionsHeader`.

1. **Secciones** del panel (acciones, info, atributos de contacto, macros, …): checkbox + drag para reordenar.
2. **Categorías** anidadas bajo `conversation_info` y `contact_attributes` (solo si hay 2+ categorías): checkbox + drag.
3. **Reset** restaura secciones visibles, orden default y preferencias de categorías.

Preferencias en `ui_settings` del agente (sin migración):

| Key | Uso |
|-----|-----|
| `conversation_sidebar_visible_items` | Nombres de secciones visibles |
| `conversation_sidebar_items_order` | Orden de secciones (ya existía) |
| `conversation_sidebar_visible_categories` | `{ conversation_attribute: [slugs], contact_attribute: [slugs] }` — clave ausente = todas visibles |
| `conversation_sidebar_category_order` | Orden de carpetas por `attributeType` |

Metadatos estáticos (browser, IP, referer) siguen visibles siempre que `conversation_info` esté activa.

### Atributos personalizados

En `CustomAttributes.vue`:

- Eliminado **Ver más / Ver menos** (ya no se truncan a 5).
- Carpetas por categoría siempre que haya 2+ categorías **visibles**.
- Filtrado y orden de carpetas respetan las preferencias del menú.
- Drag de atributos siempre habilitado.

Helpers compartidos en `useUISettings.js`: `attributeCategorySlug`, `SIDEBAR_SECTION_ATTRIBUTE_TYPE`.

---

## Cómo probar

1. Abrir una conversación → panel derecho → ⋯ junto a cerrar.
2. Ocultar una sección (ej. Macros) → desaparece; Reset la restaura.
3. Drag de secciones → el orden persiste al recargar.
4. Con atributos categorizados: bajo Conversation info / Contact attributes, ocultar categoría X → solo quedan las otras; drag de categorías cambia el orden de carpetas.
5. Confirmar que no hay botón Ver más/menos.
6. Metadatos browser/IP siguen si Conversation info está on.
7. Preferencias sobreviven refresh.

---

## Archivos relevantes

- `app/javascript/dashboard/routes/dashboard/conversation/SidebarVisibilityMenu.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue`
- `app/javascript/dashboard/composables/useUISettings.js`
- `app/javascript/dashboard/components-next/SidebarActionsHeader.vue`
- `app/javascript/dashboard/components/Accordion/AccordionItem.vue` (`compact`)
- `app/javascript/dashboard/i18n/locale/en/conversation.json` / `es/conversation.json`

---

## Notas Docker / assets

- `app/` montado: cambios Vue se ven tras restart de Rails si el bundle es el de la imagen, o con Vite build + copiar `public/vite/` según el flujo local.
- Ver `AGENTS.md` (restart vs rebuild).
