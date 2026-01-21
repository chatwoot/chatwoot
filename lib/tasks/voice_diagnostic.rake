# frozen_string_literal: true

namespace :aloo do
  namespace :voice do
    desc 'Diagnose voice reply configuration issues'
    task diagnose: :environment do
      puts "\n" + '=' * 60
      puts '  ALOO VOICE REPLY DIAGNOSTIC'
      puts '=' * 60 + "\n\n"

      # Find all assistants
      assistants = Aloo::Assistant.all
      if assistants.empty?
        puts "❌ No Aloo assistants found in the database.\n"
        exit 1
      end

      puts "Found #{assistants.count} assistant(s)\n\n"

      assistants.each do |assistant|
        diagnose_assistant(assistant)
      end

      puts "\n" + '=' * 60
      puts '  ELEVENLABS API KEY CHECK'
      puts '=' * 60 + "\n\n"
      diagnose_api_key

      puts "\n" + '=' * 60
      puts '  RECENT VOICE JOBS'
      puts '=' * 60 + "\n\n"
      check_recent_jobs

      puts "\n" + '=' * 60
      puts '  RECOMMENDATIONS'
      puts '=' * 60 + "\n\n"
      print_recommendations
    end

    desc 'Test voice synthesis for a specific assistant'
    task :test_synthesis, [:assistant_id] => :environment do |_t, args|
      assistant_id = args[:assistant_id]
      unless assistant_id
        puts '❌ Usage: rake aloo:voice:test_synthesis[ASSISTANT_ID]'
        exit 1
      end

      assistant = Aloo::Assistant.find_by(id: assistant_id)
      unless assistant
        puts "❌ Assistant with ID #{assistant_id} not found"
        exit 1
      end

      puts "\n" + '=' * 60
      puts "  TESTING VOICE SYNTHESIS FOR: #{assistant.name}"
      puts '=' * 60 + "\n\n"

      test_synthesis(assistant)
    end

    desc 'List available ElevenLabs voices'
    task list_voices: :environment do
      puts "\n" + '=' * 60
      puts '  AVAILABLE ELEVENLABS VOICES'
      puts '=' * 60 + "\n\n"

      begin
        client = Aloo::ElevenlabsClient.new
        voices = client.list_voices

        if voices.empty?
          puts '⚠️  No voices found (or API key has no access to voices)'
        else
          puts "Found #{voices.count} voice(s):\n\n"
          voices.each do |voice|
            puts "  Voice ID: #{voice['voice_id']}"
            puts "  Name:     #{voice['name']}"
            puts "  Category: #{voice['category'] || 'N/A'}"
            puts "  Labels:   #{voice['labels']&.values&.join(', ') || 'N/A'}"
            puts '-' * 40
          end
        end
      rescue Aloo::ElevenlabsClient::AuthenticationError => e
        puts "❌ Authentication Error: #{e.message}"
        puts '   Please ensure your ElevenLabs API key is configured correctly.'
      rescue StandardError => e
        puts "❌ Error: #{e.message}"
      end
    end

    desc 'Fix common voice configuration issues for an assistant'
    task :fix_config, [:assistant_id] => :environment do |_t, args|
      assistant_id = args[:assistant_id]
      unless assistant_id
        puts '❌ Usage: rake aloo:voice:fix_config[ASSISTANT_ID]'
        exit 1
      end

      assistant = Aloo::Assistant.find_by(id: assistant_id)
      unless assistant
        puts "❌ Assistant with ID #{assistant_id} not found"
        exit 1
      end

      puts "\n" + '=' * 60
      puts "  FIXING VOICE CONFIG FOR: #{assistant.name}"
      puts '=' * 60 + "\n\n"

      fix_voice_config(assistant)
    end
  end
end

