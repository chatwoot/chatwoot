class Shopify::PartnerClient
  DEFAULT_API_VERSION = Shopify::PartnerConfiguration::DEFAULT_API_VERSION
  REQUEST_TIMEOUT = 5
  SUBSCRIPTION_EVENT_TYPES = %w[
    SUBSCRIPTION_CANCELED
    SUBSCRIPTION_CANCELLATION_SCHEDULED
    SUBSCRIPTION_CREATED
    SUBSCRIPTION_FROZEN
    SUBSCRIPTION_UNFROZEN
    SUBSCRIPTION_UPDATED
  ].freeze
  QUERY = <<~GRAPHQL.freeze
    query Subscription($appId: ID!, $shopId: ID!, $occurredAtMin: DateTime!) {
      activeSubscription(appId: $appId, shopId: $shopId) {
        shop {
          id
          myshopifyDomain
        }
        billingPeriod
        cancelAtEndOfCycle
        trialEndsAt
        currentBillingCycle {
          startTime
          endTime
        }
        items {
          handle
          description
          price {
            __typename
            currency
            ... on FlatRatePrice {
              amount
            }
          }
        }
      }
      events(
        first: 1
        orderBy: OCCURRED_AT_DESC
        filter: {
          eventTypes: [#{SUBSCRIPTION_EVENT_TYPES.join(', ')}]
          occurredAtMin: $occurredAtMin
          shopId: $shopId
          subjectId: $appId
        }
      ) {
        edges {
          node {
            ... on SubscriptionStatus {
              state
              cancelEffectiveOn
              occurredAt
            }
          }
        }
      }
    }
  GRAPHQL

  class ConfigurationError < StandardError; end
  class ProviderError < StandardError; end

  def subscription_snapshot(shop_id:, verified_at: nil)
    response = request(shop_id)
    validate_response!(response)
    Shopify::SubscriptionSnapshot.from_partner_response(response.parsed_response.fetch('data'), verified_at: verified_at || Time.current)
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
    raise ProviderError, "Shopify Partner API request failed (#{e.class.name})"
  rescue JSON::ParserError, KeyError, NoMethodError, TypeError
    raise ProviderError, 'Shopify Partner API returned an invalid response'
  end

  private

  def request(shop_id)
    HTTParty.post(
      endpoint,
      headers: {
        'Content-Type' => 'application/json',
        'X-Shopify-Access-Token' => access_token
      },
      body: {
        query: QUERY,
        variables: {
          appId: app_id,
          shopId: shop_id,
          occurredAtMin: 364.days.ago.iso8601
        }
      }.to_json,
      timeout: REQUEST_TIMEOUT
    )
  end

  def endpoint
    "https://partners.shopify.com/#{organization_id}/api/#{api_version}/graphql.json"
  end

  def organization_id
    configuration.organization_id
  end

  def app_id
    configuration.app_id
  end

  def access_token
    configuration.access_token
  end

  def api_version
    configuration.api_version
  end

  def configuration
    @configuration ||= Shopify::PartnerConfiguration.current
  end

  def validate_response!(response)
    raise ProviderError, "Shopify Partner API returned HTTP #{response.code}" unless response.success?

    body = response.parsed_response
    raise ProviderError, 'Shopify Partner API returned GraphQL errors' if body.is_a?(Hash) && body['errors'].present?
    raise ProviderError, 'Shopify Partner API returned an invalid response' unless valid_response_data?(body)
  end

  def valid_response_data?(body)
    data = body['data'] if body.is_a?(Hash)
    data.is_a?(Hash) &&
      data.key?('activeSubscription') &&
      data.dig('events', 'edges').is_a?(Array)
  end
end
