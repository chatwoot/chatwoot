# frozen_string_literal: true

module Crm
  module Zoho
    module Mappers
      class TicketMapper
        # Map Nauto Console data to Zoho Desk Ticket format
        #
        # @param contact [Contact, nil] Nauto Console contact
        # @param params [Hash] Ticket parameters
        # @option params [String] :subject Ticket subject
        # @option params [String] :description Ticket description
        # @option params [Hash] :metadata AI metadata with ticket_subject, ticket_description, etc.
        # @return [Hash] Zoho Desk ticket data
        def self.map_ticket(contact, params = {})
          metadata = params[:metadata] || {}

          subject = metadata['ticket_subject'].presence || metadata['subject'].presence || params[:subject]
          description = metadata['ticket_description'].presence || metadata['description'].presence || params[:description]
          priority = metadata['priority'].presence || params[:priority]
          classification = metadata['classification'].presence || params[:classification]

          ticket_data = {
            subject: subject,
            description: description,
            priority: priority,
            classification: classification
          }.compact

          if contact
            desk_contact_id = contact.additional_attributes&.dig('external', 'zoho_desk_contact_id')

            if desk_contact_id.present?
              ticket_data[:contactId] = desk_contact_id
            else
              ticket_data[:contact] = build_contact(contact)
            end

            ticket_data[:email] = contact.email if contact.email.present?
            ticket_data[:phone] = contact.phone_number if contact.phone_number.present?
          end

          ticket_data
        end

        def self.build_contact(contact)
          {
            lastName: contact.name.presence || 'Unknown',
            email: contact.email,
            phone: contact.phone_number
          }.compact
        end
      end
    end
  end
end
