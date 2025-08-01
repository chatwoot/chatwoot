class ShopifyInboxCreatorService
  include HTTParty
  def initialize(user, shop_domain)
    @user = user
    @shop_domain = shop_domain
  end

  def setup_shopify_integration_account_and_inbox
    Rails.logger.info("[ShopifyInboxCreator] Creating inbox for user: #{@user.id}, shop: #{@shop_domain}")
    
    # Validate shop domain
    unless valid_shop_domain?
      Rails.logger.error("[ShopifyInboxCreator] Invalid shop domain format: #{@shop_domain}")
      return false
    end

    # Find or create account
    account = create_account
    
    # Enable Shopify integration feature
    account.enable_features!(:shopify_integration)
    Rails.logger.info("[ShopifyInboxCreator] Enabled shopify_integration feature for account: #{account.id}")

    # Create all Shopify resources
    @created_inbox = create_shopify_resources(account)
    
    Rails.logger.info("[ShopifyInboxCreator] Successfully created Shopify inbox for user: #{@user.id}, shop: #{@shop_domain}")
    true
  rescue StandardError => e
    Rails.logger.error("[ShopifyInboxCreator] Error creating inbox: #{e.message}")
    Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
    false
  end

  def setup_shopify_integration_for_account(account)
    Rails.logger.info("[ShopifyInboxCreator] Setting up Shopify integration for account: #{account.id}")
    
    # Enable Shopify integration feature
    account.enable_features!(:shopify_integration)
    Rails.logger.info("[ShopifyInboxCreator] Enabled shopify_integration feature for account: #{account.id}")

    # Create all Shopify resources
    @created_inbox = create_shopify_resources(account)
    
    Rails.logger.info("[ShopifyInboxCreator] Successfully created Shopify inbox for user: #{@user.id}, shop: #{@shop_domain}")
    true
  rescue StandardError => e
    Rails.logger.error("[ShopifyInboxCreator] Error creating inbox: #{e.message}")
    Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
    false
  end

  def created_inbox
    @created_inbox
  end

  private

  def valid_shop_domain?
    @shop_domain.match?(/^[a-zA-Z0-9][a-zA-Z0-9-]*\.myshopify\.com$/)
  end

  def create_account
    # No account exists for this shop, create new account
    Rails.logger.info("[ShopifyInboxCreator] No account found for shop, creating new account for shop: #{@shop_domain}")
    account = Account.create!(
      name: @shop_domain
    )
    
    # Grant access to the user
    AccountUser.create!(
      account: account,
      user: @user,
      role: 'administrator'
    )

    Rails.logger.info("[ShopifyInboxCreator] Created account and granted access: account_id=#{account.id}")
    
    # Call agent manager service to create customer
    call_agent_manager_service_for_customer(account)
    
    return account
  end

  def call_agent_manager_service_for_customer(account)
    Rails.logger.info("[ShopifyInboxCreator] Calling agent manager service for customer creation: #{account.id}")
    
    begin
      agent_manager_service = AgentManagerService.new(account)
      result = agent_manager_service.create_customer
      
      if result
        Rails.logger.info("[ShopifyInboxCreator] Successfully called agent manager service for customer creation: #{account.id}")
      else
        Rails.logger.warn("[ShopifyInboxCreator] Failed to call agent manager service for customer creation: #{account.id}")
      end
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error calling agent manager service for customer creation: #{account.id}. Error: #{e.message}")
      # Don't raise the error to avoid breaking account creation
    end
  end

  def create_shopify_resources(account)
    # Check if there's an existing ShopifyStore record with inbox_id = 0
    existing_store = Dashassist::ShopifyStore.find_by(shop: @shop_domain)
    
    # Create web widget
    Rails.logger.info("[ShopifyInboxCreator] Creating web widget for shop: #{@shop_domain}")
    web_widget = Channel::WebWidget.create!(
      account: account,
      website_url: "https://#{@shop_domain}",
      widget_color: '#5B23B5',
      welcome_title: "Welcome to #{@shop_domain}",
      welcome_tagline: 'How can we help you today?'
    )
    Rails.logger.info("[ShopifyInboxCreator] Created web widget: id=#{web_widget.id}")

    # Create inbox for the web widget
    Rails.logger.info("[ShopifyInboxCreator] Creating inbox for web widget: #{web_widget.id}")
    inbox = Inbox.create!(
      account: account,
      name: 'Shopify',
      channel: web_widget
    )
    Rails.logger.info("[ShopifyInboxCreator] Created inbox: id=#{inbox.id}")

    # Create ShopifyStore record
    store = Dashassist::ShopifyStore.create!(
      shop: @shop_domain,
      account_id: account.id,
      inbox_id: inbox.id,
      enabled: true
    )
    Rails.logger.info("[ShopifyInboxCreator] Created store mapping: shop=#{@shop_domain}, inbox_id=#{inbox.id}")

    # Create Integrations::Hook for Shopify
    create_shopify_hook(account)

    # Get customer_id once to reuse for both AI agent and datasource creation
    customer_id = get_customer_id_from_agent_manager(account.id)
    unless customer_id
      Rails.logger.error("[ShopifyInboxCreator] No customer found for account: #{account.id}")
      return inbox
    end

    Rails.logger.info("[ShopifyInboxCreator] Found customer_id: #{customer_id} for account: #{account.id}")

    # Create AI agent for the shop
    agent = create_default_shopify_ai_agent(account, customer_id)
    
    # Connect inbox to agent bot if agent was created successfully
    if agent && agent['chatwoot_agent_bot_id']
      connect_inbox_to_agent_bot_from_id(inbox, agent['chatwoot_agent_bot_id'])
    else
      Rails.logger.warn("[ShopifyInboxCreator] No agent bot ID available, skipping inbox-agent bot connection")
    end

    # Return the created inbox
    inbox
  end

  def create_shopify_hook(account)
    shopify_session = Dashassist::ShopifySession.find_by(shop: @shop_domain)
    if shopify_session
      Rails.logger.info("[ShopifyInboxCreator] Creating Integrations::Hook for shop: #{@shop_domain}")
      hook = account.hooks.find_or_initialize_by(app_id: 'shopify')
      hook.update!(
        access_token: shopify_session.access_token,
        status: 'enabled',
        reference_id: @shop_domain,
        settings: {
          scope: shopify_session.scope.join(',')
        }
      )
      Rails.logger.info("[ShopifyInboxCreator] Created Integrations::Hook for shop: #{@shop_domain}")
    else
      Rails.logger.warn("[ShopifyInboxCreator] No ShopifySession found for shop: #{@shop_domain}")
    end
  end

  def create_default_shopify_ai_agent(account, customer_id)
    Rails.logger.info("[ShopifyInboxCreator] Creating AI agent for shop: #{@shop_domain}")
    
    begin
      # Step 1: Create AI agent first (without datasource initially)
      Rails.logger.info("[ShopifyInboxCreator] Step 1: Creating AI agent...")
      agent = create_ai_agent(account.id)

      unless agent
        Rails.logger.error("[ShopifyInboxCreator] Failed to create AI agent")
        return false
      end

      # Log agent bot ID if available
      if agent['chatwoot_agent_bot_id']
        Rails.logger.info("[ShopifyInboxCreator] Created agent with bot ID: #{agent['chatwoot_agent_bot_id']} for agent: #{agent['id']}")
      else
        Rails.logger.warn("[ShopifyInboxCreator] No agent bot ID available for agent: #{agent['id']}")
      end

      # Create a datasource for the shop domain
      create_shopify_datasource(account, customer_id)

      # Connect tools to the agent
      connect_tools_to_agent(agent, customer_id, account)
      
      # Return the agent data so it can be used for connecting to inbox
      return agent
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error creating AI agent: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
      false
    end
  end

  def get_customer_id_from_agent_manager(account_id)
    Rails.logger.info("[ShopifyInboxCreator] Getting customer ID from agent manager for account: #{account_id}")
    
    begin
      endpoint = Rails.application.config.agent_manager_service_endpoint
      response = HTTParty.get(
        "#{endpoint}/customers/chatwoot/#{account_id}",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account_id.to_s
        },
        timeout: 30
      )

      if response.success?
        customer_data = response.parsed_response
        if customer_data && customer_data['data'] && customer_data['data']['id']
          Rails.logger.info("[ShopifyInboxCreator] Successfully retrieved customer ID: #{customer_data['data']['id']} for account: #{account_id}")
          return customer_data['data']['id']
        else
          Rails.logger.error("[ShopifyInboxCreator] Invalid response format from agent manager for account: #{account_id}")
          return nil
        end
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to get customer from agent manager for account: #{account_id}. Status: #{response.code}, Body: #{response.body}")
        return nil
      end
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error getting customer from agent manager for account: #{account_id}. Error: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def create_ai_agent(account_id)
    Rails.logger.info("[ShopifyInboxCreator] Creating AI agent without datasource for account: #{account_id}")
    
    begin
      endpoint = Rails.application.config.agent_manager_service_endpoint
      
      # Create a basic AI agent for Shopify
      agent_payload = {
        name: "Shopify Assistant",
        model: "gpt-4.1-mini",
        description: SHOPIFY_AI_AGENT_DESCRIPTION % { shop_domain: @shop_domain },
        tools: [],
        datasources: []
      }
      
      response = HTTParty.post(
        "#{endpoint}/agents",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account_id.to_s
        },
        body: agent_payload.to_json,
        timeout: 30
      )

      if response.success?
        agent_data = response.parsed_response
        if agent_data && agent_data['data'] && agent_data['data']['id']
          Rails.logger.info("[ShopifyInboxCreator] Successfully created AI agent: #{agent_data['data']['id']} for account: #{account_id}")
          
          # Log agent bot ID if available
          if agent_data['data']['chatwoot_agent_bot_id']
            Rails.logger.info("[ShopifyInboxCreator] Agent bot ID: #{agent_data['data']['chatwoot_agent_bot_id']} for agent: #{agent_data['data']['id']}")
          else
            Rails.logger.warn("[ShopifyInboxCreator] No agent bot ID found in response for agent: #{agent_data['data']['id']}")
          end
          
          return agent_data['data']
        else
          Rails.logger.error("[ShopifyInboxCreator] Invalid response format from agent manager for agent creation")
          return nil
        end
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to create AI agent for account: #{account_id}. Status: #{response.code}, Body: #{response.body}")
        return nil
      end
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error creating AI agent for account: #{account_id}. Error: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def connect_tools_to_agent(agent, customer_id, account)
    unless agent && agent['id']
      Rails.logger.error("[ShopifyInboxCreator] Invalid agent object provided to connect_tools_to_agent")
      return
    end
    
    Rails.logger.info("[ShopifyInboxCreator] Connecting Shopify tools to agent: #{agent['id']}")
    
    begin
      endpoint = Rails.application.config.agent_manager_service_endpoint
      
      # Get Shopify session for access token
      shopify_session = Dashassist::ShopifySession.find_by(shop: @shop_domain)
      access_token = shopify_session&.access_token
      
      if access_token
        # Configure Shopify tools
        configure_shopify_tools(endpoint, customer_id, access_token, account, agent['id'])
      else
        Rails.logger.warn("[ShopifyInboxCreator] No access token found for shop: #{@shop_domain}, agent created without Shopify tools")
      end
      
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error connecting tools to agent: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
    end
  end

  def configure_shopify_tools(endpoint, customer_id, access_token, account, agent_id)
    Rails.logger.info("[ShopifyInboxCreator] Configuring Shopify tools for customer: #{customer_id}, agent: #{agent_id}")
    
    begin
      # Configure Shopify Order Tool
      order_tool_payload = {
        customer_id: customer_id,
        shop_domain: @shop_domain,
        access_token: access_token,
        agent_id: agent_id
      }
      
      order_response = HTTParty.post(
        "#{endpoint}/tools/shopify/order-tool",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account.id.to_s
        },
        body: order_tool_payload.to_json,
        timeout: 30
      )
      
      if order_response.success?
        Rails.logger.info("[ShopifyInboxCreator] Successfully configured Shopify order tool for customer: #{customer_id}, agent: #{agent_id}")
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to configure Shopify order tool. Status: #{order_response.code}, Body: #{order_response.body}")
      end
      
      # Configure Shopify Product Tool
      product_tool_payload = {
        customer_id: customer_id,
        shop_domain: @shop_domain,
        access_token: access_token,
        limit: 50,
        buy_now_template: "https://#{@shop_domain}/cart/add?id={product_id}&variant={variant_id}",
        agent_id: agent_id
      }
      
      product_response = HTTParty.post(
        "#{endpoint}/tools/shopify/product-tool",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account.id.to_s
        },
        body: product_tool_payload.to_json,
        timeout: 30
      )
      
      if product_response.success?
        Rails.logger.info("[ShopifyInboxCreator] Successfully configured Shopify product tool for customer: #{customer_id}, agent: #{agent_id}")
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to configure Shopify product tool. Status: #{product_response.code}, Body: #{product_response.body}")
      end
      
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error configuring Shopify tools: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
    end
  end

  def create_shopify_datasource(account, customer_id)
    Rails.logger.info("[ShopifyInboxCreator] Creating datasource for shop: #{@shop_domain}")
    
    begin
      endpoint = Rails.application.config.agent_manager_service_endpoint
      
      # Send as form data instead of JSON
      response = HTTParty.post(
        "#{endpoint}/datasources",
        headers: {
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account.id.to_s
        },
        body: {
          type: "web_url",
          description: "Shopify store website for #{@shop_domain}",
          web_url: "https://#{@shop_domain}"
        },
        timeout: 30
      )

      if response.success?
        datasource_data = response.parsed_response
        if datasource_data && datasource_data['data'] && datasource_data['data']['id']
          datasource_id = datasource_data['data']['id']
          Rails.logger.info("[ShopifyInboxCreator] Successfully created datasource: #{datasource_id} for shop: #{@shop_domain}")
          
          # Connect datasource to the agent
          connect_datasource_to_agent(datasource_id, account)
          
          return datasource_data['data']
        else
          Rails.logger.error("[ShopifyInboxCreator] Invalid response format from agent manager for datasource creation")
          return nil
        end
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to create datasource for shop: #{@shop_domain}. Status: #{response.code}, Body: #{response.body}")
        return nil
      end
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error creating datasource for shop: #{@shop_domain}. Error: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def connect_datasource_to_agent(datasource_id, account)
    Rails.logger.info("[ShopifyInboxCreator] Connecting datasource #{datasource_id} to agent")
    
    begin
      endpoint = Rails.application.config.agent_manager_service_endpoint
      
      # Get the agent ID from the account
      agent_id = get_agent_id_for_account(account.id)
      unless agent_id
        Rails.logger.error("[ShopifyInboxCreator] No agent found for account: #{account.id}")
        return
      end
      
      # Connect datasource to agent
      datasource_payload = {
        datasource_id: datasource_id,
        agent_ids: [agent_id],
        metadata: {}
      }
      
      response = HTTParty.post(
        "#{endpoint}/agent-datasources/add",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account.id.to_s
        },
        body: datasource_payload.to_json,
        timeout: 30
      )
      
      if response.success?
        Rails.logger.info("[ShopifyInboxCreator] Successfully connected datasource #{datasource_id} to agent #{agent_id}")
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to connect datasource to agent. Status: #{response.code}, Body: #{response.body}")
      end
      
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error connecting datasource to agent: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
    end
  end

  def get_agent_id_for_account(account_id)
    Rails.logger.info("[ShopifyInboxCreator] Getting agent ID for account: #{account_id}")
    
    begin
      endpoint = Rails.application.config.agent_manager_service_endpoint
      response = HTTParty.get(
        "#{endpoint}/agents",
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'X-CHATWOOT-ACCOUNT-ID' => account_id.to_s
        },
        timeout: 30
      )

      if response.success?
        agents_data = response.parsed_response
        if agents_data && agents_data['data'] && agents_data['data'].any?
          # Get the first agent (assuming there's only one for now)
          agent_id = agents_data['data'].first['id']
          Rails.logger.info("[ShopifyInboxCreator] Successfully retrieved agent ID: #{agent_id} for account: #{account_id}")
          return agent_id
        else
          Rails.logger.error("[ShopifyInboxCreator] No agents found for account: #{account_id}")
          return nil
        end
      else
        Rails.logger.error("[ShopifyInboxCreator] Failed to get agents for account: #{account_id}. Status: #{response.code}, Body: #{response.body}")
        return nil
      end
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error getting agent for account: #{account_id}. Error: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def connect_inbox_to_agent_bot(inbox, agent_bot)
    Rails.logger.info("[ShopifyInboxCreator] Connecting inbox #{inbox.id} to agent bot #{agent_bot.id}")
    
    begin
      # Create the association between inbox and agent bot
      agent_bot_inbox = AgentBotInbox.create!(
        inbox: inbox,
        agent_bot: agent_bot
      )
      
      Rails.logger.info("[ShopifyInboxCreator] Successfully connected inbox #{inbox.id} to agent bot #{agent_bot.id}")
      return agent_bot_inbox
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[ShopifyInboxCreator] Failed to connect inbox to agent bot: #{e.record.errors.full_messages}")
      return nil
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error connecting inbox to agent bot: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def connect_inbox_to_agent_bot_from_id(inbox, chatwoot_agent_bot_id)
    Rails.logger.info("[ShopifyInboxCreator] Connecting inbox #{inbox.id} to agent bot with ID: #{chatwoot_agent_bot_id}")
    
    begin
      # Find the AgentBot record by its ID (which should be the chatwoot_agent_bot_id)
      agent_bot = AgentBot.find_by(id: chatwoot_agent_bot_id)
      if agent_bot
        connect_inbox_to_agent_bot(inbox, agent_bot)
      else
        Rails.logger.warn("[ShopifyInboxCreator] Agent bot with ID #{chatwoot_agent_bot_id} not found in Chatwoot.")
      end
    rescue StandardError => e
      Rails.logger.error("[ShopifyInboxCreator] Error connecting inbox to agent bot: #{e.message}")
      Rails.logger.error("[ShopifyInboxCreator] Error backtrace: #{e.backtrace.join("\n")}")
    end
  end

  private
end 