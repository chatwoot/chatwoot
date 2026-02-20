# frozen_string_literal: true

module Crm
  module Zoho
    # Zoho CRM Processor Service
    #
    # Implements CRM actions for Zoho CRM API
    class ProcessorService < Crm::BaseProcessorService
      include Crm::Concerns::OwnerAssignable

      def initialize(hook)
        super(hook)
        @lead_client = Crm::Zoho::Api::LeadClient.new(hook)
        @activity_client = Crm::Zoho::Api::ActivityClient.new(hook)
        @ticket_client = Crm::Zoho::Api::TicketClient.new(hook) if hook.settings&.dig('desk_soid').present?
      end

      def self.crm_name
        'zoho'
      end

      # ============================================================================
      # ACTION DISPATCHER
      # ============================================================================

      # Execute a CRM action based on action_type
      #
      # @param action_type [String] Type of action (create_lead, update_lead, etc.)
      # @param params [Hash] Action parameters
      # @return [Hash] Result with success status
      def execute_action(action_type, params = {})
        case action_type.to_s
        when 'create_lead'
          create_lead(params)
        when 'create_contact'
          create_contact(params)
        when 'update_lead'
          update_lead(params)
        when 'update_contact'
          update_contact(params)
        when 'create_task'
          create_task(params)
        when 'create_call'
          create_call(params)
        when 'create_event'
          create_event(params)
        when 'add_tag'
          add_tag(params)
        when 'remove_tag'
          remove_tag(params)
        when 'add_note'
          add_note(params)
        when 'update_appointment_status'
          update_appointment_status(params)
        when 'create_ticket'
          create_ticket(params)
        else
          { success: false, error: "Unknown action type: #{action_type}" }
        end
      end

      # ============================================================================
      # AUTHENTICATION
      # ============================================================================

      def authenticated?
        # Si no hay token, intentar setup inicial (el job pudo no haberse ejecutado aún)
        if @hook.credentials['access_token'].blank?
          Rails.logger.info "Zoho hook ##{@hook.id}: no access_token found, attempting initial setup..."
          Crm::Zoho::SetupService.new(@hook).setup
          @hook.reload
        end

        return false unless @hook.credentials['access_token'].present?

        # Si el token está expirado, intentar refrescarlo
        if @hook.token_expired?
          Rails.logger.info 'Zoho token expired, attempting refresh...'
          @hook.refresh_token_if_needed
          @hook.reload
        end

        # Verificar de nuevo después del posible refresh
        @hook.credentials['access_token'].present? && !@hook.token_expired?
      rescue StandardError => e
        Rails.logger.error "Zoho authentication check failed: #{e.message}"
        false
      end

      # ============================================================================
      # PROFILE SYNC
      # ============================================================================

      # Sync profile from Zoho to Nauto Console Contact
      #
      # Syncs from Lead or Contact object based on contact_type:
      # - lead: syncs from Zoho Lead object
      # - customer: syncs from Zoho Contact object
      #
      # @param contact [Contact] The contact to sync
      # @return [Hash] Result with success status and synced fields
      def sync_profile(contact)
        # Determine which Zoho object to sync from based on contact_type
        if contact.contact_type == 'customer'
          external_id = get_external_id(contact, 'zoho_contact_id')
          return { success: false, error: 'No external_id found for customer contact' } unless external_id

          # Fetch contact profile from Zoho
          response = @lead_client.get_contact(external_id)
          profile = response.dig('data', 0) if response && response['data'].is_a?(Array)
          return { success: false, error: 'Contact not found in Zoho' } unless profile && profile['id'].present?

          object_type = 'Contact'
        else
          # Default to Lead for 'lead' and 'visitor' types
          external_id = get_external_id(contact)
          return { success: false, error: 'No external_id found for lead' } unless external_id

          # Fetch lead profile from Zoho
          response = @lead_client.get_lead(external_id)
          profile = response.dig('data', 0) if response && response['data'].is_a?(Array)
          return { success: false, error: 'Lead not found in Zoho' } unless profile && profile['id'].present?

          object_type = 'Lead'
        end

        # Get org_id from credentials for URL construction
        org_id = @hook.credentials['soid'] || @hook.credentials.dig('credentials', 'soid')

        # Map CRM profile to Contact attributes
        mapped_attrs = Crm::Zoho::Mappers::ProfileMapper.map_to_contact_attributes(profile, org_id: org_id)

        # Merge additional_attributes instead of replacing
        if mapped_attrs[:additional_attributes].present?
          contact.additional_attributes ||= {}
          contact.additional_attributes.deep_merge!(mapped_attrs[:additional_attributes])
          mapped_attrs.delete(:additional_attributes)
        end

        # Update contact with mapped attributes
        contact.update!(mapped_attrs.merge(additional_attributes: contact.additional_attributes))

        Rails.logger.info "Profile synced from Zoho #{object_type} for contact #{contact.id}"
        { success: true, synced_fields: mapped_attrs.keys }
      rescue StandardError => e
        Rails.logger.error "Error syncing profile from Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # LEAD OPERATIONS
      # ============================================================================

      # Create lead in Zoho CRM
      #
      # @param params [Hash] Lead parameters
      # @option params [String] :contact_first_name
      # @option params [String] :contact_last_name
      # @option params [String] :email
      # @option params [String] :phone
      # @option params [Hash] :lead_custom_fields Custom fields for lead
      # @option params [Hash] :contact_custom_fields Custom fields for contact
      # @return [Hash] Result with success status and lead_id
      def create_lead(params)
        contact = find_contact_from_params(params)
        return { success: false, error: 'Contact not found' } unless contact

        # Check if lead already exists
        external_id = contact.additional_attributes&.dig('external', 'zoho_lead_id')
        if external_id.present?
          Rails.logger.info "Lead already exists in Zoho: #{external_id}"
          return { success: true, lead_id: external_id, action: 'existing' }
        end

        # Map contact to Zoho lead format
        # Merge lead_custom_fields from both metadata and promoted params (params takes priority)
        metadata = params[:metadata] || {}
        meta_custom = metadata.with_indifferent_access[:lead_custom_fields] || {}
        custom_fields = meta_custom.merge(params[:lead_custom_fields] || {})

        mapper = Crm::Zoho::Mappers::ContactMapper.new(contact)
        lead_data = mapper.map_to_lead(custom_fields: custom_fields)

        # Create lead in Zoho
        response = @lead_client.create_lead(lead_data)

        if response && response['data']&.any?
          lead_record = response['data'].first
          lead_id = lead_record['details']['id']

          # Store external ID
          store_external_id(contact, lead_id)

          Rails.logger.info "Lead created successfully in Zoho: #{lead_id}"
          { success: true, lead_id: lead_id, action: 'created', response: lead_record }
        else
          { success: false, error: 'Failed to create lead', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error creating lead in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # Update lead in Zoho CRM
      #
      # @param params [Hash] Lead parameters with lead_id
      # @return [Hash] Result with success status
      def update_lead(params)
        lead_id = params[:lead_id] || get_external_id_from_params(params)
        return { success: false, error: 'Lead ID not provided' } unless lead_id

        contact = find_contact_from_params(params)
        return { success: false, error: 'Contact not found' } unless contact

        # Map contact to Zoho format
        mapper = Crm::Zoho::Mappers::ContactMapper.new(contact)
        lead_data = mapper.map_to_lead(custom_fields: params[:lead_custom_fields] || {})

        # Add owner if specified (for advisor transfer)
        add_owner_to_data(lead_data, params, action: 'update_lead')

        # Update lead
        response = @lead_client.update_lead(lead_id, lead_data)

        if response && response['data']&.any?
          Rails.logger.info "Lead updated successfully in Zoho: #{lead_id}"
          { success: true, lead_id: lead_id, action: 'updated' }
        else
          { success: false, error: 'Failed to update lead', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error updating lead in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # CONTACT OPERATIONS
      # ============================================================================

      # Create contact in Zoho CRM (for customers, not leads)
      #
      # @param params [Hash] Contact parameters
      # @return [Hash] Result with success status and contact_id
      def create_contact(params)
        contact = find_contact_from_params(params)
        return { success: false, error: 'Contact not found' } unless contact

        # Check if contact already exists in Zoho
        external_id = contact.additional_attributes&.dig('external', 'zoho_contact_id')
        if external_id.present?
          Rails.logger.info "Contact already exists in Zoho: #{external_id}"
          return { success: true, contact_id: external_id, action: 'existing' }
        end

        # Map contact to Zoho contact format
        mapper = Crm::Zoho::Mappers::ContactMapper.new(contact)
        contact_data = mapper.map_to_contact(custom_fields: params[:contact_custom_fields] || {})

        # Create contact in Zoho
        response = @lead_client.create_contact(contact_data)

        if response && response['data']&.any?
          contact_record = response['data'].first
          contact_id = contact_record['details']['id']

          # Store external ID with different key for contacts
          store_external_id(contact, contact_id, 'zoho_contact_id')

          Rails.logger.info "Contact created successfully in Zoho: #{contact_id}"
          { success: true, contact_id: contact_id, action: 'created', response: contact_record }
        else
          { success: false, error: 'Failed to create contact', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error creating contact in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # Update contact in Zoho CRM
      #
      # @param params [Hash] Contact parameters
      # @option params [String] :contact_id Zoho contact ID
      # @option params [String] :owner_id Zoho owner ID
      # @return [Hash] Result with success status
      def update_contact(params)
        contact_id = params[:contact_id]
        contact_id ||= find_contact_from_params(params)&.additional_attributes&.dig('external', 'zoho_contact_id')
        return { success: false, error: 'Contact ID not provided' } unless contact_id

        contact = find_contact_from_params(params)
        return { success: false, error: 'Contact not found' } unless contact

        # Map contact to Zoho format
        mapper = Crm::Zoho::Mappers::ContactMapper.new(contact)
        contact_data = mapper.map_to_contact(custom_fields: params[:contact_custom_fields] || {})

        # Add owner if specified (for advisor transfer)
        add_owner_to_data(contact_data, params, action: 'update_contact')

        # Update contact
        response = @lead_client.update_contact(contact_id, contact_data)

        if response && response['data']&.any?
          Rails.logger.info "Contact updated successfully in Zoho: #{contact_id}"
          { success: true, contact_id: contact_id, action: 'updated' }
        else
          { success: false, error: 'Failed to update contact', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error updating contact in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # TASK OPERATIONS
      # ============================================================================

      # Create task in Zoho CRM
      #
      # @param params [Hash] Task parameters
      # @option params [String] :subject Task subject
      # @option params [String] :description Task description
      # @option params [String] :due_date Due date
      # @option params [String] :priority Priority (High, Normal, Low)
      # @option params [String] :status Status
      # @option params [String] :owner_id Zoho owner ID
      # @option params [Boolean] :send_notification Send notification
      # @return [Hash] Result with success status and task_id
      def create_task(params)
        contact = find_contact_from_params(params)
        lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')

        # Map to Zoho task format
        task_data = Crm::Zoho::Mappers::ActivityMapper.map_task(
          subject: params[:subject],
          description: params[:description],
          due_date: params[:due_date],
          priority: params[:priority],
          status: params[:status],
          owner_id: params[:owner_id],
          contact_id: nil, # Zoho tasks use What_Id for leads
          lead_id: lead_id,
          se_module: 'Leads',
          send_notification: params[:send_notification]
        )

        response = @activity_client.create_task(task_data)

        if response && response['data']&.any?
          task_record = response['data'].first
          task_id = task_record['details']['id']

          Rails.logger.info "Task created successfully in Zoho: #{task_id}"
          { success: true, task_id: task_id, response: task_record }
        else
          { success: false, error: 'Failed to create task', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error creating task in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # CALL OPERATIONS
      # ============================================================================

      # Create call log in Zoho CRM
      #
      # @param params [Hash] Call parameters
      # @option params [Integer] :appointment_id Nauto Console appointment ID (optional)
      # @option params [String] :subject Call subject
      # @option params [String] :description Call description
      # @option params [String] :call_type Call type (Inbound/Outbound)
      # @option params [String] :start_time Start time (ISO 8601)
      # @option params [Integer] :duration Duration in seconds
      # @return [Hash] Result with success status and call_id
      def create_call(params)
        appointment_id = params[:appointment_id]
        appointment = appointment_id.present? ? Appointment.find_by(id: appointment_id) : nil

        if appointment
          # Usar datos del appointment para crear la llamada
          contact = appointment.contact
          contact&.additional_attributes&.dig('external', 'zoho_lead_id')

          # Get CRM owner ID from appointment owner if available
          crm_owner_id = nil
          if appointment.owner
            account_user = appointment.owner.account_users.find_by(account_id: appointment.account_id)
            crm_owner_id = account_user&.crm_external_id
            Rails.logger.info "🔍 [ZOHO CALL] Appointment owner: #{appointment.owner.email}, CRM ID: #{crm_owner_id}"
          end

          # Usar el mapper específico para appointments, pasando owner_id
          mapper_params = params.dup
          mapper_params[:owner_id] = crm_owner_id if crm_owner_id.present?
          call_data = Crm::Zoho::Mappers::ActivityMapper.map_call_from_appointment(appointment, mapper_params)

          response = @activity_client.create_call(call_data)

          if response && response['data']&.any?
            call_record = response['data'].first
            call_id = call_record['details']['id']

            # Guardar el external_id en el appointment
            appointment.store_external_id('zoho', call_id)

            Rails.logger.info "Call created successfully in Zoho from appointment #{appointment.id}: #{call_id}"
            { success: true, call_id: call_id, response: call_record }
          else
            { success: false, error: 'Failed to create call', response: response }
          end
        else
          # Código existente para crear call sin appointment
          contact = find_contact_from_params(params)
          lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')
          metadata = params[:metadata] || {}

          # Priorizamos metadata (AI) sobre params (configuración fija del flow)
          subject     = metadata['call_subject'].presence || metadata['subject'].presence || params[:subject]
          description = metadata['call_description'].presence || metadata['description'].presence || params[:description]
          start_time  = metadata['scheduled_at'].presence || metadata['start_time'].presence || params[:start_time]

          # Map to Zoho call format
          call_data = Crm::Zoho::Mappers::ActivityMapper.map_call(
            subject: subject,
            description: description,
            call_type: params[:call_type],
            start_time: start_time,
            duration: params[:duration],
            contact_id: nil, # Zoho calls use What_Id for leads
            lead_id: lead_id,
            se_module: 'Leads',
            status: 'Scheduled'
          )

          response = @activity_client.create_call(call_data)

          if response && response['data']&.any?
            call_record = response['data'].first
            call_id = call_record['details']['id']

            Rails.logger.info "Call created successfully in Zoho: #{call_id}"
            { success: true, call_id: call_id, response: call_record }
          else
            { success: false, error: 'Failed to create call', response: response }
          end
        end
      rescue StandardError => e
        Rails.logger.error "Error creating call in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # EVENT OPERATIONS
      # ============================================================================

      # Create event in Zoho CRM from Nauto Console appointment
      #
      # @param params [Hash] Event parameters
      # @option params [Integer] :appointment_id Nauto Console appointment ID
      # @option params [String] :owner_id Zoho owner ID
      # @option params [Boolean] :send_notification Send notification
      # @return [Hash] Result with success status and event_id
      def create_event(params)
        appointment_id = params[:appointment_id]
        metadata = params[:metadata] || {}
        appointment = appointment_id.present? ? Appointment.find_by(id: appointment_id) : nil

        # Identificar el contacto y lead_id de Zoho
        contact = appointment&.contact || find_contact_from_params(params)
        lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')

        # Get CRM owner ID from appointment owner if available
        crm_owner_id = nil
        if appointment&.owner
          account_user = appointment.owner.account_users.find_by(account_id: appointment.account_id)
          crm_owner_id = account_user&.crm_external_id
          Rails.logger.info "🔍 [ZOHO EVENT] Appointment owner: #{appointment.owner.email}, CRM ID: #{crm_owner_id}"
        end

        Rails.logger.info "🔍 [ZOHO EVENT] params: #{params.inspect}"
        Rails.logger.info "🔍 [ZOHO EVENT] contact_id: #{contact&.id}, lead_id: #{lead_id}"

        # Si no hay cita ni metadata suficiente, fallamos (mantenemos compatibilidad)
        if !appointment && metadata.blank? && params[:subject].blank?
          return { success: false, error: 'Appointment or metadata required to create event' }
        end

        # Preparamos los parámetros base
        event_params = if appointment
                         # Cuando hay appointment, combinar params con lead_id, se_module y owner_id
                         # IMPORTANTE: Eliminar contact_id de Nauto Console para evitar conflicto con Who_Id
                         base_params = params.except(:contact_id).merge(
                           lead_id: lead_id,
                           se_module: 'Leads'
                         )
                         # Add CRM owner ID if available
                         base_params[:owner_id] = crm_owner_id if crm_owner_id.present?
                         base_params
                       else
                         {
                           event_title: metadata['event_title'] || metadata['subject'] || params[:subject],
                           description: metadata['event_description'] || metadata['description'] || params[:description],
                           start_time: metadata['start_time'] || metadata['scheduled_at'] || params[:start_time],
                           end_time: metadata['end_time'] || params[:end_time],
                           venue: metadata['venue'] || params[:venue],
                           lead_id: lead_id,
                           se_module: 'Leads',
                           owner_id: params[:owner_id],
                           send_notification: params[:send_notification] || false
                         }
                       end

        Rails.logger.info "🔍 [ZOHO EVENT] event_params: #{event_params.inspect}"

        # Map to Zoho event format
        event_data = Crm::Zoho::Mappers::ActivityMapper.map_event(
          appointment || event_params,
          appointment ? event_params : {}
        )

        Rails.logger.info "🔍 [ZOHO EVENT] event_data final: #{event_data.inspect}"

        response = @activity_client.create_event(event_data)

        if response && response['data']&.any?
          event_record = response['data'].first
          event_id = event_record['details']['id']

          # Si venía de una cita, guardamos el ID externo
          appointment.store_external_id('zoho', event_id) if appointment

          Rails.logger.info "Event created successfully in Zoho: #{event_id}"
          { success: true, event_id: event_id, response: event_record }
        else
          { success: false, error: 'Failed to create event', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error creating event in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # TAG OPERATIONS
      # ============================================================================

      # Add tag to lead in Zoho CRM
      #
      # @param params [Hash] Tag parameters
      # @option params [String] :tag_name Tag name
      # @return [Hash] Result with success status
      def add_tag(params)
        contact = find_contact_from_params(params)
        lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')

        return { success: false, error: 'Lead not found in Zoho' } unless lead_id

        tag_name = params[:tag_name]
        return { success: false, error: 'Tag name not provided' } unless tag_name

        response = @lead_client.add_tags(lead_id, [tag_name], module_name: 'Leads')

        if response && response['data']&.any?
          Rails.logger.info "Tag '#{tag_name}' added to lead #{lead_id}"
          { success: true, tag_name: tag_name }
        else
          { success: false, error: 'Failed to add tag', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error adding tag in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # Remove tag from lead in Zoho CRM
      #
      # @param params [Hash] Tag parameters
      # @option params [String] :tag_name Tag name
      # @return [Hash] Result with success status
      def remove_tag(params)
        contact = find_contact_from_params(params)
        lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')

        return { success: false, error: 'Lead not found in Zoho' } unless lead_id

        tag_name = params[:tag_name]
        return { success: false, error: 'Tag name not provided' } unless tag_name

        response = @lead_client.remove_tags([lead_id], [tag_name], module_name: 'Leads')

        if response && response['data']&.any?
          Rails.logger.info "Tag '#{tag_name}' removed from lead #{lead_id}"
          { success: true, tag_name: tag_name }
        else
          { success: false, error: 'Failed to remove tag', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error removing tag in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # NOTE OPERATIONS
      # ============================================================================

      # Add note to lead in Zoho CRM
      #
      # @param params [Hash] Note parameters
      # @option params [String] :note_text Note content
      # @option params [String] :note_title Note title (optional)
      # @return [Hash] Result with success status and note_id
      def add_note(params)
        contact = find_contact_from_params(params)
        lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')

        return { success: false, error: 'Lead not found in Zoho' } unless lead_id

        note_text = params[:note_text]
        return { success: false, error: 'Note text not provided' } unless note_text

        note_title = params[:note_title] || 'Note from Nauto Console'

        response = @lead_client.add_note(lead_id, note_title, note_text, se_module: 'Leads')

        if response && response['data']&.any?
          note_record = response['data'].first
          note_id = note_record['details']['id']

          Rails.logger.info "Note added to lead #{lead_id}"
          { success: true, note_id: note_id, response: note_record }
        else
          { success: false, error: 'Failed to add note', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error adding note in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # APPOINTMENT STATUS SYNC
      # ============================================================================

      # Update appointment status in Zoho CRM
      #
      # Syncs appointment status changes (started, completed, cancelled) to the corresponding
      # Zoho object (Call or Event) based on appointment type
      #
      # @param params [Hash] Update parameters
      # @option params [Integer] :appointment_id Nauto Console appointment ID
      # @return [Hash] Result with success status
      def update_appointment_status(params)
        appointment_id = params[:appointment_id]
        appointment = Appointment.find_by(id: appointment_id)

        return { success: false, error: 'Appointment not found' } unless appointment

        external_id = appointment.external_id_for('zoho')
        return { success: false, error: 'Appointment not synced to Zoho' } unless external_id

        # Mapear status de Nauto Console a Zoho
        zoho_status = Crm::AppointmentStatusConfig.resolve('zoho', appointment.status)
        return { success: false, error: 'Status mapping not found' } unless zoho_status

        # Determinar si es Call o Event según appointment_type
        object_type = appointment.appointment_type == 'phone_call' ? 'Calls' : 'Events'

        # Preparar datos de actualización
        update_data = if object_type == 'Calls'
                        { Call_Status: zoho_status, Outgoing_Call_Status: zoho_status }
                      else
                        { Event_Status: zoho_status }
                      end

        # Actualizar en Zoho
        response = if object_type == 'Calls'
                     @activity_client.update_record('Calls', external_id, update_data)
                   else
                     @activity_client.update_record('Events', external_id, update_data)
                   end

        if response && response['data']&.any?
          Rails.logger.info "Appointment status updated in Zoho: #{external_id} (#{object_type}) -> #{zoho_status}"
          { success: true, updated_id: external_id, object_type: object_type, status: zoho_status }
        else
          { success: false, error: 'Failed to update appointment status', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error updating appointment status in Zoho: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # TICKET OPERATIONS (Zoho Desk)
      # ============================================================================

      def create_ticket(params)
        return { success: false, error: 'Zoho Desk not configured' } unless @ticket_client

        department_id = resolve_desk_department_id
        return { success: false, error: 'No departments found in Zoho Desk' } if department_id.blank?

        contact = find_contact_from_params(params)
        ticket_data = Crm::Zoho::Mappers::TicketMapper.map_ticket(contact, params)
        ticket_data[:departmentId] = department_id

        return { success: false, error: 'Ticket subject is required' } if ticket_data[:subject].blank?

        response = @ticket_client.create_ticket(ticket_data)

        if response && response['id'].present?
          ticket_id = response['id']
          Rails.logger.info "Ticket created successfully in Zoho Desk: #{ticket_id}"
          { success: true, ticket_id: ticket_id, response: response }
        else
          { success: false, error: 'Failed to create ticket', response: response }
        end
      rescue StandardError => e
        Rails.logger.error "Error creating ticket in Zoho Desk: #{e.message}"
        { success: false, error: e.message }
      end

      # ============================================================================
      # HELPER METHODS
      # ============================================================================

      protected

      def build_client
        # Clients are initialized in constructor
        @lead_client
      end

      private

      def resolve_desk_department_id
        cached = @hook.settings&.dig('desk_department_id')
        return cached if cached.present?

        response = @ticket_client.get_departments
        Rails.logger.info "Zoho Desk departments response: #{response.inspect}"

        departments = response.is_a?(Array) ? response : (response&.dig('data') || [])
        department = departments.first
        return nil unless department

        department_id = department['id'].to_s
        @hook.update!(settings: @hook.settings.merge('desk_department_id' => department_id))
        department_id
      end

      def find_contact_from_params(params)
        contact_id = params[:contact_id]
        return Contact.find_by(id: contact_id) if contact_id

        # Try to find by email or phone if provided
        if params[:email].present?
          Contact.find_by(email: params[:email], account_id: hook.account_id)
        elsif params[:phone].present?
          Contact.find_by(phone_number: params[:phone], account_id: hook.account_id)
        end
      end

      def get_external_id_from_params(params)
        contact = find_contact_from_params(params)
        contact&.additional_attributes&.dig('external', 'zoho_lead_id')
      end

      def store_external_id(contact, external_id, key = 'zoho_lead_id')
        contact.additional_attributes ||= {}
        contact.additional_attributes['external'] ||= {}
        contact.additional_attributes['external'][key] = external_id
        contact.save(validate: false)
      end

      def get_external_id(contact)
        contact.additional_attributes&.dig('external', 'zoho_lead_id')
      end
    end
  end
end
