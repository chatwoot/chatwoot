# frozen_string_literal: true

module Crm
  module Zoho
    module Mappers
      # Maps Nauto Console data to Zoho CRM Task/Event format
      class ActivityMapper
        # Map Chatwoot data to Zoho Task format
        #
        # @param params [Hash] Task parameters
        # @option params [String] :contact_id Zoho contact ID
        # @option params [String] :lead_id Zoho lead ID (What_Id)
        # @option params [String] :owner_id Zoho owner ID
        # @option params [String] :subject Task subject
        # @option params [String] :description Task description
        # @option params [String] :due_date Due date (YYYY-MM-DD)
        # @option params [String] :priority Priority (High, Normal, Low)
        # @option params [String] :status Status (Not Started, In Progress, Completed)
        # @option params [Boolean] :send_notification Send email notification
        # @return [Hash] Zoho Task data
        def self.map_task(params = {})
          task_data = {
            Subject: params[:subject] || 'Follow up from Chatwoot',
            Description: params[:description],
            Due_Date: params[:due_date] || (Date.current + 1.day).to_s,
            Priority: params[:priority] || 'Normal',
            Status: params[:status] || 'Not Started',
            Send_Notification_Email: params[:send_notification] || false,
            send_notification: params[:send_notification] || false
          }.compact

          # En Zoho V2/V3, Who_Id es para Contactos
          # What_Id es para Leads (requiere especificar $se_module)
          if params[:lead_id].present?
            task_data[:What_Id] = { id: params[:lead_id] }
            task_data[:'$se_module'] = params[:se_module] || 'Leads'
          elsif params[:contact_id].present?
            task_data[:Who_Id] = { id: params[:contact_id] }
          end

          # Add Owner if specified
          if params[:owner_id].present?
            task_data[:Owner] = { id: params[:owner_id] }
          end

          task_data
        end

        # Map Nauto Console Appointment to Zoho Event format
        #
        # @param appointment [Appointment] Nauto Console appointment
        # @param params [Hash] Additional parameters
        # @option params [String] :contact_id Zoho contact ID
        # @option params [String] :lead_id Zoho lead ID
        # @option params [String] :owner_id Zoho owner ID
        # @option params [Array<Hash>] :participants Event participants
        # @return [Hash] Zoho Event data
        # Map Nauto Console Appointment to Zoho Event format
        #
        # @param appointment_or_params [Appointment, Hash] Appointment model or parameters hash
        # @param params [Hash] Additional parameters
        # @return [Hash] Zoho Event data
        def self.map_event(appointment_or_params, params = {})
          is_appointment = appointment_or_params.is_a?(Appointment)
          p = is_appointment ? params : appointment_or_params

          Rails.logger.info "🔍 [MAPPER] is_appointment: #{is_appointment}"
          Rails.logger.info "🔍 [MAPPER] p (params hash): #{p.inspect}"
          Rails.logger.info "🔍 [MAPPER] p[:contact_id]: #{p[:contact_id].inspect}"
          Rails.logger.info "🔍 [MAPPER] p[:lead_id]: #{p[:lead_id].inspect}"
          Rails.logger.info "🔍 [MAPPER] p[:se_module]: #{p[:se_module].inspect}"

          # Título/Asunto
          subject = if is_appointment
                      appointment_or_params.description
                    else
                      p[:event_title] || p[:subject] || p[:event_subject]
                    end
          subject ||= 'Meeting from Nauto Console'

          # Fechas
          start_at = if is_appointment
                       appointment_or_params.scheduled_at
                     else
                       p[:start_datetime] || p[:start_time] || p[:scheduled_at] || Time.current + 1.hour
                     end

          end_at = if is_appointment
                     appointment_or_params.ended_at || appointment_or_params.scheduled_at + 1.hour
                   else
                     p[:end_datetime] || p[:end_time]
                   end
          end_at ||= start_at + 1.hour

          # Descripción
          description = if is_appointment
                          build_event_description(appointment_or_params)
                        else
                          p[:description]
                        end

          event_data = {
            Subject: subject,                 # Standard field
            Event_Title: subject,             # V3 field name
            Start_DateTime: format_datetime(start_at),
            End_DateTime: format_datetime(end_at),
            Description: description,
            Venue: p[:venue] || (is_appointment ? map_appointment_venue(appointment_or_params) : nil),
            Send_Notification_Email: p[:send_notification] || false
          }.compact

          # Add Who_Id (Contact) if provided
          if p[:contact_id].present?
            Rails.logger.info "🔍 [MAPPER] Añadiendo Who_Id con contact_id: #{p[:contact_id]}"
            event_data[:Who_Id] = { id: p[:contact_id] }
          end

          # Add What_Id (Lead or other related record) if provided
          if p[:lead_id].present?
            Rails.logger.info "🔍 [MAPPER] Añadiendo What_Id con lead_id: #{p[:lead_id]}"
            event_data[:What_Id] = { id: p[:lead_id] }
            event_data[:'$se_module'] = p[:se_module] || 'Leads'
          else
            Rails.logger.info "🔍 [MAPPER] NO añadiendo What_Id porque lead_id no está present"
          end

          # Add Owner if specified
          if p[:owner_id].present?
            event_data[:Owner] = { id: p[:owner_id] }
          end

          # Add participants if provided
          if p[:participants].present?
            event_data[:Participants] = p[:participants]
          end

          event_data
        end

        def self.map_appointment_venue(appointment)
          case appointment.appointment_type
          when 'physical_visit' then appointment.location || 'Office'
          when 'digital_meeting' then 'Video Call'
          when 'phone_call' then 'Phone Call'
          end
        end

        # Map Chatwoot Appointment to Zoho Call format
        #
        # @param appointment [Appointment] Chatwoot appointment
        # @param params [Hash] Additional parameters
        # @option params [String] :owner_id CRM owner ID
        # @return [Hash] Zoho Call data
        def self.map_call_from_appointment(appointment, params = {})
          contact = appointment.contact
          lead_id = contact&.additional_attributes&.dig('external', 'zoho_lead_id')

          # Determinar el status según el appointment status
          zoho_status = map_status_to_zoho(appointment.status)

          # Construir descripción desde appointment
          description = build_call_description(appointment)

          map_call(
            subject: appointment.description || "Call with #{contact&.name || 'Unknown'}",
            description: description,
            call_type: params[:call_type] || 'Outbound',
            start_time: appointment.scheduled_at,
            duration: appointment.duration_minutes ? appointment.duration_minutes * 60 : nil,
            status: zoho_status,
            lead_id: lead_id,
            se_module: 'Leads',
            owner_id: params[:owner_id]
          )
        end

        # Map Chatwoot appointment status to Zoho status
        #
        # @param chatwoot_status [String] Chatwoot status
        # @return [String] Zoho status
        def self.map_status_to_zoho(chatwoot_status)
          Crm::AppointmentStatusConfig.resolve('zoho', chatwoot_status)
        end

        # Build call description from appointment
        #
        # @param appointment [Appointment] Chatwoot appointment
        # @return [String] Call description
        def self.build_call_description(appointment)
          parts = []

          parts << appointment.description if appointment.description.present?
          parts << "Type: Phone Call"
          parts << "Phone: #{appointment.phone_number}" if appointment.phone_number.present?
          parts << "Status: #{appointment.status.humanize}"

          if appointment.participant_agents.any?
            agent_names = appointment.participant_agents.map(&:name).join(', ')
            parts << "Agents: #{agent_names}"
          end

          parts.join("\n")
        end

        # Map phone call to Zoho Call format
        #
        # @param params [Hash] Call parameters
        # @option params [String] :contact_id Zoho contact ID
        # @option params [String] :lead_id Zoho lead ID
        # @option params [String] :subject Call subject
        # @option params [String] :description Call description
        # @option params [String] :call_type Call type (Inbound/Outbound)
        # @option params [DateTime] :start_time Call start time
        # @option params [Integer] :duration Call duration in seconds
        # @return [Hash] Zoho Call data
        def self.map_call(params = {})
          status = params[:status] || 'Scheduled'
          start_time = params[:start_time] || Time.current

          # Para llamadas programadas, Zoho requiere que la hora sea estrictamente a futuro.
          # Agregamos un margen de 5 minutos si es "ahora" para evitar errores de sincronización.
          if status == 'Scheduled' && params[:start_time].blank?
            start_time = Time.current + 5.minutes
          end

          call_data = {
            Subject: params[:subject] || (status == 'Scheduled' ? 'Scheduled Call from Nauto Console' : 'Call from Nauto Console'),
            Call_Type: params[:call_type] || 'Outbound',
            Call_Start_Time: format_datetime(start_time),
            Call_Status: status,            # Standard field
            Outgoing_Call_Status: status,   # Field name from error message (V2.1+)
            Outbound_Call_Status: status,   # Field name from documentation
            Description: params[:description]
          }

          # Zoho rechaza duración cero, y para programadas debe omitirse.
          if status == 'Completed'
            duration_secs = params[:duration].to_i
            hours   = duration_secs / 3600
            minutes = (duration_secs % 3600) / 60
            call_data[:Call_Duration] = format('%<hh>02d:%<mm>02d', hh: hours, mm: minutes)
          end

          # En Zoho V2/V3, Who_Id es para Contactos/Leads
          # What_Id es para otros módulos (Deals, etc)
          # Sin embargo, si se usa What_Id para Leads (según ProcessorService),
          # se REQUIERE especificar $se_module.
          if params[:lead_id].present?
            call_data[:What_Id] = { id: params[:lead_id] }
            call_data[:'$se_module'] = params[:se_module] || 'Leads'
          elsif params[:contact_id].present?
            call_data[:Who_Id] = { id: params[:contact_id] }
          end

          # Add Owner if specified
          if params[:owner_id].present?
            call_data[:Owner] = { id: params[:owner_id] }
          end

          call_data.compact
        end

        # Format datetime to Zoho format (ISO 8601 with timezone)
        #
        # @param datetime [DateTime, Time] DateTime to format
        # @return [String] Formatted datetime
        def self.format_datetime(datetime)
          return nil unless datetime
          return datetime if datetime.is_a?(String)

          datetime.iso8601
        end

        # Build event description from appointment
        #
        # @param appointment [Appointment] Nauto Console appointment
        # @return [String] Event description
        def self.build_event_description(appointment)
          parts = []

          parts << appointment.description if appointment.description.present?
          parts << "Type: #{appointment.appointment_type.humanize}"
          parts << "Status: #{appointment.status.humanize}"

          if appointment.participant_agents.any?
            agent_names = appointment.participant_agents.map(&:name).join(', ')
            parts << "Agents: #{agent_names}"
          end

          parts.join("\n")
        end
      end
    end
  end
end
