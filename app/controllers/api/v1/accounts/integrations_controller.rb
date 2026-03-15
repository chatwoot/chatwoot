# frozen_string_literal: true

class Api::V1::Accounts::IntegrationsController < Api::V1::Accounts::BaseController
  def index
    slug = Current.account.hub_client_slug
    return render json: { actions: [], active_products: [] } if slug.blank? || !Igaralead::HubClient.configured?

    client = Igaralead::HubClient.new
    data = client.get("/api/v1/integrations/#{slug}/actions/nexus")

    render json: data || { actions: [] }
  rescue Faraday::Error => e
    Rails.logger.warn("[Igaralead] Hub integrations fetch failed: #{e.message}")
    render json: { actions: [], error: 'hub_unavailable' }
  end
end
