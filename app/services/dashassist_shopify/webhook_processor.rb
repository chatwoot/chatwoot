module DashassistShopify
  class WebhookProcessor
    attr_reader :shop_domain, :payload

    def initialize(shop_domain, payload = {})
      @shop_domain = shop_domain
      @payload = payload
    end

    # Process app uninstalled webhook
    def process_app_uninstalled
      Rails.logger.info("[DashassistShopify::WebhookProcessor] Processing app uninstall for shop: #{shop_domain}")
      
      # Use TokenManager to handle token removal
      token_manager = TokenManager.new(shop_domain)
      
      if token_manager.has_valid_token?
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Found Shopify session to delete for shop: #{shop_domain}")
        # Remove the token from both storage locations
        token_manager.remove_token
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Successfully removed Shopify token for shop: #{shop_domain}")
      else
        Rails.logger.warn("[DashassistShopify::WebhookProcessor] No Shopify session found for shop: #{shop_domain}")
      end

      # Make the web widget invisible by disabling the channel
      disable_web_widget
      
      { success: true }
    end

    # Process shop redaction webhook
    def process_shop_redact
      Rails.logger.info("[DashassistShopify::WebhookProcessor] Processing shop redaction for: #{shop_domain}")
      
      # Use TokenManager to handle token removal
      token_manager = TokenManager.new(shop_domain)
      
      # Remove token from both storage locations
      if token_manager.has_valid_token?
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Found Shopify session to delete for shop: #{shop_domain}")
        token_manager.remove_token
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Successfully removed Shopify token for shop: #{shop_domain}")
      else
        Rails.logger.warn("[DashassistShopify::WebhookProcessor] No Shopify session found for shop: #{shop_domain}")
      end

      # Delete Shopify store and related data if found
      shopify_store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
      if shopify_store
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Found Shopify store to delete for shop: #{shop_domain}")
        
        # Get the account before destroying the store
        account = shopify_store.account
        
        # Delete the Shopify store record
        shopify_store.destroy
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Successfully deleted Shopify store for shop: #{shop_domain}")
        
        # Delete the entire account and all related data
        if account
          Rails.logger.info("[DashassistShopify::WebhookProcessor] Deleting account and all related data for shop: #{shop_domain}")
          
          # Account.destroy will automatically cascade delete all associated records
          # due to dependent: :destroy_async associations in the Account model
          account.destroy
          Rails.logger.info("[DashassistShopify::WebhookProcessor] Successfully deleted account for shop: #{shop_domain}")
        else
          Rails.logger.warn("[DashassistShopify::WebhookProcessor] No account found for shop: #{shop_domain}")
        end
      else
        Rails.logger.warn("[DashassistShopify::WebhookProcessor] No Shopify store found for shop: #{shop_domain}")
      end
      
      { success: true }
    end

    # Process customer data request webhook
    def process_customers_data_request
      Rails.logger.info("[DashassistShopify::WebhookProcessor] Processing data request for customer from shop: #{shop_domain}")
      
      # Extract customer info from payload
      customer_email = payload.dig('customer', 'email')
      customer_id = payload.dig('customer', 'id')
      
      Rails.logger.info("[DashassistShopify::WebhookProcessor] Customer data request: email=#{customer_email}, id=#{customer_id}")
      
      # Find the relevant customer data in your system
      # TODO: Implement actual data collection logic here
      # This should gather all personal data you store related to this customer
      
      # For proper GDPR compliance, you should email this data directly to the merchant
      # (who will then provide it to the customer)
      
      { success: true }
    end

    # Process customer data deletion webhook
    def process_customers_redact
      Rails.logger.info("[DashassistShopify::WebhookProcessor] Processing redaction request for customer from shop: #{shop_domain}")
      
      # Extract customer info from payload
      customer_email = payload.dig('customer', 'email')
      customer_id = payload.dig('customer', 'id')
      
      Rails.logger.info("[DashassistShopify::WebhookProcessor] Customer redaction request: email=#{customer_email}, id=#{customer_id}")
      
      # Delete or anonymize all customer data in your system
      # TODO: Implement actual data deletion logic here
      # This should remove or anonymize all personal data you store for this customer
      
      { success: true }
    end

    # Process any webhook by type
    def process_webhook(webhook_type)
      case webhook_type
      when 'app/uninstalled'
        process_app_uninstalled
      when 'shop/redact'
        process_shop_redact
      when 'customers/data_request'
        process_customers_data_request
      when 'customers/redact'
        process_customers_redact
      else
        Rails.logger.warn("[DashassistShopify::WebhookProcessor] Unknown webhook type: #{webhook_type}")
        { success: false, error: "Unknown webhook type: #{webhook_type}" }
      end
    end

    # Batch process multiple webhooks
    def self.process_webhooks(webhooks)
      results = {}
      
      webhooks.each do |webhook|
        shop_domain = webhook[:shop_domain]
        webhook_type = webhook[:type]
        payload = webhook[:payload] || {}
        
        processor = new(shop_domain, payload)
        results[shop_domain] = processor.process_webhook(webhook_type)
      end
      
      results
    end

    private

    # Disable the web widget by setting the store to disabled
    def disable_web_widget
      store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
      
      if store
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Disabling web widget for shop: #{shop_domain}")
        store.update!(enabled: false)
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Successfully disabled web widget for shop: #{shop_domain}")
      else
        Rails.logger.warn("[DashassistShopify::WebhookProcessor] No Shopify store found for shop: #{shop_domain}")
      end
    end

    # Re-enable the web widget by setting the store to enabled
    def enable_web_widget
      store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
      
      if store
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Re-enabling web widget for shop: #{shop_domain}")
        store.update!(enabled: true)
        Rails.logger.info("[DashassistShopify::WebhookProcessor] Successfully re-enabled web widget for shop: #{shop_domain}")
      else
        Rails.logger.warn("[DashassistShopify::WebhookProcessor] No Shopify store found for shop: #{shop_domain}")
      end
    end
  end
end 