# frozen_string_literal: true

class AgentManagerService
  include HTTParty
  
  def initialize(account)
    @account = account
    @endpoint = Rails.application.config.agent_manager_service_endpoint
  end

  def create_customer
    Rails.logger.info("[AgentManagerService] Creating customer for account: #{@account.id}")
    
    begin
      response = HTTParty.post(
        "#{@endpoint}/customers",
        headers: request_headers,
        body: customer_payload.to_json,
        timeout: 30
      )

      if response.success?
        Rails.logger.info("[AgentManagerService] Successfully created customer for account: #{@account.id}")
        return response.parsed_response
      else
        Rails.logger.error("[AgentManagerService] Failed to create customer for account: #{@account.id}. Status: #{response.code}, Body: #{response.body}")
        return nil
      end
    rescue StandardError => e
      Rails.logger.error("[AgentManagerService] Error creating customer for account: #{@account.id}. Error: #{e.message}")
      Rails.logger.error("[AgentManagerService] Error backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  private

  def request_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'X-CHATWOOT-ACCOUNT-ID' => @account.id.to_s
    }
  end

  def customer_payload
    {
      name: @account.name,
      chatwoot_account_id: @account.id
    }
  end
end 