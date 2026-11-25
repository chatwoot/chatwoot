# Per-account switches for the WhatsApp session providers. Both are on offer to an account
# nobody has touched, and each switch takes its provider away from one account.
#
# What decides whether a provider is served **at all** is still its descriptor, not
# these: `native` needs the connector, which an installation turns off with
# WHATSAPP_CONNECTOR_ENABLED=false, and answers `available?` on that. These narrow what the
# descriptor already allows, and neither can offer a provider this deployment does not serve.
#
# `native` was opt-in while it was rolled out to named accounts (`whatsapp_native_enabled`).
# That key stays in the settings of the accounts it was set on and decides nothing now.
#
# They live in the `settings` jsonb (see the "Account-level toggles" section in
# AGENTS.md), keyed by name, so bit positions never drift between CE and Pro.
#
# Include this AFTER the other `store_accessor :settings` calls in Account: the writers
# below reach the store-accessor module through `super`.
module AccountWhatsappProviders
  extend ActiveSupport::Concern

  included do
    store_accessor :settings, :whatsapp_native_disabled, :whatsapp_uazapi_disabled
  end

  # Deliberately not on the super admin form: withdrawing a provider from an account is a
  # console step. No API writes them either: the account endpoint permits only its own list
  # of settings, and the Platform API does not take `settings` at all.
  #
  # The cast stays because a console line can type "1", and the settings JSON schema only
  # accepts booleans.
  def whatsapp_native_disabled=(value)
    super(ActiveModel::Type::Boolean.new.cast(value))
  end

  def whatsapp_uazapi_disabled=(value)
    super(ActiveModel::Type::Boolean.new.cast(value))
  end

  def whatsapp_session_provider_enabled?(provider)
    case provider.to_s
    when 'native' then !whatsapp_native_disabled
    when 'uazapi' then !whatsapp_uazapi_disabled
    else false
    end
  end
end
