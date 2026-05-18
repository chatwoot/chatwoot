module ChatwootGlpiIntegration
  class SyncTicketJob < ::ApplicationJob
    queue_as :integrations

    retry_on GlpiClient::RemoteError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveRecord::RecordNotFound

    def perform(link_id)
      link = TicketLink.find(link_id)
      SyncTicketService.new(link).call
    end
  end
end
