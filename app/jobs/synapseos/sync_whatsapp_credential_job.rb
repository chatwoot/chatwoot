# frozen_string_literal: true

# CUSTOMIZAÇÃO_SYNAPSEOS: After a WhatsApp inbox is created/updated in
# Chatwoot, replicate its credential into the agentic n8n instance via
# `POST /api/clients/:slug/sync-whatsapp-credential` so the operator never
# has to re-cadastrate the same secret in n8n. The agentic side is
# idempotent (PUT-on-second-call) — we always fire on credential change.
class Synapseos::SyncWhatsappCredentialJob < ApplicationJob
  queue_as :default

  class TransientError < StandardError; end

  retry_on TransientError, attempts: 5, wait: :polynomially_longer

  SUPPORTED_PROVIDERS = %w[avisa whatsapp_cloud hyperflow].freeze
  AUDIT_ACTION = 'sync_whatsapp_credential'

  def perform(channel_id)
    channel = Channel::Whatsapp.find_by(id: channel_id)
    return if channel.nil?
    return unless Synapseos::Agentic.config[:enabled]
    return unless SUPPORTED_PROVIDERS.include?(channel.provider)

    slug = channel.account.custom_attributes['synapseos_agentic_slug'] if channel.account
    return if slug.blank?

    payload = build_payload(channel)
    return if payload.nil?

    dispatch(channel, slug, payload)
  end

  private

  def build_payload(channel)
    cfg = channel.provider_config || {}
    case channel.provider
    when 'avisa'
      { provider: 'avisa', token: cfg['api_key'], name: "Avisa #{channel.phone_number}" }
    when 'whatsapp_cloud'
      { provider: 'waba', token: cfg['api_key'], name: "WABA #{channel.phone_number}",
        phone_number_id: cfg['phone_number_id'], business_account_id: cfg['business_account_id'] }
    when 'hyperflow'
      { provider: 'hyperflow', shared_secret: cfg['shared_secret'], name: "Hyperflow #{channel.phone_number}" }
    end
  end

  def dispatch(channel, slug, payload)
    result = Synapseos::Agentic.client.sync_whatsapp_credential(slug, payload)
    return handle_success(channel, slug, result) if result.ok?

    handle_failure(channel, slug, result)
  end

  def handle_success(channel, slug, result)
    credential_id = result.data.is_a?(Hash) ? result.data['credential_id'] : nil
    Rails.logger.info("synapseos.credential_synced channel_id=#{channel.id} slug=#{slug} credential_id=#{credential_id}")
    return if credential_id.blank?

    # with_lock opens a transaction and SELECT FOR UPDATEs the row, reloading
    # the AR object from DB before yielding — so provider_config inside the
    # block is the freshest value, even if a user edited it during the HTTP
    # window. update_columns bypasses callbacks (loop guard) atomically.
    channel.with_lock do
      merged = (channel.provider_config || {}).merge('synapseos_credential_id' => credential_id)
      channel.update_columns(provider_config: merged, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def handle_failure(channel, slug, result)
    if result.kind == :agentic_offline
      Rails.logger.warn("synapseos.credential_sync_offline channel_id=#{channel.id} slug=#{slug} message=#{result.message}")
      raise TransientError, result.message
    end

    Rails.logger.error(
      "synapseos.credential_sync_failed channel_id=#{channel.id} slug=#{slug} kind=#{result.kind} message=#{result.message}"
    )
    write_audit_failure(channel, slug, result)
  end

  def write_audit_failure(channel, slug, result)
    return unless defined?(SynapseosAgenticDeploymentLog)

    SynapseosAgenticDeploymentLog.create!(
      slug: slug,
      account_id: channel.account_id,
      action: AUDIT_ACTION,
      status: 'failure',
      error_message: "#{result.kind}: #{result.message}",
      result_summary: { channel_id: channel.id, details: result.details }
    )
  end
end
