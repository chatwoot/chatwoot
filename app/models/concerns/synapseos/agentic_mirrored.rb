# frozen_string_literal: true

# CUSTOMIZAÇÃO_SYNAPSEOS: small concern mixed into AgentBot to keep the
# Chatwoot Mirror reconciliation logic self-contained. Provides idempotent
# soft-disable / soft-enable helpers so the mirror can mark agents removed
# from a client YAML without destroying the bot row (which may still be
# referenced by inboxes / past conversations).
module Synapseos::AgenticMirrored
  extend ActiveSupport::Concern

  DISABLED_PREFIX = '[DISABLED]'

  # Roles supported by the agentic-side ClientConfig YAML. Superset of the
  # original 7-role Esquadrão (alice, iza, luis, otto, fernanda, angela,
  # vitor); the agentic side ships an 8th persona, `natalia`, used by
  # specific verticals (e.g. Royal Enfield). Keeping it on the concern
  # avoids touching the canonical SQUADRON_ROLES constant in agent_bot.rb.
  AGENTIC_ROLES = %w[alice iza luis otto fernanda angela vitor natalia].freeze

  def synapseos_disabled?
    description.to_s.start_with?(DISABLED_PREFIX)
  end

  def mark_synapseos_disabled!
    return if synapseos_disabled?

    new_desc = description.present? ? "#{DISABLED_PREFIX} #{description}" : DISABLED_PREFIX
    update!(description: new_desc)
  end

  def mark_synapseos_enabled!
    return unless synapseos_disabled?

    stripped = description.to_s.sub(/\A#{Regexp.escape(DISABLED_PREFIX)}\s?/, '')
    update!(description: stripped.presence)
  end
end