def diagnose_assistant(assistant)
  puts '-' * 60
  puts "Assistant: #{assistant.name} (ID: #{assistant.id})"
  puts '-' * 60

  checks = []

  # Check 1: voice_enabled
  voice_enabled = assistant.voice_enabled?
  checks << {
    name: 'voice_enabled column',
    status: voice_enabled,
    value: voice_enabled.to_s,
    fix: "assistant.update!(voice_enabled: true)"
  }

  # Check 2: elevenlabs_voice_id
  voice_id = assistant.elevenlabs_voice_id
  checks << {
    name: 'elevenlabs_voice_id',
    status: voice_id.present?,
    value: voice_id.presence || '(not set)',
    fix: "assistant.update!(voice_config: assistant.voice_config.merge('elevenlabs_voice_id' => 'YOUR_VOICE_ID'))"
  }

  # Check 3: reply_mode
  reply_mode = assistant.effective_reply_mode
  valid_modes = %w[voice_only text_and_voice]
  checks << {
    name: 'reply_mode',
    status: valid_modes.include?(reply_mode),
    value: reply_mode,
    fix: "assistant.update!(voice_config: assistant.voice_config.merge('reply_mode' => 'text_and_voice'))"
  }

  # Check 4: voice_reply_enabled? (combined check)
  voice_reply_enabled = assistant.voice_reply_enabled?
  checks << {
    name: 'voice_reply_enabled?',
    status: voice_reply_enabled,
    value: voice_reply_enabled.to_s,
    fix: 'Fix the issues above'
  }

  # Print results
  checks.each do |check|
    status_icon = check[:status] ? '✅' : '❌'
    puts "  #{status_icon} #{check[:name]}: #{check[:value]}"
    puts "     └─ Fix: #{check[:fix]}" unless check[:status]
  end

  # Print full voice_config for debugging
  puts "\n  📋 Full voice_config:"
  (assistant.voice_config || {}).each do |key, value|
    puts "     #{key}: #{value.inspect}"
  end
  puts "     (empty)" if assistant.voice_config.blank?

  puts
end

def diagnose_api_key
  sources = {
    'ENV variable' => ENV.fetch('ELEVENLABS_API_KEY', nil),
    'InstallationConfig' => InstallationConfig.find_by(name: 'ELEVENLABS_API_KEY')&.value
  }

  # Check account-level keys
  Aloo::Assistant.find_each do |assistant|
    account_key = assistant.account&.custom_attributes&.dig('elevenlabs_api_key')
    sources["Account #{assistant.account_id} custom_attributes"] = account_key if account_key.present?
  end

  found_any = false
  sources.each do |source, value|
    if value.present?
      masked = value[0..3] + '*' * (value.length - 8) + value[-4..]
      puts "  ✅ #{source}: #{masked}"
      found_any = true
    else
      puts "  ⚠️  #{source}: (not set)"
    end
  end

  unless found_any
    puts "\n  ❌ NO ELEVENLABS API KEY CONFIGURED!"
    puts '     Please set one of the following:'
    puts '     1. ENV["ELEVENLABS_API_KEY"] = "your_key"'
    puts '     2. InstallationConfig.find_or_create_by(name: "ELEVENLABS_API_KEY").update!(value: "your_key")'
    puts '     3. Account custom_attributes["elevenlabs_api_key"]'
  end

  # Test API key validity
  puts "\n  Testing API key..."
  begin
    client = Aloo::ElevenlabsClient.new
    subscription = client.get_subscription
    puts "  ✅ API key is valid!"
    puts "     Character quota: #{subscription['character_count']}/#{subscription['character_limit']}"
    puts "     Tier: #{subscription['tier']}"
  rescue Aloo::ElevenlabsClient::AuthenticationError => e
    puts "  ❌ API key validation failed: #{e.message}"
  rescue StandardError => e
    puts "  ⚠️  Could not validate API key: #{e.message}"
  end
end

def check_recent_jobs
  # Check Sidekiq for recent VoiceReplyJob executions
  puts "  Checking recent voice usage records...\n"

  records = Aloo::VoiceUsageRecord.where(operation_type: 'synthesis').order(created_at: :desc).limit(10)

  if records.empty?
    puts '  ⚠️  No voice synthesis records found.'
    puts '     This means VoiceReplyJob may not be running or voice synthesis has never been attempted.'
  else
    puts "  Found #{records.count} recent synthesis attempts:\n\n"
    records.each do |record|
      status_icon = record.success? ? '✅' : '❌'
      puts "  #{status_icon} #{record.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "     Assistant: #{record.assistant&.name || 'N/A'} (ID: #{record.aloo_assistant_id})"
      puts "     Characters: #{record.characters_used}"
      puts "     Voice ID: #{record.voice_id}"
      puts "     Error: #{record.error_message}" if record.error_message.present?
      puts
    end
  end
