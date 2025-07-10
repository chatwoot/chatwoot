# Handles WhatsApp token validation
module Whatsapp::TokenValidator
  extend ActiveSupport::Concern

  def validate_token_waba_access(access_token, waba_id)
    token_debug_data = fetch_token_debug_data(access_token)
    waba_scope = extract_waba_scope(token_debug_data)
    verify_waba_authorization(waba_scope, waba_id)
  end

  private

  def fetch_token_debug_data(access_token)
    response = Faraday.get(
      "https://graph.facebook.com/#{whatsapp_api_version}/debug_token",
      {
        input_token: access_token,
        access_token: build_app_access_token
      }
    )

    raise "Token validation failed: #{response.body}" unless response.success?

    JSON.parse(response.body)
  end

  def extract_waba_scope(token_data)
    granular_scopes = token_data.dig('data', 'granular_scopes')
    waba_scope = granular_scopes&.find { |scope| scope['scope'] == 'whatsapp_business_management' }

    raise 'No WABA scope found in token' unless waba_scope

    waba_scope
  end

  def verify_waba_authorization(waba_scope, waba_id)
    authorized_waba_ids = waba_scope['target_ids'] || []

    return if authorized_waba_ids.include?(waba_id)

    raise "Token does not have access to WABA #{waba_id}. Authorized WABAs: #{authorized_waba_ids}"
  end
end