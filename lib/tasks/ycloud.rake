# frozen_string_literal: true

namespace :ycloud do
  desc 'Complete YCloud WhatsApp integration setup: validates environment, dependencies, and optionally creates a channel'
  task setup: :environment do
    puts "\n\e[1;36m╔══════════════════════════════════════════════════════════════╗\e[0m"
    puts "\e[1;36m║          YCloud WhatsApp Integration — Setup                 ║\e[0m"
    puts "\e[1;36m╚══════════════════════════════════════════════════════════════╝\e[0m\n"

    errors = []
    warnings = []

    # ─── 1. Core Dependencies ──────────────────────────────────────
    section('1/7 — Core Dependencies')

    check('Ruby loaded') { ok }
    check('Rails loaded') { Rails.version ? ok : fail!('Rails not found') }

    httparty_ok = begin
      require 'httparty'
      true
    rescue LoadError
      false
    end
    check('HTTParty gem') { httparty_ok ? ok : fail!('gem install httparty') }
    errors << 'HTTParty gem not installed. Run: bundle install' unless httparty_ok

    check('Database connection') do
      ActiveRecord::Base.connection.active? ? ok : fail!('Cannot connect to database')
    rescue StandardError => e
      fail!(e.message)
    end

    # ─── 2. Database Schema ────────────────────────────────────────
    section('2/7 — Database Schema')

    whatsapp_table = ActiveRecord::Base.connection.table_exists?('channel_whatsapp')
    check('channel_whatsapp table') { whatsapp_table ? ok : fail!('Table missing. Run: rails db:migrate') }
    errors << 'channel_whatsapp table missing. Run: rails db:migrate' unless whatsapp_table

    if whatsapp_table
      columns = ActiveRecord::Base.connection.columns('channel_whatsapp').map(&:name)
      %w[provider provider_config phone_number].each do |col|
        present = columns.include?(col)
        check("  column: #{col}") { present ? ok : fail!('Column missing') }
        errors << "column #{col} missing in channel_whatsapp" unless present
      end
    end

    provider_valid = Channel::Whatsapp::PROVIDERS.include?('ycloud')
    check('Provider "ycloud" registered') { provider_valid ? ok : fail!('Not in PROVIDERS constant') }
    errors << 'ycloud not in Channel::Whatsapp::PROVIDERS' unless provider_valid

    # ─── 3. Backend Services ───────────────────────────────────────
    section('3/7 — Backend Services')

    services = %w[
      Whatsapp::Ycloud::ApiClient
      Whatsapp::Ycloud::TemplateService
      Whatsapp::Ycloud::FlowService
      Whatsapp::Ycloud::CallService
      Whatsapp::Ycloud::ProfileService
      Whatsapp::Ycloud::ContactService
      Whatsapp::Ycloud::EventService
      Whatsapp::Ycloud::MultiChannelService
      Whatsapp::Ycloud::UnsubscriberService
      Whatsapp::Ycloud::WebhookService
      Whatsapp::Ycloud::AccountService
    ]

    services.each do |svc|
      loaded = begin
        svc.constantize
        true
      rescue NameError
        false
      end
      check(svc.split('::').last) { loaded ? ok : fail!('Class not found') }
      errors << "#{svc} not loadable" unless loaded
    end

    provider_svc = begin
      Whatsapp::Providers::WhatsappYcloudService
      true
    rescue NameError
      false
    end
    check('WhatsappYcloudService (provider)') { provider_svc ? ok : fail!('Class not found') }
    errors << 'WhatsappYcloudService not loadable' unless provider_svc

    incoming_svc = begin
      Whatsapp::IncomingMessageYcloudService
      true
    rescue NameError
      false
    end
    check('IncomingMessageYcloudService') { incoming_svc ? ok : fail!('Class not found') }
    errors << 'IncomingMessageYcloudService not loadable' unless incoming_svc

    # ─── 4. API Controller & Routes ───────────────────────────────
    section('4/7 — API Controller & Routes')

    controller_ok = begin
      Api::V1::Accounts::Channels::Whatsapp::YcloudController
      true
    rescue NameError
      false
    end
    check('YcloudController') { controller_ok ? ok : fail!('Controller not found') }
    errors << 'YcloudController not loadable' unless controller_ok

    route_entries = Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('ycloud') }
    route_count = route_entries.size
    check("YCloud API routes (#{route_count} found)") { route_count >= 30 ? ok : warn!("Expected 30+, got #{route_count}") }
    warnings << "Only #{route_count} YCloud routes found (expected 30+)" if route_count < 30

    webhook_route = Rails.application.routes.routes.any? { |r| r.path.spec.to_s.include?('webhooks/whatsapp') }
    check('Webhook endpoint route') { webhook_route ? ok : fail!('Webhook route missing') }
    errors << 'Webhook route for WhatsApp not found' unless webhook_route

    # ─── 5. Frontend Files ─────────────────────────────────────────
    section('5/7 — Frontend Files')

    frontend_files = {
      'API Client' => 'app/javascript/dashboard/api/ycloud.js',
      'Settings Page' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudSettingsPage.vue',
      'Dashboard' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudDashboard.vue',
      'Templates' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudTemplates.vue',
      'Flows' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudFlows.vue',
      'Profile' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudProfile.vue',
      'Calling' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudCalling.vue',
      'Contacts' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudContacts.vue',
      'MultiChannel' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudMultiChannel.vue',
      'Unsubscribers' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ycloud/YCloudUnsubscribers.vue',
      'i18n (ycloud.json)' => 'app/javascript/dashboard/i18n/locale/en/ycloud.json',
      'Inbox Creation Form' => 'app/javascript/dashboard/routes/dashboard/settings/inbox/channels/YCloudWhatsapp.vue',
    }

    frontend_files.each do |label, path|
      exists = File.exist?(Rails.root.join(path))
      size = exists ? File.size(Rails.root.join(path)) : 0
      check("#{label} (#{exists ? "#{size}B" : 'MISSING'})") { exists && size > 100 ? ok : fail!('File missing or empty') }
      errors << "Frontend file missing: #{path}" unless exists && size > 100
    end

    # ─── 6. Environment & Configuration ────────────────────────────
    section('6/7 — Environment & Configuration')

    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    check("FRONTEND_URL = #{frontend_url || '(not set)'}") do
      frontend_url.present? ? ok : warn!('Needed for webhook registration')
    end
    warnings << 'FRONTEND_URL not set — webhook auto-registration will fail' if frontend_url.blank?

    ycloud_url = ENV.fetch('YCLOUD_BASE_URL', 'https://api.ycloud.com/v2')
    check("YCLOUD_BASE_URL = #{ycloud_url}") { ok }

    sidekiq_running = begin
      Sidekiq::ProcessSet.new.size > 0
    rescue StandardError
      false
    end
    check('Sidekiq processes') { sidekiq_running ? ok : warn!('Not running — async jobs will queue') }
    warnings << 'Sidekiq not running — webhook events will queue until started' unless sidekiq_running

    # ─── 7. Existing YCloud Channels ──────────────────────────────
    section('7/7 — Existing YCloud Channels')

    ycloud_channels = Channel::Whatsapp.where(provider: 'ycloud')
    check("YCloud channels found: #{ycloud_channels.count}") { ok }

    ycloud_channels.each do |ch|
      config = ch.provider_config || {}
      has_key = config['api_key'].present?
      inbox = ch.inbox
      inbox_name = inbox&.name || 'unknown'
      check("  #{inbox_name} (#{ch.phone_number}) — API key: #{has_key ? 'configured' : 'MISSING'}") do
        has_key ? ok : warn!('No API key configured')
      end
      warnings << "Channel #{ch.phone_number} missing api_key in provider_config" unless has_key
    end

    if ycloud_channels.count.zero?
      puts "\n  \e[33mNo YCloud channels exist yet.\e[0m"
      puts "  Create one from: Settings → Inboxes → Add Inbox → WhatsApp → YCloud"
    end

    # ─── Results ───────────────────────────────────────────────────
    puts "\n\e[1;36m══════════════════════════════════════════════════════════════\e[0m"

    if errors.any?
      puts "\n\e[1;31m  ERRORS (#{errors.size}):\e[0m"
      errors.each { |e| puts "    \e[31m✗ #{e}\e[0m" }
    end

    if warnings.any?
      puts "\n\e[1;33m  WARNINGS (#{warnings.size}):\e[0m"
      warnings.each { |w| puts "    \e[33m⚠ #{w}\e[0m" }
    end

    if errors.empty?
      puts "\n  \e[1;32m✓ YCloud integration is fully installed and ready!\e[0m"
      puts "\n  \e[1mQuick Start:\e[0m"
      puts "  1. Go to Settings → Inboxes → Add Inbox → WhatsApp"
      puts "  2. Select \e[1mYCloud\e[0m as provider"
      puts "  3. Enter your YCloud API Key and phone number"
      puts "  4. The webhook will be auto-registered at:"
      puts "     \e[36m#{frontend_url || 'FRONTEND_URL'}/webhooks/whatsapp/<phone_number>\e[0m"
      puts "  5. Access all YCloud features from the \e[1mYCloud tab\e[0m in inbox settings"
      puts ''
    else
      puts "\n  \e[1;31m✗ Setup incomplete. Fix the errors above and run again:\e[0m"
      puts "    \e[1mrake ycloud:setup\e[0m\n"
      exit 1
    end
  end

  desc 'Validate YCloud API key connectivity for all YCloud channels'
  task validate: :environment do
    channels = Channel::Whatsapp.where(provider: 'ycloud')
    if channels.empty?
      puts "\e[33mNo YCloud channels found. Create one first.\e[0m"
      exit 0
    end

    channels.each do |ch|
      config = ch.provider_config || {}
      api_key = config['api_key']
      inbox_name = ch.inbox&.name || 'unknown'

      print "  Testing #{inbox_name} (#{ch.phone_number})... "

      unless api_key.present?
        puts "\e[31mSKIPPED — no API key\e[0m"
        next
      end

      begin
        base = ENV.fetch('YCLOUD_BASE_URL', 'https://api.ycloud.com/v2')
        response = HTTParty.get(
          "#{base}/whatsapp/phoneNumbers",
          headers: { 'X-API-Key' => api_key },
          timeout: 10
        )
        if response.success?
          items = response.parsed_response['items'] || []
          puts "\e[32mOK\e[0m — #{items.size} phone number(s) found"
        else
          puts "\e[31mFAIL\e[0m — HTTP #{response.code}: #{response.message}"
        end
      rescue StandardError => e
        puts "\e[31mERROR\e[0m — #{e.message}"
      end
    end
  end

  desc 'Sync message templates for all YCloud channels'
  task sync_templates: :environment do
    channels = Channel::Whatsapp.where(provider: 'ycloud')
    if channels.empty?
      puts "\e[33mNo YCloud channels found.\e[0m"
      exit 0
    end

    channels.each do |ch|
      inbox_name = ch.inbox&.name || 'unknown'
      print "  Syncing templates for #{inbox_name} (#{ch.phone_number})... "
      begin
        ch.provider_service.sync_templates
        ch.reload
        count = (ch.message_templates || []).size
        puts "\e[32mOK\e[0m — #{count} template(s) synced"
      rescue StandardError => e
        puts "\e[31mERROR\e[0m — #{e.message}"
      end
    end
  end

  # ─── Helper Methods ────────────────────────────────────────────

  def section(title)
    puts "\n  \e[1;34m▸ #{title}\e[0m"
  end

  def check(label)
    result = yield
    status = case result
             when :ok then "\e[32m✓\e[0m"
             when :warn then "\e[33m⚠\e[0m"
             else "\e[31m✗\e[0m"
             end
    puts "    #{status} #{label}"
  end

  def ok
    :ok
  end

  def warn!(msg)
    :warn
  end

  def fail!(msg)
    :fail
  end
end
