# Beet Digital App: Plan de Trabajo para la Extensión de Chatwoot

## Resultado Deseado

Desarrollar una extensión de Chatwoot completamente funcional que sirva como puente entre los canales de comunicación externos (principalmente WhatsApp) y los protocolos de automatización internos. El producto final debe integrarse de manera fluida y nativa en el ecosistema del fork de Chatwoot, adoptando su UI/UX y arquitectura.

---

## Características Principales

1.  **Canal (WhatsApp):** Mejorar y ampliar el manejo de mensajes de WhatsApp, incluyendo soporte completo para:
    *   Mensajes de Texto
    *   Mensajes Interactivos (botones, listas)
    *   Mensajes de Anuncios (Ads)
    *   WhatsApp Flows
    *   Mensajes de Producto
    *   Mensajes de Audio y Multimedia (imágenes, videos, documentos)

2.  **Inteligencia (Automatización MCP):** Implementar automatizaciones basadas en el **MCP (Model Context Protocol)** para gestionar el contexto de la conversación y ejecutar acciones del lado del servidor de forma inteligente, basadas en los diferentes estados de la conversación.

---

## Requisitos de Arquitectura

*   **Frontend:** La interfaz de usuario se construirá utilizando **Vue.js** y **TypeScript**, replicando el diseño nativo de Chatwoot para una experiencia de usuario cohesiva.
*   **Backend:** La lógica de negocio y el servidor MCP se implementarán con servicios robustos en **TypeScript**.
*   **Contexto de Origen:** Se analizará un prototipo existente (Node.js y Next.js) para extraer su lógica y objetivos de negocio. Sin embargo, el código se **re-implementará desde cero** para adaptarse a la nueva arquitectura MCP y la pila tecnológica de Vue.js + TypeScript.

---

## Plan de Trabajo

### Fase 1: Configuración de Producción V1 (Baseline)

**Objetivo:** Establecer un entorno de producción inicial y estable en Kubernetes (GKE) utilizando Terraform. Esta instancia servirá como la base para todo el desarrollo futuro.

**Restricciones:**
*   **Código:** Utilizar el código fuente actual "as-is", sin aplicar refactorizaciones ni nuevas funcionalidades.
*   **Base de Datos:** Conectar a una instancia gestionada de PostgreSQL en GCP (Cloud SQL).
*   **Seguridad:** Implementar estrictamente el patrón de **sidecar con Cloud SQL Auth Proxy** para la conexión entre los pods de Kubernetes y la base de datos, sin exponer IPs públicas.

**Tareas Clave:**

1.  **Infraestructura como Código (IaC) con Terraform:**
    *   Crear los scripts de Terraform para provisionar el clúster de GKE.
    *   Definir la configuración de la instancia de Cloud SQL (PostgreSQL).
    *   Establecer las reglas de red y firewall necesarias en GCP.

2.  **Configuración de Kubernetes:**
    *   Desarrollar los manifiestos de Kubernetes (Deployment, Service, etc.) para la aplicación.
    *   Configurar el `Deployment` para incluir el contenedor de la aplicación y el sidecar de Cloud SQL Auth Proxy.
    *   Asegurar que las variables de entorno y los secretos para la conexión a la base de datos apunten al proxy local.

3.  **Red y Dominios:**
    *   Configurar los recursos de **Ingress** en Kubernetes.
    *   Mapear los dominios personalizados a los servicios correspondientes para exponer la aplicación de forma segura.

4.  **Despliegue y Validación:**
    *   Ejecutar el pipeline de despliegue para levantar la infraestructura y la aplicación.
    *   Verificar que la aplicación esté corriendo, sea accesible a través del dominio personalizado y tenga conectividad con la base de datos.

**Entregable:** Una instancia de la aplicación funcionando en un entorno de producción estable, que servirá como punto de partida para las siguientes fases.

---

### Fase 2: Análisis del Prototipo y Re-implementación de la Arquitectura

**Objetivo:** Extraer la lógica de negocio del prototipo legacy y construir la estructura base del nuevo servicio siguiendo la arquitectura de Vue.js y TypeScript con MCP.

**Tareas Clave:**

1.  **Análisis del Prototipo:** Revisar el código Node.js/Next.js para documentar flujos de datos, lógica de negocio y funcionalidades clave.
2.  **Diseño de Arquitectura MCP:** Definir los contratos y esquemas del protocolo para la comunicación cliente-servidor.
3.  **Andamiaje del Proyecto:** Crear la estructura del proyecto con un backend en TypeScript y un frontend en Vue.js, listos para integrarse en Chatwoot.

**Entregable:** Un repositorio con la nueva estructura de proyecto y la arquitectura base de MCP implementada.

---

### Fase 3: Desarrollo de Características Principales

**Objetivo:** Implementar las funcionalidades completas de manejo de WhatsApp y las automatizaciones MCP.

**Tareas Clave:**

1.  **Manejo Avanzado de WhatsApp:** Desarrollar los componentes de Vue.js y la lógica de backend para soportar todos los tipos de mensajes definidos.
2.  **Implementación de Automatizaciones MCP:** Crear los servicios de automatización en el backend y las acciones del lado del servidor.
3.  **Integración y Pruebas:** Integrar la extensión en el fork de Chatwoot y realizar pruebas end-to-end.

**Entregable:** La extensión de Chatwoot completamente funcional e integrada.
