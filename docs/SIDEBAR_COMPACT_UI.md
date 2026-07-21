# Sidebar Compact UI — Notas de trabajo

**Fecha:** 2026-07-21  
**Rama actual:** `hotfix/conversation-status-webwidget`  
**Objetivo:** Reducir el espacio vertical del panel lateral derecho de conversaciones en Chatwoot para aprovechar mejor la pantalla.

---

## Cambios aplicados

### 1. Layout general del sidebar (`ContactPanel.vue`)
- Reducir espaciado entre secciones (`gap-2` en lugar de `gap-3`).
- Reducir padding inferior (`pb-2` en lugar de `pb-8`).
- Pasa la prop `compact` a todos los `AccordionItem` del sidebar, incluyendo `conversation_participants`.
- Ocultar los badges destacados repetidos dentro de la sección `contact_attributes` para evitar duplicar información.

### 2. Acordeón (`AccordionItem.vue`)
- Padding del header y contenido más pequeño.
- Título `text-xs font-medium tracking-wide` sin `uppercase` ni negrita.
- Icono y chevron ligeramente reducidos.
- Soporta prop `compact`.

### 3. Selectores de acción (`ConversationAction.vue`)
- Wrapper en `flex flex-col gap-1.5` para agrupar labels y controles.
- `ContactDetailsItem` con prop `compact` para las labels.
- `MultiselectDropdown` con prop `compact` para equipo y prioridad.
- `ConversationAssigneeSelector` con prop `compact-dropdown` para mantener el dropdown completo del sidebar sin afectar el header.

### 4. Selector de agente (`ConversationAssigneeSelector.vue`)
- Nuevo prop `compactDropdown` que compacta solo el dropdown cuando se usa desde el sidebar, manteniendo el layout split original cuando se usa en el header.

### 5. Dropdown compartido (`MultiselectDropdown.vue`)
- Soporta prop `compact`.
- Botón con altura fija `h-8`, padding reducido y tamaño de texto `text-sm`.
- Avatar del ítem seleccionado más pequeño.

### 6. Opciones del dropdown (`MultiselectDropdownItems.vue`)
- Nuevo prop `compact`.
- Items con altura reducida, texto `text-sm`, avatar más pequeño.
- Input de búsqueda compacto.

### 7. Atributos personalizados
- `ConversationInfo.vue`: pasa prop `compact` a `CustomAttributes`.
- `CustomAttributes.vue`: acepta y propaga `compact` a cada `CustomAttribute`.
- `CustomAttribute.vue`: render compacto con padding reducido, label sin negrita y dropdown `compact`.

### 8. Items de detalle de contacto (`ContactDetailsItem.vue`)
- Labels en `text-xs font-medium tracking-wide`.
- Sin `uppercase` ni negrita.
- Sin margin inferior en modo `compact`.

---

## Cómo probar

1. Abrir una conversación en el dashboard.
2. Verificar que el panel derecho de contacto/conversación tenga menos espacio entre secciones.
3. Confirmar que los acordeones son más pequeños y los títulos no están en mayúsculas.
4. Confirmar que el dropdown de agente en el sidebar sigue siendo completo (muestra foto + nombre + estado).
5. Revisar que los atributos personalizados (Monto, Título, etc.) estén compactos.

---

## Notas de build / Docker

- El entorno productivo (container) no usa Vite HMR; sirve assets precompilados de `/app/public/vite/`.
- `app/` sí está montado como bind mount, pero `/app/public/vite/` NO está montado.
- Para ver cambios en el container:
  1. `pnpm exec vite build` en host.
  2. Copiar el contenido de `public/vite/` al container.
  3. Reiniciar el container (`docker restart chatwoot-chatwoot-rails-1`).
- Si el navegador cachea bundles viejos, asegurarse de que el build tenga hashes nuevos y recargar en ventana de incógnito.

---

## Problemas encontrados y soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| No se veían cambios en el container | `public/vite/` no está montado | Copiar assets compilados al container y reiniciar |
| Navegador mostraba versión vieja | Cache de assets estáticos | Usar build con hash nuevo + probar en incógnito |
| Errores 404 de archivos estáticos | Faltaban archivos en el destino del container | Copiar todo el directorio `public/vite/` completo |
| Dropdown del agente en sidebar quedó cortado | Se reutilizó el componente split del header | Agregar prop `compact-dropdown` en `ConversationAssigneeSelector` |
| Badges repetidos en atributos destacados | Render duplicado en `ContactPanel.vue` | Ocultar badges dentro de la sección de atributos |

---

## Estado actual

- Los cambios fueron visibles y aprobados por el usuario en el navegador.
- **Caveat:** al momento de escribir estas notas, algunos archivos fuente parecen haber vuelto a su estado original. Verificar con `git diff` antes de regenerar el build, o re-aplicar los cambios si aún se desea mantenerlos.
- Aún no se crea la rama ni el commit con estos cambios.
- Pendiente: ejecutar `pnpm eslint:fix` y crear commit local.

---

## Archivos relevantes

- `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`
- `app/javascript/dashboard/components/Accordion/AccordionItem.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue`
- `app/javascript/dashboard/components/widgets/conversation/ConversationAssigneeSelector.vue`
- `app/javascript/shared/components/ui/MultiselectDropdown.vue`
- `app/javascript/shared/components/ui/MultiselectDropdownItems.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/ContactDetailsItem.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/ConversationInfo.vue`
- `app/javascript/dashboard/components/CustomAttribute.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue`
- `public/vite/` (assets compilados)
