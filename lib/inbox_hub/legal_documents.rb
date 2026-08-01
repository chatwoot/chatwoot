# frozen_string_literal: true

# Mirror of Panel AI legal pages (ainbox) for InboxHub domain (inbox.paluhub.com).
module InboxHub
  module LegalDocuments
    LOCALES = %w[en es].freeze
    DOCS = %w[privacy terms data-deletion].freeze
    LAST_UPDATED = '2026-08-01'
    SUPPORT_EMAIL = 'soporte@paluhub.com'

    NAV = {
      'en' => {
        'privacy' => 'Privacy',
        'terms' => 'Terms',
        'data-deletion' => 'Data deletion'
      },
      'es' => {
        'privacy' => 'Privacidad',
        'terms' => 'Términos',
        'data-deletion' => 'Eliminación de datos'
      }
    }.freeze

    module_function

    def fetch(locale, doc_id)
      locale = LOCALES.include?(locale) ? locale : 'en'
      raise ArgumentError, "unknown doc #{doc_id}" unless DOCS.include?(doc_id)

      CONTENT.fetch(locale).fetch(doc_id)
    end

    def path_for(locale, doc_id)
      "/#{locale}/#{doc_id}"
    end

    # rubocop:disable Metrics/CollectionLiteralLength
    CONTENT = {
      'en' => {
        'privacy' => {
          title: 'Privacy Policy for InboxHub',
          last_updated: LAST_UPDATED,
          intro: 'At PaluHub (“we”, “us”), we operate InboxHub, a multi-channel customer communication platform built on a Chatwoot-based framework and optional AI assistants (Panel AI). This Privacy Policy explains what data we collect when you connect channels such as TikTok, WhatsApp, Instagram, Facebook Messenger, and Email, and how that data is used—especially when AI features are enabled.',
          sections: [
            { heading: '1. Who we are', paragraphs: ['InboxHub is a product operated by PaluHub. It is an independent software platform that integrates official third-party APIs (including TikTok and Meta). We are not affiliated with, endorsed by, or sponsored by TikTok, Meta, OpenAI, Anthropic, or other platform providers.'] },
            { heading: '2. Data we collect', paragraphs: ['Depending on the channels you connect and the permissions you grant, we may collect and process:'], bullets: ['Public profile information from TikTok and other connected platforms (for example display name, avatar, and public identifiers).', 'Direct messages and conversation content exchanged with your business through connected inboxes.', 'Comments and related public interaction data where the connected API exposes them for customer support use cases.', 'Media metadata for images, audio, and video attached to conversations (and, where permitted, media content needed to display or process the message).', 'Account and workspace data for InboxHub users (name, email, organization, roles, billing-related records).', 'Technical logs needed to operate the service (timestamps, delivery status, webhook events, error diagnostics).'] },
            { heading: '3. How we use information', paragraphs: ['Data is processed to centralize business communication and improve customer response through optional artificial intelligence models. Specifically, we use information to:'], bullets: ['Display conversations in a unified InboxHub dashboard for your agents.', 'Route, assign, label, and escalate conversations according to your configuration.', 'Power AI assistants that draft or send automated replies when you enable them.', 'Provide knowledge features (for example document retrieval / RAG) that you configure.', 'Operate billing, security, abuse prevention, and support.'] },
            { heading: '4. AI processing', paragraphs: ['When AI features are enabled for your organization, messages and related context may be processed by large language model providers (such as OpenAI, Anthropic, or other providers configured for your plan) to generate automated responses or suggestions.', 'We use provider APIs for inference. We do not use your conversation content to train our own global foundation models, and we instruct customers’ production traffic to use provider API modes that do not opt customer content into the provider’s model-training programs where such controls exist.', 'You may disable AI bots or disconnect AI features at any time from Panel AI / InboxHub settings. Human agents remain responsible for supervising automation.'] },
            { heading: '5. Data transfers between systems', paragraphs: ['Message and profile data travel between official platform APIs (for example TikTok API, WhatsApp Business / Meta APIs) and InboxHub. When AI is enabled, relevant content may also be sent to Panel AI and the configured LLM provider to generate responses, then returned to InboxHub for delivery on the original channel.', 'Transfers occur over HTTPS and only for the purpose of operating the services you requested.'] },
            { heading: '6. Retention', paragraphs: ['We retain conversation and account data for as long as your InboxHub account remains active and as needed to provide the service, comply with legal obligations, resolve disputes, and enforce agreements.', 'After a verified deletion request (see our Data Deletion Instructions), we delete or anonymize applicable personal data from our systems within thirty (30) days, except where we must retain limited records for legitimate legal, security, or accounting reasons.'] },
            { heading: '7. Sharing and sale of data', paragraphs: ['We do not sell personal data to third parties. We share data only with: (a) subprocessors needed to run InboxHub (hosting, email, LLM APIs) under contractual controls; (b) the channel platforms you connect, as required to send/receive messages; and (c) authorities when legally required.'] },
            { heading: '8. Your choices and rights', paragraphs: ['Workspace admins can disconnect channels, manage agent access, and disable AI features. End users of TikTok or Meta may also use those platforms’ privacy tools. To request deletion of data stored in InboxHub, email us as described in the Data Deletion Instructions.'] },
            { heading: '9. Contact', paragraphs: ["Privacy and deletion requests: #{SUPPORT_EMAIL}. Commercial inquiries: ventas@paluhub.com."] }
          ]
        },
        'terms' => {
          title: 'Terms of Service for InboxHub',
          last_updated: LAST_UPDATED,
          intro: 'These Terms of Service (“Terms”) govern access to and use of InboxHub and related PaluHub services (including Panel AI). By creating an account or using the product, you agree to these Terms on behalf of yourself or the organization you represent.',
          sections: [
            { heading: '1. The service', paragraphs: ['InboxHub is a multi-channel inbox and customer communication tool. Optional AI features help draft or send replies. PaluHub provides software and hosting; you remain responsible for your business communications, content, and compliance with platform rules (TikTok, Meta, etc.).'] },
            { heading: '2. Permitted use', paragraphs: ['You may use InboxHub only for lawful customer service and business messaging. You must not use the service to:'], bullets: ['Send spam, unsolicited bulk messages, or deceptive content on TikTok, WhatsApp, Instagram, Facebook, email, or any connected channel.', 'Harass, threaten, or exploit individuals, or distribute illegal content.', 'Violate TikTok, Meta, or other platform policies, or attempt to bypass API rate limits or security controls.', 'Probe, scrape, or attack the service infrastructure.'] },
            { heading: '3. AI disclaimer (important)', paragraphs: ['InboxHub is not responsible for responses generated by artificial intelligence. AI outputs may be inaccurate, incomplete, or inappropriate. You are solely responsible for supervising, reviewing, correcting, approving, or disabling automations before and after they reach customers.', 'You should maintain human oversight for sensitive topics (legal, medical, financial, or safety-critical matters).'] },
            { heading: '4. Intellectual property and non-affiliation', paragraphs: ['InboxHub, PaluHub branding, and our software are owned by PaluHub or its licensors. TikTok, Meta, WhatsApp, Instagram, OpenAI, Anthropic, and other marks belong to their respective owners.', 'InboxHub is an independent tool. It is not an official TikTok or Meta product. We integrate using official APIs under your authorized credentials and permissions.'] },
            { heading: '5. Your content and channels', paragraphs: ['You retain rights to your business content. You grant us a limited license to host, process, and transmit that content solely to operate InboxHub and optional AI features. You represent that you have the rights and consents needed to connect each channel and process end-user messages.'] },
            { heading: '6. Service limits and availability', paragraphs: ['We strive for reliable uptime but do not guarantee uninterrupted service. Third-party APIs (for example TikTok or WhatsApp) may degrade, change, or become unavailable. Scheduled maintenance of InboxHub or Panel AI may temporarily interrupt features.', 'We are not liable for outages, policy changes, or rate limits imposed by third-party platforms outside our reasonable control.'] },
            { heading: '7. Billing', paragraphs: ['Paid plans and AI message packs are billed according to your order and the pricing shown in Panel AI / sales communications. Bank-transfer plans activate after confirmation by PaluHub. Unused prepaid message packs remain available as described in product documentation until consumed.'] },
            { heading: '8. Suspension and termination', paragraphs: ['We may suspend or terminate access for policy violations, non-payment, or security risk. You may stop using the service and request account closure. Data deletion requests are handled as described in our Data Deletion Instructions and Privacy Policy.'] },
            { heading: '9. Limitation of liability', paragraphs: ['To the maximum extent permitted by law, PaluHub is not liable for indirect, incidental, special, consequential, or punitive damages, or for lost profits, revenue, or data, arising from use of InboxHub or AI outputs. Our aggregate liability for claims relating to the service is limited to the fees you paid to PaluHub for the service in the three (3) months before the claim.'] },
            { heading: '10. Contact', paragraphs: ["Questions about these Terms: #{SUPPORT_EMAIL}. Sales: ventas@paluhub.com."] }
          ]
        },
        'data-deletion' => {
          title: 'Data Deletion Instructions for InboxHub',
          last_updated: LAST_UPDATED,
          intro: 'TikTok, Meta, and other platforms require a clear way for users and businesses to disconnect apps and request deletion of stored data. This page explains how to disconnect channels from InboxHub and how to ask PaluHub to delete conversation history from our systems.',
          sections: [
            { heading: '1. Disconnect TikTok (or another channel) from InboxHub', paragraphs: ['Workspace admins can remove channel access so InboxHub no longer receives new messages from that channel:'], bullets: ['Sign in to InboxHub (https://inbox.paluhub.com).', 'Open Settings → Inboxes (or the equivalent Channels / Inboxes section).', 'Select the TikTok (or WhatsApp / Instagram / Facebook) inbox connected to your account.', 'Disconnect, revoke, or delete the inbox / channel connection as shown in the UI.', 'Optionally, also revoke InboxHub access from the TikTok or Meta developer / business settings for your account or Page.'] },
            { heading: '2. Request deletion of stored conversation data', paragraphs: ["Disconnecting a channel stops new sync but may leave historical conversations in InboxHub. To request deletion of your data from PaluHub databases, email #{SUPPORT_EMAIL} with:"], bullets: ['Subject line: Data deletion request', 'The email associated with your InboxHub account', 'Organization / workspace name', 'Channel(s) involved (e.g. TikTok, WhatsApp) and any inbox identifiers you have', 'Whether you want full account deletion or only a specific channel’s history'] },
            { heading: '3. What we delete', paragraphs: ['After we verify your request, we delete or anonymize applicable data within thirty (30) days, including where feasible:'], bullets: ['Conversation messages and attachments stored for the requested scope', 'Contact records primarily associated with the disconnected channel (when not shared with other active channels)', 'OAuth tokens and channel credentials for the disconnected integration', 'AI-related logs tied to those conversations, subject to short-lived operational backups'] },
            { heading: '4. Timing', paragraphs: ['We aim to confirm receipt within a few business days and complete deletion within thirty (30) days of a verified request, unless a longer period is required by law or ongoing dispute resolution.'] },
            { heading: '5. Automated platform callbacks', paragraphs: ['Some platforms offer an automated data-deletion callback when a user removes an app. InboxHub may add automated callback endpoints in the future. Until then, use the disconnect steps and email process above.'] },
            { heading: '6. Contact', paragraphs: ["Data deletion and privacy: #{SUPPORT_EMAIL}."] }
          ]
        }
      },
      'es' => {
        'privacy' => {
          title: 'Política de Privacidad de InboxHub',
          last_updated: LAST_UPDATED,
          intro: 'PaluHub (“nosotros”) opera InboxHub, una plataforma de comunicación multicanal basada en un framework tipo Chatwoot y asistentes de IA opcionales (Panel AI). Esta Política explica qué datos recolectamos al conectar canales como TikTok, WhatsApp, Instagram, Facebook Messenger y Email, y cómo se usan—especialmente cuando hay funciones de IA activas.',
          sections: [
            { heading: '1. Quiénes somos', paragraphs: ['InboxHub es un producto operado por PaluHub. Es una plataforma de software independiente que integra APIs oficiales de terceros (incluidas TikTok y Meta). No estamos afiliados, respaldados ni patrocinados por TikTok, Meta, OpenAI, Anthropic u otros proveedores.'] },
            { heading: '2. Datos que recolectamos', paragraphs: ['Según los canales que conectes y los permisos que otorgues, podemos recolectar y tratar:'], bullets: ['Información de perfil público de TikTok y otras plataformas conectadas (nombre, avatar e identificadores públicos).', 'Mensajes directos y contenido de conversaciones con tu negocio a través de las bandejas conectadas.', 'Comentarios y datos de interacción pública cuando la API los exponga para soporte.', 'Metadatos de medios (imágenes, audio, video) y, cuando corresponda, el contenido necesario para mostrar o procesar el mensaje.', 'Datos de cuenta y workspace de usuarios de InboxHub (nombre, email, organización, roles, facturación).', 'Registros técnicos de operación (marcas de tiempo, estado de entrega, webhooks, diagnósticos de error).'] },
            { heading: '3. Uso de la información', paragraphs: ['Los datos se procesan para centralizar la comunicación y mejorar la respuesta al cliente mediante modelos de Inteligencia Artificial opcionales. En concreto, usamos la información para:'], bullets: ['Mostrar conversaciones en un dashboard unificado de InboxHub.', 'Enrutar, asignar, etiquetar y escalar conversaciones según tu configuración.', 'Impulsar asistentes de IA que redactan o envían respuestas automáticas cuando los activás.', 'Ofrecer conocimiento (por ejemplo RAG / documentos) que configures.', 'Operar facturación, seguridad, prevención de abuso y soporte.'] },
            { heading: '4. Procesamiento de IA', paragraphs: ['Cuando las funciones de IA están activas, los mensajes y su contexto pueden ser procesados por proveedores de modelos de lenguaje (como OpenAI, Anthropic u otros según el plan) para generar respuestas o sugerencias automáticas.', 'Usamos las APIs de esos proveedores para inferencia. No usamos el contenido de tus conversaciones para entrenar modelos globales propios, y configuramos el tráfico de producción para que no se opte al entrenamiento de modelos del proveedor cuando existan esos controles.', 'Podés desactivar bots de IA o desconectar funciones de IA en cualquier momento desde Panel AI / InboxHub. Los agentes humanos son responsables de supervisar la automatización.'] },
            { heading: '5. Transferencia de datos', paragraphs: ['Los datos viajan entre las APIs oficiales (por ejemplo TikTok API, WhatsApp Business / APIs de Meta) y tu plataforma InboxHub. Si la IA está activa, el contenido relevante también puede enviarse a Panel AI y al proveedor LLM configurado, y luego volver a InboxHub para entregarse en el canal original.', 'Las transferencias se realizan por HTTPS y solo para operar los servicios que solicitaste.'] },
            { heading: '6. Retención de datos', paragraphs: ['Conservamos conversaciones y datos de cuenta mientras tu cuenta de InboxHub esté activa y sea necesario para prestar el servicio, cumplir obligaciones legales, resolver disputas y hacer cumplir acuerdos.', 'Tras una solicitud de eliminación verificada (ver Instrucciones de Eliminación de Datos), eliminamos o anonimizamos los datos personales aplicables en un plazo de treinta (30) días, salvo registros limitados que debamos conservar por motivos legales, de seguridad o contables.'] },
            { heading: '7. Compartición y venta de datos', paragraphs: ['No vendemos datos personales a terceros. Solo compartimos datos con: (a) subprocesadores necesarios para operar InboxHub (hosting, email, APIs LLM) bajo controles contractuales; (b) las plataformas de canal que conectás, para enviar/recibir mensajes; y (c) autoridades cuando la ley lo exija.'] },
            { heading: '8. Tus opciones y derechos', paragraphs: ['Los administradores pueden desconectar canales, gestionar agentes y desactivar IA. Los usuarios finales de TikTok o Meta también pueden usar las herramientas de privacidad de esas plataformas. Para pedir borrado de datos en InboxHub, escribinos según las Instrucciones de Eliminación de Datos.'] },
            { heading: '9. Contacto', paragraphs: ["Privacidad y borrado: #{SUPPORT_EMAIL}. Comercial: ventas@paluhub.com."] }
          ]
        },
        'terms' => {
          title: 'Términos y Condiciones de Servicio de InboxHub',
          last_updated: LAST_UPDATED,
          intro: 'Estos Términos y Condiciones (“Términos”) regulan el acceso y uso de InboxHub y servicios relacionados de PaluHub (incluido Panel AI). Al crear una cuenta o usar el producto, aceptás estos Términos en tu nombre o en el de la organización que representás.',
          sections: [
            { heading: '1. El servicio', paragraphs: ['InboxHub es una bandeja multicanal para comunicación con clientes. Las funciones de IA opcionales ayudan a redactar o enviar respuestas. PaluHub provee software y hosting; vos sos responsable de tus comunicaciones, contenido y del cumplimiento de las reglas de cada plataforma (TikTok, Meta, etc.).'] },
            { heading: '2. Uso permitido', paragraphs: ['Solo podés usar InboxHub para mensajería comercial y atención al cliente lícitas. Queda prohibido usar el servicio para:'], bullets: ['Enviar spam, mensajes masivos no solicitados o contenido engañoso en TikTok, WhatsApp, Instagram, Facebook, email u otros canales conectados.', 'Acosar, amenazar o explotar personas, o distribuir contenido ilegal.', 'Violar políticas de TikTok, Meta u otras plataformas, o eludir límites de API o controles de seguridad.', 'Sondear, scrapear o atacar la infraestructura del servicio.'] },
            { heading: '3. Responsabilidad de la IA (importante)', paragraphs: ['InboxHub no se hace responsable de las respuestas generadas por la IA. Los resultados pueden ser inexactos, incompletos o inadecuados. El usuario final es responsable de supervisar, revisar, corregir, aprobar o desactivar las automatizaciones antes y después de que lleguen a los clientes.', 'Debés mantener supervisión humana en temas sensibles (legales, médicos, financieros o de seguridad).'] },
            { heading: '4. Propiedad intelectual y no afiliación', paragraphs: ['InboxHub, la marca PaluHub y nuestro software pertenecen a PaluHub o a sus licenciantes. TikTok, Meta, WhatsApp, Instagram, OpenAI, Anthropic y otras marcas pertenecen a sus respectivos dueños.', 'InboxHub es una herramienta independiente y no está afiliada oficialmente a TikTok ni a Meta; usa sus APIs oficiales bajo tus credenciales y permisos autorizados.'] },
            { heading: '5. Tu contenido y canales', paragraphs: ['Conservás los derechos sobre el contenido de tu negocio. Nos otorgás una licencia limitada para alojar, procesar y transmitir ese contenido solo para operar InboxHub y las funciones de IA opcionales. Declarás que tenés los derechos y consentimientos necesarios para conectar cada canal y tratar mensajes de usuarios finales.'] },
            { heading: '6. Límites del servicio y disponibilidad', paragraphs: ['Buscamos alta disponibilidad, pero no garantizamos un servicio ininterrumpido. Las APIs de terceros (por ejemplo TikTok o WhatsApp) pueden degradarse, cambiar o no estar disponibles. El mantenimiento de InboxHub o Panel AI puede interrumpir funciones temporalmente.', 'No somos responsables de caídas, cambios de política o límites de tasa impuestos por plataformas de terceros fuera de nuestro control razonable.'] },
            { heading: '7. Facturación', paragraphs: ['Los planes pagos y packs de mensajes IA se cobran según tu pedido y los precios mostrados en Panel AI / comunicaciones de ventas. Los planes por transferencia se activan tras la confirmación de PaluHub. Los packs prepago no usados permanecen disponibles según la documentación del producto hasta consumirse.'] },
            { heading: '8. Suspensión y terminación', paragraphs: ['Podemos suspender o terminar el acceso por violación de políticas, falta de pago o riesgo de seguridad. Podés dejar de usar el servicio y solicitar el cierre de la cuenta. Las solicitudes de borrado se tratan según las Instrucciones de Eliminación de Datos y la Política de Privacidad.'] },
            { heading: '9. Limitación de responsabilidad', paragraphs: ['En la máxima medida permitida por la ley, PaluHub no responde por daños indirectos, incidentales, especiales, consecuentes o punitivos, ni por pérdida de beneficios, ingresos o datos, derivados del uso de InboxHub o de salidas de IA. Nuestra responsabilidad agregada se limita a las tarifas que nos hayas pagado por el servicio en los tres (3) meses anteriores al reclamo.'] },
            { heading: '10. Contacto', paragraphs: ["Consultas sobre estos Términos: #{SUPPORT_EMAIL}. Ventas: ventas@paluhub.com."] }
          ]
        },
        'data-deletion' => {
          title: 'Instrucciones de Eliminación de Datos de InboxHub',
          last_updated: LAST_UPDATED,
          intro: 'TikTok, Meta y otras plataformas exigen una vía clara para desconectar apps y solicitar el borrado de datos almacenados. Esta página explica cómo desconectar canales de InboxHub y cómo pedir a PaluHub que elimine el historial de conversaciones de nuestros sistemas.',
          sections: [
            { heading: '1. Desconectar TikTok (u otro canal) de InboxHub', paragraphs: ['Los administradores del workspace pueden quitar el acceso del canal para que InboxHub deje de recibir mensajes nuevos:'], bullets: ['Iniciá sesión en InboxHub (https://inbox.paluhub.com).', 'Abrí Configuración → Bandejas (Inboxes) o la sección equivalente de Canales.', 'Seleccioná la bandeja de TikTok (o WhatsApp / Instagram / Facebook) conectada.', 'Desconectá, revocá o eliminá la conexión del inbox / canal según la interfaz.', 'Opcionalmente, revocá también el acceso de InboxHub desde la configuración de desarrollador / negocio de TikTok o Meta.'] },
            { heading: '2. Solicitud manual de borrado', paragraphs: ["Desconectar un canal detiene la sincronización nueva, pero puede quedar historial en InboxHub. Para pedir el borrado de tus datos en las bases de PaluHub, escribí a #{SUPPORT_EMAIL} con:"], bullets: ['Asunto: Solicitud de eliminación de datos / Data deletion request', 'El email de tu cuenta InboxHub', 'Nombre de la organización / workspace', 'Canal(es) involucrados (p. ej. TikTok, WhatsApp) e identificadores de bandeja si los tenés', 'Si querés borrado total de la cuenta o solo el historial de un canal'] },
            { heading: '3. Qué borramos', paragraphs: ['Tras verificar la solicitud, eliminamos o anonimizamos los datos aplicables en un plazo de treinta (30) días, incluyendo cuando sea posible:'], bullets: ['Mensajes y adjuntos del alcance solicitado', 'Contactos asociados principalmente al canal desconectado (si no se comparten con otros canales activos)', 'Tokens OAuth y credenciales del canal desconectado', 'Logs de IA vinculados a esas conversaciones, sujetos a respaldos operativos de corta duración'] },
            { heading: '4. Plazos', paragraphs: ['Confirmamos la recepción en pocos días hábiles y completamos el borrado dentro de treinta (30) días desde una solicitud verificada, salvo que la ley o una disputa en curso exijan un plazo mayor.'] },
            { heading: '5. Callback automático de plataformas', paragraphs: ['Algunas plataformas ofrecen un callback automático de borrado cuando alguien desinstala la app. InboxHub podrá añadir endpoints automáticos en el futuro. Mientras tanto, usá los pasos de desconexión y el correo anteriores.'] },
            { heading: '6. Contacto', paragraphs: ["Eliminación de datos y privacidad: #{SUPPORT_EMAIL}."] }
          ]
        }
      }
    }.freeze
    # rubocop:enable Metrics/CollectionLiteralLength
  end
end
