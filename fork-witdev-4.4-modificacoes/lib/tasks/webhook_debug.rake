namespace :webhook do
  desc 'Debug webhook configuration for a specific account'
  task :debug, [:account_id] => :environment do |_task, args|
    account_id = args[:account_id]
    
    if account_id.blank?
      puts "Usage: rails webhook:debug[ACCOUNT_ID]"
      exit 1
    end

    account = Account.find_by(id: account_id)
    unless account
      puts "Account with ID #{account_id} not found"
      exit 1
    end

    puts "=== WEBHOOK DEBUG FOR ACCOUNT #{account.id} ==="
    puts "Account name: #{account.name}"
    puts

    # Lista webhooks da conta
    webhooks = account.webhooks.account_type
    puts "Webhooks found: #{webhooks.count}"
    
    webhooks.each do |webhook|
      puts "  - Webhook ID: #{webhook.id}"
      puts "    URL: #{webhook.url}"
      puts "    Subscriptions: #{webhook.subscriptions.join(', ')}"
      puts "    Include Access Token: #{webhook.include_access_token}"
      puts
    end

    # Verifica administrador e access token
    administrator = account.users.administrator.first
    if administrator
      puts "Administrator: #{administrator.name} (#{administrator.email})"
      access_token = administrator.access_token
      if access_token
        puts "Access Token: #{access_token.token[0..10]}..."
      else
        puts "Access Token: NOT FOUND"
      end
    else
      puts "Administrator: NOT FOUND"
    end
    puts

    # Simular evento message_created
    puts "=== SIMULATING message_created EVENT ==="
    
    # Busca uma mensagem da conta para testar
    message = account.messages.joins(:conversation)
                     .where(conversations: { account_id: account.id })
                     .where(message_type: ['incoming', 'outgoing'])
                     .first

    if message
      puts "Using message ID: #{message.id}"
      puts "Message content: #{message.content.to_s[0..50]}..."
      puts
      
      # Simula o evento
      payload = message.webhook_data.merge(event: 'message_created')
      
      webhooks.each do |webhook|
        next unless webhook.subscriptions.include?('message_created')
        
        puts "Processing webhook ID #{webhook.id}:"
        
        final_payload = payload.dup
        if webhook.include_access_token && administrator&.access_token&.token
          final_payload[:ACCESS_TOKEN] = administrator.access_token.token
          puts "  ✓ ACCESS_TOKEN added to payload"
        elsif webhook.include_access_token
          puts "  ⚠ ACCESS_TOKEN requested but not available"
        end
        
        puts "  → Webhook URL: #{webhook.url}"
        puts "  → Payload event: #{final_payload[:event]}"
        puts "  → Has ACCESS_TOKEN: #{final_payload.key?(:ACCESS_TOKEN)}"
        puts
      end
    else
      puts "No messages found for testing"
    end
  end

  desc 'Test webhook delivery to a specific URL'
  task :test, [:url] => :environment do |_task, args|
    url = args[:url]
    
    if url.blank?
      puts "Usage: rails webhook:test[URL]"
      exit 1
    end

    puts "=== TESTING WEBHOOK DELIVERY ==="
    puts "Target URL: #{url}"
    puts

    # Cria payload de teste
    test_payload = {
      event: 'test_webhook',
      timestamp: Time.current.to_i,
      test: true,
      message: 'This is a test webhook from Chatwit'
    }

    begin
      puts "Sending test payload..."
      response = RestClient::Request.execute(
        method: :post,
        url: url,
        payload: test_payload.to_json,
        headers: { content_type: :json, accept: :json },
        timeout: 10
      )
      
      puts "✓ SUCCESS!"
      puts "Response status: #{response.code}"
      puts "Response body: #{response.body[0..200]}..."
    rescue => e
      puts "✗ FAILED!"
      puts "Error: #{e.message}"
      puts "Error class: #{e.class}"
    end
  end

  desc 'List all webhooks in the system'
  task :list => :environment do
    puts "=== ALL WEBHOOKS IN SYSTEM ==="
    
    Webhook.includes(:account).each do |webhook|
      puts "Webhook ID: #{webhook.id}"
      puts "  Account: #{webhook.account.name} (ID: #{webhook.account_id})"
      puts "  URL: #{webhook.url}"
      puts "  Subscriptions: #{webhook.subscriptions.join(', ')}"
      puts "  Include Access Token: #{webhook.include_access_token}"
      puts "  Created: #{webhook.created_at.strftime('%Y-%m-%d %H:%M')}"
      puts
    end
  end
end 