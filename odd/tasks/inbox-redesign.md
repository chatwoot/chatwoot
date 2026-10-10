# Feature: inbox-redesign

## Objective
Aplicar el diseño de la bandeja de QEVA CRM (canvas `WrQN1m9GniFikYyEfof6uJ`, artboards Bandeja oscuro/claro) sobre la bandeja de Chatwoot, manteniendo las funcionalidades.

## Decisions
- Colores: valores de Tailwind fijos solo en los componentes tocados, igual que en el login. No se cambian tokens globales `n-*` todavía. Pendiente: decidir si se pasa la paleta a tokens (afecta toda la app).
- Funcionalidad: no cambia ningún handler, filtro, ni clave i18n.

## Tasks
- [x] T1: Baseline `ConversationCard.spec.js` (4 tests verdes).
- [x] T2: Fila de conversación (`widgets/conversation/ConversationCard.vue`): bordes redondeados (`rounded-2xl`), separación con `mx-2 my-0.5`, sin separadores de borde inferior, estado activo con fondo `#E3EDFC` / `#10264A`.
- [ ] T3: Pestañas de asignación (`ChatTypeTabs`) y encabezado de la lista (`ChatListHeader`).
- [ ] T4: Encabezado y composer del hilo (`ConversationHeader.vue`, `ReplyBox.vue`).
- [ ] T5: Burbujas (`components-next/message/bubbles/Base.vue`, `Text/Index.vue`).
- [ ] T6: Panel de contacto (`ContactPanel.vue`, `ConversationInfo.vue`).
- [ ] T7: Barra lateral (`components-next/sidebar/Sidebar.vue`).

## Verification
- T2: `ConversationCard.spec.js` 4/4, `eslint` sin errores. Sin RED significativo para CSS (excepción explicada en `login-redesign.md`).
- Pendiente de verificación visual: no revisado en navegador.

## Next step
T3.
