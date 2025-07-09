#!/usr/bin/env ruby

# Script to get business account path for a specific inbox ID
# Usage: ruby get_business_account_path.rb

# Set the inbox ID to query
INBOX_ID = 1090

# Load Rails environment (assuming this script is run from the Rails app root)
require_relative 'config/environment'

def get_business_account_path(inbox_id)
  # Find the inbox by ID
  inbox = Inbox.find(inbox_id)

  # Check if this is a WhatsApp inbox
  unless inbox.whatsapp?
    puts "Error: Inbox #{inbox_id} is not a WhatsApp inbox. Channel type: #{inbox.channel_type}"
    return nil
  end

  # Get the WhatsApp channel
  whatsapp_channel = inbox.channel

  # Check if it's a WhatsApp Cloud provider
  unless whatsapp_channel.provider == 'whatsapp_cloud'
    puts "Error: Inbox #{inbox_id} is not using WhatsApp Cloud provider. Provider: #{whatsapp_channel.provider}"
    return nil
  end

  # Get the business_account_id and api_key from provider_config
  business_account_id = whatsapp_channel.provider_config['business_account_id']
  api_key = whatsapp_channel.provider_config['api_key']

  if business_account_id.blank?
    puts "Error: No business_account_id found in provider_config for inbox #{inbox_id}"
    return nil
  end

  if api_key.blank?
    puts "Error: No api_key (access token) found in provider_config for inbox #{inbox_id}"
    return nil
  end

  # Construct the business account path (following the pattern from WhatsappCloudService)
  api_base_path = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  business_account_path = "#{api_base_path}/v14.0/#{business_account_id}"

  return {
    inbox_id: inbox_id,
    inbox_name: inbox.name,
    business_account_id: business_account_id,
    business_account_path: business_account_path,
    provider: whatsapp_channel.provider,
    phone_number: whatsapp_channel.phone_number,
    api_key: api_key,
    access_token: api_key  # alias for clarity
  }

rescue ActiveRecord::RecordNotFound
  puts "Error: Inbox with ID #{inbox_id} not found"
  return nil
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
  return nil
end

# Main execution
puts "Getting business account path for inbox ID: #{INBOX_ID}"
puts '=' * 50

result = get_business_account_path(INBOX_ID)

if result
  puts 'Success! Found WhatsApp Business Account details:'
  puts
  puts "Inbox ID: #{result[:inbox_id]}"
  puts "Inbox Name: #{result[:inbox_name]}"
  puts "Phone Number: #{result[:phone_number]}"
  puts "Provider: #{result[:provider]}"
  puts "Business Account ID: #{result[:business_account_id]}"
  puts
  puts 'Business Account Path:'
  puts result[:business_account_path]
  puts
  puts 'Access Token (API Key):'
  puts result[:access_token]
  puts
  puts 'Complete API Endpoint Examples:'
  puts "• Message Templates: #{result[:business_account_path]}/message_templates?access_token=#{result[:access_token]}"
  puts "• Phone Numbers: #{result[:business_account_path]}/phone_numbers?access_token=#{result[:access_token]}"
  puts
  puts 'Authorization Header Format:'
  puts "Authorization: Bearer #{result[:access_token]}"
else
  puts "Failed to get business account path for inbox ID #{INBOX_ID}"
  exit 1
end