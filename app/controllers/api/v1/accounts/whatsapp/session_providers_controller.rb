class Api::V1::Accounts::Whatsapp::SessionProvidersController < Api::V1::Accounts::BaseController
  # Only an administrator can create or convert an inbox, and this catalog exists to
  # drive those two forms.
  before_action :check_admin_authorization?

  # GET /api/v1/accounts/:account_id/whatsapp/session_providers
  #
  # The catalog the setup form renders itself from: which session providers this account
  # may pick, what each one asks for, and what it can do once connected. Legacy providers
  # are described too, so an existing inbox can be labelled and gated without the
  # dashboard carrying a provider name of its own.
  def index
    render json: { payload: session_descriptors.map { |d| d.to_h.merge('creatable' => creatable?(d)).merge(unavailability(d)) } }
  end

  private

  def session_descriptors
    Whatsapp::Session::Registry.descriptors.select(&:session?)
  end

  # Whether this account may stand up a new inbox on this provider. The picker renders
  # itself from this, so the answer has to be the whole rule rather than the part this
  # layer happens to own.
  #
  # Legacy providers are still offered: they are frozen, not withdrawn, and they are what
  # most inboxes run on today. `available?` asks who serves the session, and nobody here
  # serves theirs, so it does not apply to them. Withdrawing them ahead of the removal is
  # then one env var on this line rather than a dashboard change.
  def creatable?(descriptor)
    return Whatsapp::Session::Registry.legacy_creatable? && legacy_installed?(descriptor) if descriptor.legacy?
    return false unless descriptor.available?
    return false unless connector_running?(descriptor)

    Current.account.whatsapp_session_provider_enabled?(descriptor.key)
  end

  # A native inbox that only lacks a running connector is shown disabled rather than left
  # out, with why: the administrator who opens the picker is rarely the one who can start
  # it, and an option that silently vanishes reads as a feature this installation lacks.
  # The detail is the reason the helper published for the last failed start, when there
  # is one.
  def unavailability(descriptor)
    return {} unless descriptor.key == 'native' && descriptor.available? && !connector_running?(descriptor)
    return {} unless Current.account.whatsapp_session_provider_enabled?(descriptor.key)

    { 'unavailable_reason' => 'connector_not_running', 'unavailable_detail' => last_start_error }
  end

  def last_start_error
    Whatsapp::Connector::Status.new.last_start_error
  rescue Whatsapp::Session::Errors::ProviderUnavailable
    nil
  end

  # On by default is not the same as started: the Docker image runs the connector next to
  # Sidekiq, and an installation from source has nothing that does. A native inbox created
  # with nobody to pair it would never connect, so the picker asks the connector registry.
  # Saving an inbox does not: a connector restarting must not stop an inbox being edited.
  def connector_running?(descriptor)
    return true unless descriptor.key == 'native'
    return @connector_running if defined?(@connector_running)

    @connector_running = begin
      Whatsapp::Connector::Client.new(nil).available?
    rescue Whatsapp::Session::Errors::ProviderUnavailable
      false
    end
  end

  # Baileys runs as a separate API that the installation points at. One that never set
  # it up, or whose API is gone, has no use for it, and a legacy provider is not
  # something to introduce. Like the connector check, this gates the picker only: an
  # existing Baileys inbox keeps saving while its API restarts.
  def legacy_installed?(descriptor)
    return true unless descriptor.key == 'baileys'

    Whatsapp::Providers::WhatsappBaileysService.installed?
  end
end
