# YCloud Account and WhatsApp Business Account management.
# Balance monitoring and WABA information.
# https://docs.ycloud.com/reference/whatsapp-business-accounts
module Whatsapp::Ycloud
  class AccountService
    pattr_initialize [:whatsapp_channel!]

    # --- Balance ---

    # Retrieve current account balance.
    # @return [HTTParty::Response] with balance amount and currency
    def get_balance
      client.get('/balance')
    end

    # --- WhatsApp Business Accounts ---

    # List all WhatsApp Business Accounts.
    def list_business_accounts(page: 1, limit: 20)
      client.get('/whatsapp/businessAccounts', page: page, limit: limit)
    end

    # Retrieve a specific WhatsApp Business Account by ID.
    def get_business_account(waba_id)
      client.get("/whatsapp/businessAccounts/#{waba_id}")
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
