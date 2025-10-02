# frozen_string_literal: true

namespace :whatsapp do
  namespace :webhook do
    desc 'Debug WhatsApp webhook configuration'
    task debug: :environment do
      puts "\n" + "=" * 80
      puts "🔍 WHATSAPP WEBHOOK DEBUG TOOL"
      puts "=" * 80 + "\n"

      # 1. Check if WhatsApp channels exist
      puts "📋 Step 1: Checking WhatsApp Channels in Database\n"
      channels = Channel::Whatsapp.all

      if channels.empty?
        puts "❌ No WhatsApp channels found in database!"
        puts "   Create a WhatsApp channel first in Chatwoot dashboard"
        exit 1
      end

      puts "✅ Found #{channels.count} WhatsApp channel(s):\n"

      channels.each_with_index do |channel, index|
        puts "\n#{index + 1}. Channel Details:"
        puts "   Phone Number: #{channel.phone_number}"
        puts "   Provider: #{channel.provider}"
        puts "   Account ID: #{channel.account_id}"
        puts "   Created: #{channel.created_at}"

        # Check provider_config
        config = channel.provider_config || {}
        puts "\n   Provider Config:"
        puts "   - webhook_verify_token: #{config['webhook_verify_token'] || '❌ NOT SET'}"
        puts "   - phone_number_id: #{config['phone_number_id'] || '❌ NOT SET'}"
        puts "   - business_account_id: #{config['business_account_id'] || '❌ NOT SET'}"
        puts "   - api_key: #{config['api_key'] ? '✅ SET (hidden)' : '❌ NOT SET'}"
      end

      # 2. Test webhook verification endpoint
      puts "\n\n📡 Step 2: Testing Webhook Verification Endpoint\n"

      test_channel = channels.first
      phone_number = test_channel.phone_number
      verify_token = test_channel.provider_config['webhook_verify_token']

      if verify_token.blank?
        puts "❌ webhook_verify_token is blank! Cannot test."
        puts "\n💡 Fix: Run this command to generate one:"
        puts "   rails runner \"Channel::Whatsapp.find(#{test_channel.id}).update(provider_config: {webhook_verify_token: SecureRandom.hex(16)})\""
        exit 1
      end

      # 3. Show webhook URLs
      puts "\n📍 Step 3: Webhook URLs\n"
      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      callback_url = "#{frontend_url}/webhooks/whatsapp/#{phone_number}"
      verify_url = "#{callback_url}?hub.mode=subscribe&hub.challenge=test123&hub.verify_token=#{verify_token}"

      puts "Webhook Callback URL (for Meta configuration):"
      puts "   #{callback_url}\n"
      puts "Verify Token (copy to Meta):"
      puts "   #{verify_token}\n"
      puts "\nTest Verification URL (GET request):"
      puts "   #{verify_url}\n"

      # 4. Simulate Meta verification request
      puts "\n🧪 Step 4: Simulating Meta Verification Request\n"

      begin
        # Create a mock request
        params = {
          'hub.mode' => 'subscribe',
          'hub.challenge' => 'test_challenge_123',
          'hub.verify_token' => verify_token,
          phone_number: phone_number
        }

        # Instantiate controller
        controller = Webhooks::WhatsappController.new
        controller.params = ActionController::Parameters.new(params)

        # Check if token is valid
        if controller.send(:valid_token?, verify_token)
          puts "✅ Token validation: PASSED"
          puts "   Expected: #{verify_token}"
          puts "   Got: #{verify_token}"
          puts "   Result: Match! ✓"
        else
          puts "❌ Token validation: FAILED"
          puts "   This means the webhook verification will fail"
        end
      rescue StandardError => e
        puts "❌ Error during simulation: #{e.message}"
        puts "   #{e.backtrace.first}"
      end

      # 5. Check environment variables
      puts "\n\n🔧 Step 5: Environment Configuration\n"
      env_vars = {
        'FRONTEND_URL' => ENV['FRONTEND_URL'],
        'WHATSAPP_PHONE_NUMBER_ID' => ENV['WHATSAPP_PHONE_NUMBER_ID'],
        'WHATSAPP_ACCESS_TOKEN' => ENV['WHATSAPP_ACCESS_TOKEN'] ? '✅ SET (hidden)' : nil,
        'WHATSAPP_WEBHOOK_VERIFY_TOKEN' => ENV['WHATSAPP_WEBHOOK_VERIFY_TOKEN'],
        'WHATSAPP_BUSINESS_ACCOUNT_ID' => ENV['WHATSAPP_BUSINESS_ACCOUNT_ID']
      }

      env_vars.each do |key, value|
        status = value.present? ? '✅' : '❌'
        display_value = value&.include?('SET') ? value : (value || 'NOT SET')
        puts "#{status} #{key}: #{display_value}"
      end

      # 6. Instructions for Meta setup
      puts "\n\n📝 Step 6: Next Steps for Meta WhatsApp Business Setup\n"
      puts "1. Go to: https://developers.facebook.com/apps"
      puts "2. Select your app → WhatsApp → Configuration"
      puts "3. In 'Webhook' section, click 'Edit'"
      puts "4. Enter Callback URL:"
      puts "      #{callback_url}"
      puts "5. Enter Verify Token:"
      puts "      #{verify_token}"
      puts "6. Click 'Verify and Save'"
      puts "\n7. Subscribe to webhook fields:"
      puts "   - messages"
      puts "   - message_status (optional)"
      puts "\n8. Test by sending a message to: #{phone_number}"

      # 7. Quick diagnostic summary
      puts "\n\n" + "=" * 80
      puts "📊 DIAGNOSTIC SUMMARY"
      puts "=" * 80

      issues = []
      issues << "No webhook_verify_token set" if verify_token.blank?
      issues << "FRONTEND_URL not configured" if ENV['FRONTEND_URL'].blank?
      issues << "No phone_number_id in config" if test_channel.provider_config['phone_number_id'].blank?

      if issues.empty?
        puts "✅ All checks passed! Webhook should work correctly."
        puts "\n🎯 If Meta still shows an error:"
        puts "   1. Check Render logs: https://dashboard.render.com/web/[your-service]/logs"
        puts "   2. Ensure the app is deployed and running"
        puts "   3. Verify the callback URL is accessible (try GET request)"
      else
        puts "⚠️  Found #{issues.count} issue(s):"
        issues.each_with_index do |issue, i|
          puts "   #{i + 1}. #{issue}"
        end
      end

      puts "\n" + "=" * 80 + "\n"
    end

    desc 'Test webhook endpoint directly'
    task :test_endpoint, [:phone_number, :verify_token] => :environment do |_t, args|
      phone_number = args[:phone_number] || Channel::Whatsapp.first&.phone_number
      verify_token = args[:verify_token] || Channel::Whatsapp.first&.provider_config&.dig('webhook_verify_token')

      if phone_number.blank? || verify_token.blank?
        puts "❌ Usage: rake whatsapp:webhook:test_endpoint['+573017668760','your_token']"
        exit 1
      end

      puts "\n🧪 Testing Webhook Endpoint\n"
      puts "Phone: #{phone_number}"
      puts "Token: #{verify_token}"
      puts "\nSending GET request...\n"

      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      url = "#{frontend_url}/webhooks/whatsapp/#{URI.encode_www_form_component(phone_number)}"
      url += "?hub.mode=subscribe&hub.challenge=test_123&hub.verify_token=#{URI.encode_www_form_component(verify_token)}"

      puts "URL: #{url}\n\n"

      require 'net/http'
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      puts "Response Code: #{response.code}"
      puts "Response Body: #{response.body}"

      if response.code == '200'
        puts "\n✅ Success! Webhook verification endpoint is working."
      else
        puts "\n❌ Failed! Check the response above for errors."
      end
    end

    desc 'Update webhook verify token for a channel'
    task :update_token, [:phone_number] => :environment do |_t, args|
      phone_number = args[:phone_number]

      if phone_number.blank?
        puts "❌ Usage: rake whatsapp:webhook:update_token['+573017668760']"
        exit 1
      end

      channel = Channel::Whatsapp.find_by(phone_number: phone_number)

      if channel.nil?
        puts "❌ No channel found with phone number: #{phone_number}"
        exit 1
      end

      new_token = SecureRandom.hex(16)
      channel.provider_config['webhook_verify_token'] = new_token
      channel.save!

      puts "✅ Webhook verify token updated successfully!"
      puts "\nNew Token: #{new_token}"
      puts "\nUpdate this token in Meta's webhook configuration:"
      puts "https://developers.facebook.com/apps → Your App → WhatsApp → Configuration → Webhook"
    end

    desc 'Show webhook configuration for all channels'
    task show_config: :environment do
      puts "\n📋 WhatsApp Webhook Configuration\n"
      puts "=" * 80

      Channel::Whatsapp.find_each do |channel|
        puts "\nPhone: #{channel.phone_number}"
        puts "Callback URL: #{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/webhooks/whatsapp/#{channel.phone_number}"
        puts "Verify Token: #{channel.provider_config['webhook_verify_token'] || 'NOT SET'}"
        puts "Provider: #{channel.provider}"
        puts "-" * 80
      end
    end
  end
end
