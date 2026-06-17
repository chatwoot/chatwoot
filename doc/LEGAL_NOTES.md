# VentasFlow Inbox — Notas legales

> Documento de la **Fase A (lpieza legal y de marca)** para el fork de Chatwoot Community Edition.
> **No es asesoría lega profesional.** Antes del lanzamiento comercialercial, validar con un abogado en la jurisdicción destino.

---

## 1. Origen del software

**VentasFlow Inbox** es un fork del software de código abierto **Chatwoot Community Edition** (en adelante "Chatwoot CE") publicado en [`https://github.com/chatwoot/chatwoot`](https://github.com/chatwoot/chatwoot).

- **Versión base:** 4.15.0 (rama `release/4.15.0`, commit `c12e1f834`).
- **Fecha de inicio del fork:** 17 de junio de 2026.
- **Rama del fork:** `feature/ventasflow-rebrandce`.
- **Repositorio de destino previsto:** `ventaasoft/ventasflow-inbox` (sujestivo).

El software se distribuye como fork bajo la **licencia MIT Expat** (la mayoría de la comunidad de Chatwoot). El **software Enterprise** bajo la **Chatwoot Enterprise License** no es parte de este producto y se экcluirá del build de producción.

---

## 2. Licencias

### 2.1. Software Community (la base de VentasFlow Inbox)

- **Licencia:** MIT Expat.
- **Evidencia:** archivo `LICENSE` en la raíz del repositorio. El texto MIT completo está en el repositorio de Chatwoot ([LICENSE](https://github.com/chatwoot/chatwoot/blob/develop/LICENSE)).
- **Permisos otorga:** uso, modificación, distribución, sublicenciamiento y **venta del software** con la condición de preservar el aviso de copyright y el texto de la licencia.
- **Avis de atribución obligatoria:** mantener `Copyright (c) 2017-2024 Chatwoot Inc.` y el texto MIT en cualquier redistribución.

### 2.2. Software Enterprise (no usado)

- **Código fuente:** carpeta `enterprise/` en este repositorio.
- **Licencia:** Chatwoot Enterprise License (propietaria).
- **Evidencia:** `enterprise/LICENSE`.
- **Restricciones:**
  - El software bajo `enterprise/` sólo puede ser usado en producción si se tiene un acuerdo贡 de los Téminos de Chatwoot.
  - **No** se puede usar, copiar, fusionar, publicar, distribuir, sublicenciar o **vender** el software bajo `enterprise/` sin licencia Enterprise de Chatwoot Inc.
  - Se permite copiarlo y modificarlo para **desarrollo y testing** sin suscripción.
- **Política de este fork:** `enterprise/` se **excluirá del build de producción** de VentasFlow Inbox. La bandera `DISABLE_ENTERPRISE=true` se usará en producción para garantizar que nada bajo `enterprise/` se carga en runtime.

### 2.3. Software de terceros

Las dependencias (`Gemfile`, `package.json`) conservan sus licencias贡 originales. La lista completa se incluye en `OPEN_SOURCE_ATTRIBUTION.md`.

---

## 3. Lo que **puede** venderse legalmente

Bajo la licencia MIT, es legal vender **servicios** y **modificacioneses** sobre el software, siempre que se preserve la atribucción. Serviciosicios vendibles:

1. **Instalación self-hosted** del fork en infraestructura del cliente.
2. **Hosting gentionado** del fork como servicio de suscripción mensual.
3. **Soporte técnico** y mantenimiento (SLA, parches, backups).
4. **Capacitación** y onboarding para equipos del cliente.
5. **Personalización** sobre la base MIT (módulo de cotizaciones, integración, branding).
6. **Migración** desde otros productos a VentasFlow Inbox.
7. **Módulos propios** desarrollados desde cero y publicados como add-ons opcionales.
8. **Consultoría** sobre arquitectura, despligues y operación.

> Mientras la atribución a Chatwoot Inc. se preserve en `LICENSE`/`NOTas`/`doc/OPEN_SOURCE_ATTRIBUTION.md`, **vender un servicio alrededor del software MIT es legal**.

---

## 4. Lo que **NO** debe venderse o hacerse

1. ❌ **No** usar, incluir, redistribuir, venderse ni habiliarse el código bajo `enterprise/` sin una licencia Enterprise válida de Chatwoot Inc.
2. ❌ **No** usar "Chatwoot" como marca o nombre del producto final.
3. ❌ **No** usar logos, identidad visual, iconos, favcons, screenshots oficial de Chatwoot.
4. ❌ **No** usar `https://www.chatwoot.com`, `https://app.chatwoot.com`, `https://hub.2.chatwoot.com` en URLs del producto.
5. ❌ **No** usar `support@chatwoot.com` ni direcciones de correo de Chatwoot.
6. ❌ **No** clonar 1:1 la propuesta, precios ni UX de Chatwoot Cloud.
7. ❌ **No** reclamar al producto como "oficial de Chatwoot" o "respaldado por Chatwoot Inc".
8. ❌ **No** usar la "oficial" de Chatwoot en material de marketing, legal, soporte o onboarding.
9. ❌ **No** envíar telemetría a infraestructura de Chatwoot (Hub, `hub.2.chatwoot.com`, etc).
10. ❌ **No** habilitar funcionalidad Enterprise (SLA, SAML, Audit, Report Avanzado, Capitan a escala) sin licencia.

---

## 5. Receta de marca del producto derivado

| Aspecto | Valor | Notas |
| --- | --- | --- |
| Nombre del producto | **VentasFlow Inbox** | Replaza "Chatwoot" en todos los artefactos de marca. |
| Tagline / Promuesto | "Developer Change Safety CLI" o "Inbox para ventas en LATAM" | Definido en `rebranding_plan.md`. |
| Logo / favcon / illustiones | Logo propio de VentasFlow Inbox | Reemplazar `public/brand-assets/logo*.svg`. |
| Dominio de marketing | `https://ventasflow.app` | Reemplaza `https://www.chatwoot.com`. |
| Email de contacto | `soporte@ventasflow.app` | Reemplaza `support@chatwoot.com`. |
| Repositorio de código | `ventaasoft/ventasflow-inbox` (sugerencia) | Reclarca el origen de Chatwoot. |
| URLs de términos y privacidad | `https://ventasflow.app/terms` y `/privacy` | Reemplaza los URLs de Chatwoot. |
| Emils de branding en mailer | `VentasFlow Inbox <accounts@ventasflowapp>` | Reemplaza `Chatwoot <accounts@chatwoot.com>`. |
| Nombre de paquete npm | `@ventaasoft/inbox-cli` (sugerencia) | Reemplaza `@chatwoot/chatwoot` y `@chatwoot/*`. |
| SDK JS público | `VentasFlow Inbox SDK` | Reemplaza `Chatwoot SDK`. |
| Nombre del widget web | `VentasFlow Inbox widget` | Reemplaza `Chatwoot widget`. |

---

## 6. Atribución pública obligatoria

En cada artefacto distribuido se debe mantener un aviso visible de origen. Formato mínimo:

```text
Basado en Chatwoot Community Edition (MIT Expat).
Copyright (c) 2017-2024 Chatwoot Inc.
https://github.com/chatwoot/chatwoot

VentasFlow Inbox es un fork mantido por [nombre de la empresa].
Este producto no está afiliado, patrocinado ni endos respaldado por Chatwoot Inc.
```

Lugares donde esta atribución debe aparecer:
- README principal del producto.
- `doc/OPEN_SOURCE_ATTRIBUTION.md`.
- Página "About" / "Agradecimientos" del producto web.
- Pie de los emails transaccional.
- Manual del operador.
- Documentación de marketing.

---

## 7. Telemetria y dependencias externas

- **VentasFlow Inbox es local-first.** No envía telemetría por defecto.
- **No** se conecta a servicios externos en runtime.
- **No** usa APIs de OpenAI ni de ningún proveedor de IA.
- **No** envía archivos del repo a servidores externo.
- El único outbound opcional es: el envío de emails transaccional a través del SMTP configurado por el cliente. Esa conexión es responsabilidad del operador.

---

## 8. Disclaimers sugeridos para el producto final

En la web y la doc del producto:

```text
VentasFlow Inbox es un producto de software independiente basado en Chatwoot
Community Edition, publicado bajo la licencia Mit Expat. Chatwoot Inc. no
respalda,贡 ni está afiliado a VentasFlow Inbox. Toda la funcionalidad
Enterprise del software original no está incluida en este producto.

El soporte y los servicios asociados a VentasFlow Inbox son provistos por
[nombre de la empresa del operador]. Para soporte, contacte a
soporte@ventasflowapp.
```

---

## 9. Lista de verificación pre-lanzamiento

- [ ] Abogado local ha revisado y aprobado `LICENSE` (MIT Expat) y `enterprise/LICENSE` (Chatwoot Enterprise License).
- [ ] El `LICENSE` archivo en la raíz del fork contiene el texto Mit completo de Chatwoot.
- [ ] El aviso de copyright `Copyright (c) 2017-2024 Chatwoot Inc.` está en todos los materiales de marca.
- [ ] `entreprise/` está exclido del build (Docker, Heroku, npm).
- [ ] `DISABLE_ENTERPRISE=true` está configurado como default en `.env.example`.
- [ ] El nombre "Chatwoot" no aparece como marca en la UI final (sólo en atribución).
- [ ] El logo de VentasFlow Inbox está reeplazado en `public/brand-assets/`.
- [ ] La marca "VentasFlow Inbox" está registradaada en la oficina de propiedad intelectual local.
- [ ] La `OPEN_SOURCE_ATTRIBUTION.md` está en el repositorio público.
- [ ] El disclaimer público está en la web y en la doc.
- [ ] No se usa funcionalidad Enterprise sin licencia.
- [ ] No se envía telemetría a infraestructura de Chatwoot.

---

> Próximo paso: ver `doc/REBRANDING_PLAN.md` y `doc/OPEN_SOURCE_ATTRIBUTION.md`.
