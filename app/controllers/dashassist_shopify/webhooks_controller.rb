module DashassistShopify
  class WebhooksController < ActionController::Base
    include Shopify::IntegrationHelper
    
    protect_from_forgery with: :null_session
    before_action :setup_shopify_context
    before_action :verify_webhook_hmac
    
    # Handles app uninstalled webhooks
    # Shopify sends this immediately when a merchant uninstalls your app
    def app_uninstalled
      Rails.logger.info("[Shopify Webhooks] [app_uninstalled] Received app/uninstalled webhook")
      
      # Extract shop info from the payload
      payload = JSON.parse(request.body.read)
      
      # Debug: Print the full payload to see what we're receiving
      Rails.logger.info("[Shopify Webhooks] [app_uninstalled] Full payload: #{payload.inspect}")
      
      # For app/uninstalled webhook, shop domain is in 'domain' field
      shop_domain = payload['domain']
      shop_id = payload['id']
      
      Rails.logger.info("[Shopify Webhooks] [app_uninstalled] Processing app uninstall for shop: #{shop_domain}")
      
      # Use WebhookProcessor service to handle the webhook
      processor = DashassistShopify::WebhookProcessor.new(shop_domain, payload)
      result = processor.process_app_uninstalled
      
      if result[:success]
        Rails.logger.info("[Shopify Webhooks] [app_uninstalled] Successfully processed app uninstall for shop: #{shop_domain}")
        else
        Rails.logger.error("[Shopify Webhooks] [app_uninstalled] Failed to process app uninstall for shop: #{shop_domain}: #{result[:error]}")
      end
      
      # Acknowledge receipt of the webhook
      head :ok
    end
    
    # Handles customer data request webhooks
    # Shopify sends this when customers request their data
    def customers_data_request
      Rails.logger.info("[Shopify Webhooks] [customers_data_request] Received customers/data_request webhook")
      
      # Extract customer and shop info from the payload
      payload = JSON.parse(request.body.read)
      
      # Debug: Print the full payload to see what we're receiving
      Rails.logger.info("[Shopify Webhooks] [customers_data_request] Full payload: #{payload.inspect}")
      
      shop_domain = payload['shop_domain']
      customer_email = payload['customer']['email']
      customer_id = payload['customer']['id']
      
      Rails.logger.info("[Shopify Webhooks] [customers_data_request] Processing data request for customer: #{customer_email} from shop: #{shop_domain}")
      
      # Use WebhookProcessor service to handle the webhook
      processor = DashassistShopify::WebhookProcessor.new(shop_domain, payload)
      result = processor.process_customers_data_request
      
      if result[:success]
        Rails.logger.info("[Shopify Webhooks] [customers_data_request] Successfully processed customer data request for shop: #{shop_domain}")
      else
        Rails.logger.error("[Shopify Webhooks] [customers_data_request] Failed to process customer data request for shop: #{shop_domain}: #{result[:error]}")
      end
      
      # Acknowledge receipt of the webhook
      head :ok
    end
    
    # Handles customer data deletion webhooks
    # Shopify sends this when customers request deletion of their data
    def customers_redact
      Rails.logger.info("[Shopify Webhooks] [customers_redact] Received customers/redact webhook")
      
      # Extract customer and shop info from the payload
      payload = JSON.parse(request.body.read)
      
      # Debug: Print the full payload to see what we're receiving
      Rails.logger.info("[Shopify Webhooks] [customers_redact] Full payload: #{payload.inspect}")
      
      shop_domain = payload['shop_domain']
      customer_email = payload['customer']['email']
      customer_id = payload['customer']['id']
      
      Rails.logger.info("[Shopify Webhooks] [customers_redact] Processing redaction request for customer: #{customer_email} from shop: #{shop_domain}")
      
      # Use WebhookProcessor service to handle the webhook
      processor = DashassistShopify::WebhookProcessor.new(shop_domain, payload)
      result = processor.process_customers_redact
      
      if result[:success]
        Rails.logger.info("[Shopify Webhooks] [customers_redact] Successfully processed customer redaction for shop: #{shop_domain}")
      else
        Rails.logger.error("[Shopify Webhooks] [customers_redact] Failed to process customer redaction for shop: #{shop_domain}: #{result[:error]}")
      end
      
      # Acknowledge receipt of the webhook
      head :ok
    end
    
    # Handles shop data deletion webhooks
    # Shopify sends this 48 hours after a merchant uninstalls your app
    def shop_redact
      Rails.logger.info("[Shopify Webhooks] [shop_redact] Received shop/redact webhook")
      
      # Extract shop info from the payload
      payload = JSON.parse(request.body.read)
      
      # Debug: Print the full payload to see what we're receiving
      Rails.logger.info("[Shopify Webhooks] [shop_redact] Full payload: #{payload.inspect}")
      
      shop_domain = payload['shop_domain']
      shop_id = payload['shop_id']
      
      Rails.logger.info("[Shopify Webhooks] [shop_redact] Processing shop redaction for: #{shop_domain}")
      
      # Use WebhookProcessor service to handle the webhook
      processor = DashassistShopify::WebhookProcessor.new(shop_domain, payload)
      result = processor.process_shop_redact
      
      if result[:success]
        Rails.logger.info("[Shopify Webhooks] [shop_redact] Successfully processed shop redaction for shop: #{shop_domain}")
        else
        Rails.logger.error("[Shopify Webhooks] [shop_redact] Failed to process shop redaction for shop: #{shop_domain}: #{result[:error]}")
      end
      
      # Acknowledge receipt of the webhook
      head :ok
    end
  end
end 