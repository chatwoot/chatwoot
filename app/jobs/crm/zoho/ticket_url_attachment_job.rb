# frozen_string_literal: true

module Crm
  module Zoho
    class TicketUrlAttachmentJob < ApplicationJob
      queue_as :default
      retry_on StandardError, attempts: 3, wait: 5.seconds

      def perform(ticket_id:, url:, hook_id:)
        ticket = Ticket.find(ticket_id)
        hook   = Integrations::Hook.find(hook_id)

        zoho_ticket_id = ticket.external_id_for('zoho')
        return unless zoho_ticket_id

        blob = download_and_attach(ticket, url)
        return unless blob

        client = Crm::Zoho::Api::TicketClient.new(hook)
        blob.open do |tempfile|
          result = client.upload_attachment(zoho_ticket_id, tempfile)
          store_attachment_id(ticket, blob.id, result) if result&.dig('id')
        end
      end

      private

      def download_and_attach(ticket, url)
        filename = File.basename(URI.parse(url).path).presence || 'attachment'
        response = HTTParty.get(url, follow_redirects: true)
        return unless response.success?

        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(response.body),
          filename: filename,
          content_type: response.headers['content-type'] || 'application/octet-stream'
        )
        ticket.files.attach(blob)
        blob
      end

      def store_attachment_id(ticket, blob_id, result)
        ticket.metadata ||= {}
        ticket.metadata['zoho_attachments'] ||= {}
        ticket.metadata['zoho_attachments'][blob_id.to_s] = result['id']
        ticket.save!
      end
    end
  end
end