end

def print_recommendations
  puts <<~RECS
    If voice replies are not working, check the following in order:

    1. ASSISTANT CONFIGURATION
       - voice_enabled must be TRUE
       - elevenlabs_voice_id must be set to a valid voice ID
       - reply_mode should be 'text_and_voice' or 'voice_only'

    2. API KEY
       - ElevenLabs API key must be configured (ENV, InstallationConfig, or Account)
       - API key must have sufficient character quota

    3. BACKGROUND JOBS
       - Sidekiq must be running
       - Check sidekiq.log for VoiceReplyJob errors

    4. AUDIO CONVERSION
       - FFmpeg must be installed for audio format conversion
       - Run: which ffmpeg

    Quick Fix Commands (in Rails console):
    ─────────────────────────────────────
    # Enable voice for assistant
    assistant = Aloo::Assistant.find(ID)
    assistant.update!(voice_enabled: true)

    # Set voice ID (run rake aloo:voice:list_voices first)
    assistant.update!(voice_config: assistant.voice_config.merge('elevenlabs_voice_id' => 'VOICE_ID'))

    # Set API key
    InstallationConfig.find_or_create_by(name: 'ELEVENLABS_API_KEY').update!(value: 'YOUR_KEY')

    # Test synthesis
    rake aloo:voice:test_synthesis[ASSISTANT_ID]
  RECS
end

def test_synthesis(assistant)
  unless assistant.voice_reply_enabled?
    puts '❌ voice_reply_enabled? returns false'
    puts '   Please fix the configuration issues first (run rake aloo:voice:diagnose)'
    return
  end

  puts '📝 Testing with text: "Hello, this is a voice synthesis test."'
  puts

  begin
    result = Aloo::VoiceSynthesisService.new(
      text: 'Hello, this is a voice synthesis test.',
      assistant: assistant
    ).perform

    if result[:success]
      puts '✅ Voice synthesis succeeded!'
      puts "   Audio file: #{result[:audio_path]}"
      puts "   Format: #{result[:format]}"
      puts "   Content-Type: #{result[:content_type]}"

      if result[:audio_path] && File.exist?(result[:audio_path])
        size = File.size(result[:audio_path])
        puts "   File size: #{(size / 1024.0).round(2)} KB"

        # Clean up test file
        File.delete(result[:audio_path])
        puts '   (test file cleaned up)'
      end
    else
      puts '❌ Voice synthesis failed!'
      puts "   Error: #{result[:error]}"
    end
  rescue StandardError => e
    puts "❌ Exception during synthesis: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end
end

def fix_voice_config(assistant)
  changes = []

  # Fix 1: Enable voice if disabled
  unless assistant.voice_enabled?
    assistant.voice_enabled = true
    changes << 'Enabled voice_enabled'
  end

  # Fix 2: Set default reply_mode if not set
  if assistant.effective_reply_mode == 'text_only'
    assistant.voice_config = (assistant.voice_config || {}).merge('reply_mode' => 'text_and_voice')
    changes << "Set reply_mode to 'text_and_voice'"
  end

  # Check for voice_id
  if assistant.elevenlabs_voice_id.blank?
    puts '⚠️  elevenlabs_voice_id is not set.'
    puts '   Run: rake aloo:voice:list_voices'
    puts '   Then set the voice ID manually:'
    puts "   assistant.update!(voice_config: assistant.voice_config.merge('elevenlabs_voice_id' => 'VOICE_ID'))"
    puts
  end

  if changes.any?
    if assistant.save
      puts '✅ Applied the following fixes:'
      changes.each { |c| puts "   - #{c}" }
    else
      puts "❌ Failed to save: #{assistant.errors.full_messages.join(', ')}"
    end
  else
    puts '✅ No automatic fixes needed.'
  end

  puts "\nCurrent configuration:"
  diagnose_assistant(assistant)
end
