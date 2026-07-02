# Mejoras futuras del módulo Contactos (Chatwoot fork)

> Este archivo guarda ideas descartadas o pospuestas para no perderlas.
> No representan tareas activas; se implementarán solo si surge una necesidad concreta.

---

## 1. Propietario / agente asignado al contacto (`owner_id`)

### Campo propuesto
- `contacts.owner_id` → referencia opcional a `users`.
- Relación: `belongs_to :owner, class_name: 'User', optional: true`.

### Usos posibles
1. **Auto-asignación de conversaciones**: cuando un contacto con `owner_id` inicie una conversación y el bot la escale (o no haya bot), asignar la conversación automáticamente a ese agente.
2. **Notificación al owner**: avisar al agente cuando un contacto inactivo vuelve a escribir.
3. **Filtrado rápido en CRM**: vista "Mis contactos" por owner.
4. **Reportes de ventas**: atribuir conversaciones/conversiones al responsable del contacto.

### Por qué no se implementa ahora
No hay un flujo definido que lo requiera. Agregarlo sin un uso concreto sería deuda técnica. Se retoma cuando se necesite auto-asignación o reporting por agente comercial.

### Archivos que tocaría
- Migración: `add_owner_id_to_contacts`.
- Modelo: `app/models/contact.rb`.
- Controller: `app/controllers/api/v1/accounts/contacts_controller.rb`.
- Serializer/partial: `app/views/api/v1/models/_contact.json.jbuilder`.
- Frontend: `ContactsForm.vue`, `ContactsCard.vue`, `ContactsTable.vue`.
- Hook de asignación: `app/builders/conversation_builder.rb` o un callback en `Conversation`.

---

## 2. Estado de ciclo de vida del contacto

Actualmente Chatwoot tiene `contact_type`: `visitor`, `lead`, `customer`.
Se podría extender con un lifecycle más rico: `prospect`, `qualified`, `opportunity`, `churned`.

---

## 3. Fuente / atribución de primer contacto

Guardar el canal de origen del contacto: WhatsApp, webchat, email, Instagram, importación, etc.
Útil para métricas de conversión.

---

## 4. Fecha de próximo seguimiento

Campo `contacts.next_follow_up_at` para crear vistas de "contactos pendientes de seguimiento".

---

## 5. Detección y fusión de duplicados automática

Pantalla de "posibles duplicados" basada en email, teléfono o `document_number`.

---

## 6. Acciones masivas mejoradas

- Asignar etiqueta a seleccionados.
- Asignar propietario a seleccionados.
- Exportar solo seleccionados.
- Eliminar seleccionados en batch.
