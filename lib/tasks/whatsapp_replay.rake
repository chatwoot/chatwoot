namespace :whatsapp do
  # Replays a captured WhatsApp webhook payload (Baileys or Cloud) through the
  # real ingestion pipeline (Webhooks::WhatsappEventsJob), bypassing the HTTP
  # controller so you don't need the Meta signature (Cloud) or a live request.
  #
  # Usage:
  #   bundle exec rails "whatsapp:replay_webhook[tmp/payload.json]"
  #   bundle exec rails "whatsapp:replay_webhook[tmp/payload.json,+5511999990001]"
  #
  # The phone_number arg is required for Baileys payloads (used to find the
  # channel and inject its webhook_verify_token). Cloud payloads resolve the
  # channel from the embedded metadata, so the arg is optional there.
  desc 'Replay a captured WhatsApp webhook payload (Baileys/Cloud) through the parser'
  task :replay_webhook, %i[path phone_number] => :environment do |_task, args|
    abort 'usage: rake "whatsapp:replay_webhook[path/to/payload.json,+55...]"' if args[:path].blank?

    payload = JSON.parse(File.read(args[:path])).with_indifferent_access
    phone = args[:phone_number].presence || payload[:phone_number]
    payload[:phone_number] = phone if phone.present?

    # Cloud payloads embed the channel in their metadata; Baileys payloads resolve
    # the channel from the phone. Fail fast on a Baileys replay with no phone
    # available instead of silently no-opping inside the events job.
    cloud_payload = payload[:object] == 'whatsapp_business_account'
    abort 'Baileys replays require a phone_number argument or payload[:phone_number]' if !cloud_payload && phone.blank?

    # Only resolve a channel for non-cloud (Baileys) replays: cloud payloads route
    # from embedded metadata, so an optional/stale phone must not pull in a channel
    # here (which could misprint the destination or inject a Baileys token).
    channel = Channel::Whatsapp.find_by(phone_number: phone) if phone.present? && !cloud_payload

    # A non-cloud payload (a phone was given) that resolves to no channel is a
    # dead end — abort instead of no-opping inside the events job. Cloud replays
    # resolve the channel from embedded metadata, so a stale phone must not fail them.
    abort "No WhatsApp channel found for phone #{phone.inspect}" if phone.present? && channel.nil? && !cloud_payload

    # A non-cloud payload must run through the Baileys parser; if the phone maps to
    # a Cloud/Z-API channel the events job would misroute it, so fail fast.
    abort "Baileys replays must target a Baileys channel, got #{channel.provider.inspect}" if !cloud_payload && channel.provider != 'baileys'

    # Baileys verifies webhookVerifyToken inside the service, so inject the
    # channel's token (captured payloads usually omit/filter it).
    if channel&.provider == 'baileys' && payload[:webhookVerifyToken].blank?
      payload[:webhookVerifyToken] = channel.provider_config['webhook_verify_token']
    end

    Rails.logger.info("[whatsapp:replay_webhook] replaying #{args[:path]} (phone=#{phone.inspect})")
    destination = " -> #{channel.name} (#{channel.provider})" if channel
    puts "Replaying #{args[:path]}#{destination}"
    Webhooks::WhatsappEventsJob.perform_now(payload)
    puts 'Done. Check the conversation / last message in the inbox.'
  end
end
