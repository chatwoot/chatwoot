#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script to understand WhatsApp SocialWise Flow issue
# This script helps identify the exact problem with the flash effect

puts "🔍 Debugging WhatsApp SocialWise Flow Flash Effect"
puts "=" * 60

# Set up Rails environment if available
begin
  require_relative 'config/environment' if File.exist?('config/environment.rb')
  puts "✅ Rails environment loaded"
rescue LoadError => e
  puts "❌ Failed to load Rails environment: #{e.message}"
  exit 1
end

# Test the exact flow that's causing the problem
class WhatsAppFlowDebugger
  def initialize
    @account = Account.first
    @inbox = @account.inboxes.where(channel_type: 'Channel::Whatsapp').first
    
    unless @inbox
      puts "❌ No WhatsApp inbox found"
      exit 1
    end
    
    @conversation = @inbox.conversations.first || create_test_conversation
    puts "✅ Test setup complete"
    puts "   Account: #{@account.name} (ID: #{@account.id})"
    puts "   Inbox: #{@inbox.name} (ID: #{@inbox.id})"
    puts "   Conversation: #{@conversation.id}"
  end

  def debug_flow
    puts "\n🔍 Debugging the exact flow that causes flash effect"
    puts "-" * 50
    
    # Step 1: Create incoming message (simulates user message)
    incoming_message = create_incoming_message("Test interactive message")
    puts "1️⃣  Created incoming message: #{incoming_message.id}"
    
    # Step 2: Create WhatsApp interactive payload (simulates SocialWise Flow response)
    whatsapp_payload = create_test_interactive_payload
    puts "2️⃣  Created test interactive payload"
    
    # Step 3: Process with our new WhatsappResponseProcessor
    puts "3️⃣  Processing with WhatsappResponseProcessor..."
    
    begin
      success = Integrations::SocialwiseFlow::WhatsappResponseProcessor.process(whatsapp_payload, incoming_message)
      
      if success
        puts "   ✅ Processing successful"
        
        # Step 4: Check what messages were created
        outgoing_messages = @conversation.messages.where(message_type: 'outgoing').order(:created_at)
        puts "4️⃣  Checking created messages..."
        
        outgoing_messages.each_with_index do |msg, index|
          puts "   Message #{index + 1}:"
          puts "     ID: #{msg.id}"
          puts "     Content Type: #{msg.content_type}"
          puts "     Content: #{msg.content.truncate(50)}"
          puts "     Content Attributes Keys: #{msg.content_attributes.keys}"
          puts "     Additional Attributes: #{msg.additional_attributes}"
          puts "     Created At: #{msg.created_at}"
          puts "     Updated At: #{msg.updated_at}"
          puts ""
        end
        
        # Step 5: Check if message is properly formatted for WhatsAppInteractive.vue
        latest_message = outgoing_messages.last
        if latest_message
          puts "5️⃣  Checking latest message format for frontend..."
          puts "   Content Type: #{latest_message.content_type}"
          
          if latest_message.content_type == 'integrations'
            puts "   ✅ Message is integrations type (good for WhatsAppInteractive.vue)"
            
            # Check if it has the right structure for WhatsAppInteractive.vue
            interactive_payload = latest_message.content_attributes['interactive'] || 
                                latest_message.content_attributes['whatsapp_interactive_payload']
            
            if interactive_payload
              puts "   ✅ Has interactive payload for frontend"
              puts "   Interactive Type: #{interactive_payload['type']}"
              puts "   Body Text: #{interactive_payload.dig('body', 'text')}"
            else
              puts "   ❌ Missing interactive payload for frontend"
              puts "   Available keys: #{latest_message.content_attributes.keys}"
            end
          else
            puts "   ❌ Message is not integrations type (will not work with WhatsAppInteractive.vue)"
          end
        end
        
      else
        puts "   ❌ Processing failed"
      end
      
    rescue => e
      puts "   ❌ Exception during processing: #{e.class}: #{e.message}"
      puts "   Backtrace: #{e.backtrace.first(3).join('\n   ')}"
    end
  end

  private

  def create_test_conversation
    contact = @account.contacts.create!(
      name: 'Debug Contact',
      phone_number: '+5511999999999'
    )
    
    @inbox.conversations.create!(
      account: @account,
      contact: contact,
      status: 'open'
    )
  end

  def create_incoming_message(content)
    @conversation.messages.create!(
      content: content,
      message_type: 'incoming',
      account: @account,
      inbox: @inbox,
      contact: @conversation.contact
    )
  end

  def create_test_interactive_payload
    {
      'type' => 'interactive',
      'interactive' => {
        'type' => 'button',
        'body' => {
          'text' => 'Escolha uma opção para continuar:'
        },
        'action' => {
          'buttons' => [
            {
              'type' => 'reply',
              'reply' => {
                'id' => 'btn_1',
                'title' => 'Opção 1'
              }
            },
            {
              'type' => 'reply',
              'reply' => {
                'id' => 'btn_2',
                'title' => 'Opção 2'
              }
            }
          ]
        }
      }
    }
  end
end

# Run the debug
begin
  debugger = WhatsAppFlowDebugger.new
  debugger.debug_flow
  
  puts "\n🎯 Debug Summary:"
  puts "   The key is that messages must be created DIRECTLY as 'integrations' type"
  puts "   with the correct content_attributes structure for WhatsAppInteractive.vue"
  puts "   This prevents the flash effect by avoiding content_type changes after creation."
  
rescue => e
  puts "❌ Debug failed: #{e.class}: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(5).join('\n   ')}"
end