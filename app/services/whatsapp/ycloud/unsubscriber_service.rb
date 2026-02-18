# YCloud Unsubscriber management.
# Track customer opt-out preferences per channel to comply with regulations.
# https://docs.ycloud.com/reference/unsubscribers
module Whatsapp::Ycloud
  class UnsubscriberService
    pattr_initialize [:whatsapp_channel!]

    # Add an unsubscriber (opt-out a customer).
    # @param params [Hash]:
    #   - customer [String] Phone number or email
    #   - channel [String] 'whatsapp' | 'sms' | 'email'
    def create(params)
      client.post('/unsubscribers', params)
    end

    # List unsubscribers with pagination.
    # @param page [Integer]
    # @param limit [Integer]
    def list(page: 1, limit: 20)
      client.get('/unsubscribers', page: page, limit: limit)
    end

    # List all unsubscribers for a specific customer across all channels.
    def list_all_for_customer(customer)
      client.get('/unsubscribers/all', customer: customer)
    end

    # Check if a customer is unsubscribed from a specific channel.
    # @param customer [String] Phone number or email
    # @param channel [String] 'whatsapp' | 'sms' | 'email'
    def check(customer, channel)
      response = client.get("/unsubscribers/#{customer}/#{channel}")
      response.success?
    end

    # Remove an unsubscriber (re-subscribe a customer).
    def delete(customer, channel)
      client.delete("/unsubscribers/#{customer}/#{channel}")
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
