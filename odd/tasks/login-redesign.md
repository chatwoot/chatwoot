# Feature: login-redesign

## Objective
Aplicar el diseño nuevo de QEVA CRM (canvas `WrQN1m9GniFikYyEfof6uJ`, artboards Ingreso oscuro/claro) a la pantalla de login de `app/javascript/v3/views/login/Index.vue`.

## Scope (this feature, first delivery)
- Solo la plantilla y clases Tailwind de `Index.vue`. La lógica (MFA, SSO, SAML, Google OAuth, impersonation, errores) no cambia.
- Textos con claves i18n existentes (`LOGIN.*` en `en.json`). No hay strings nuevos hardcodeados.
- Sin cambios globales de tokens (`_next-colors.scss`, `theme/colors.js`). La paleta del canvas queda para un feature aparte.

## Out of scope
- Paleta global del producto, tipografía global, bandeja de conversaciones, widget.

## Constraints (AGENTS.md)
- Tailwind only, sin CSS scoped ni estilos inline.
- `<script setup>` no aplica a este archivo (ya usa Options API); no se migra en este feature.
- Usar tokens `n-*` existentes.

## Tasks
- [ ] T1: Baseline: `pnpm vitest run app/javascript/v3/views/login/Index.spec.js` (5 tests verdes antes del cambio).
- [ ] T2: Restyle de la tarjeta de login (contenedor, radio, borde, padding, ancho máximo) con tokens `n-*`.
- [ ] T3: Ajuste de jerarquía del título y del texto de apoyo.
- [ ] T4: Verificar que los 5 tests siguen verdes y que el lint pasa (`pnpm eslint` sobre el archivo).

## Test-first policy
Los specs existentes cubren la lógica, no el aspecto visual. No hay un RED significativo para CSS: la excepción se explica y se usan checks estructurales (tests + eslint). Ningún test de lógica cambia.

## Route declaration
- T2-T3: inline (un solo archivo, sin investigación pendiente).

## Progress and evidence
- T1: pendiente.
