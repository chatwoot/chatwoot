# frozen_string_literal: true

module Crm
  module Zoho
    module Api
      class TicketClient < Crm::Zoho::BaseClient
        API_PATH = '/api/v1'

        def create_ticket(ticket_data)
          request(:post, "#{API_PATH}/tickets", body: ticket_data.to_json)
        end

        def get_ticket(ticket_id)
          request(:get, "#{API_PATH}/tickets/#{ticket_id}")
        end

        def get_departments
          request(:get, "#{API_PATH}/departments")
        end

        def upload_attachment(ticket_id, file_io)
          url = "#{base_url}#{API_PATH}/tickets/#{ticket_id}/attachments"
          headers = {
            'Authorization' => "Zoho-oauthtoken #{@credentials['access_token']}",
            'orgId' => desk_org_id
          }

          ensure_valid_token!

          response = HTTParty.post(url, headers: headers, multipart: true, body: { file: file_io })
          handle_response(response)
        end

        private

        def base_url
          crm_domain = @credentials['api_domain'] || ENV.fetch('ZOHO_API_DOMAIN', 'https://www.zohoapis.com')
          crm_domain.gsub('www.zohoapis', 'desk.zoho')
        end

        def default_headers
          {
            'Authorization' => "Zoho-oauthtoken #{@credentials['access_token']}",
            'Content-Type' => 'application/json',
            'orgId' => desk_org_id
          }
        end

        def desk_org_id
          @credentials['desk_soid']
        end
      end
    end
  end
end
