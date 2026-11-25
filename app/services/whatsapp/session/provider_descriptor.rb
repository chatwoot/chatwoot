# Everything the rest of the system needs to know about a WhatsApp provider without
# instantiating it: which backend serves it, what it can do, how it pairs and which
# fields its setup form asks for. The dashboard renders the form from this, instead of
# carrying one hardcoded component and one literal check per provider.
class Whatsapp::Session::ProviderDescriptor < Data.define(
  :key, :family, :backend, :capabilities, :pairing_modes, :fields, :legacy, :beta
)
  # `session` pairs with a phone (QR / pairing code); `cloud` is the hosted Meta API
  # family (`default` = 360dialog, `whatsapp_cloud`), which this layer does not serve.
  FAMILIES = %w[session cloud].freeze

  # `advanced` puts the field behind the form's advanced options: optional, with a default
  # most inboxes keep. It is said here rather than inferred from the type, so an optional
  # text field can go there without a new rule in the dashboard.
  class Field < Data.define(:name, :type, :required, :default, :secret, :advanced)
    TYPES = %w[string url password boolean].freeze

    # One keyword per attribute of the Data, which is what the parameter count measures.
    def initialize(name:, type: 'string', required: false, default: nil, secret: false, advanced: false) # rubocop:disable Metrics/ParameterLists
      raise ArgumentError, "unknown field type: #{type}" unless TYPES.include?(type.to_s)

      super(name: name.to_s, type: type.to_s, required: required, default: default, secret: secret, advanced: advanced)
    end

    def to_h
      {
        'name' => name, 'type' => type, 'required' => required, 'default' => default, 'secret' => secret,
        'advanced' => advanced
      }
    end
  end

  DEFAULTS = {
    family: 'session', backend: nil, capabilities: [], pairing_modes: [], fields: [], legacy: false, beta: false
  }.freeze

  def initialize(**attributes)
    attributes = DEFAULTS.merge(attributes.compact)
    family = attributes[:family].to_s
    raise ArgumentError, "unknown provider family: #{family}" unless FAMILIES.include?(family)

    super(
      key: attributes[:key].to_s, family: family, backend: attributes[:backend],
      capabilities: Whatsapp::Session::Capabilities.validate!(attributes[:capabilities]),
      pairing_modes: attributes[:pairing_modes].map(&:to_s).freeze,
      fields: attributes[:fields].freeze, legacy: attributes[:legacy], beta: attributes[:beta]
    )
  end

  def session?
    family == 'session'
  end

  # Frozen: still described so an existing inbox can be labelled and gated, never offered
  # as a destination.
  def legacy?
    legacy
  end

  # Offered, but not yet trusted enough to be picked without being told so. The dashboard
  # badges it; nothing gates on it. It is a property of the provider rather than of the
  # account precisely so that ending the beta is one line here instead of a translation
  # hunt across every label that names it.
  def beta?
    beta
  end

  # Served by this layer (as opposed to the legacy session providers, which keep their
  # own services).
  def served?
    backend.present?
  end

  def backend_class
    backend&.safe_constantize
  end

  # A provider can be described (so the UI can label an existing inbox) long before it
  # can be created: `native` needs a connector deployed, and a backend that has not
  # shipped yet cannot serve anything.
  def available?
    return false unless served?
    return false if backend_class.nil?
    return connector_enabled? if key == 'native'

    true
  end

  def supports?(capability)
    capabilities.include?(capability.to_s)
  end

  def to_h
    {
      'key' => key, 'family' => family, 'legacy' => legacy, 'beta' => beta, 'available' => available?,
      'capabilities' => capabilities, 'pairing_modes' => pairing_modes, 'fields' => fields.map(&:to_h)
    }
  end

  private

  def connector_enabled?
    ENV.fetch('WHATSAPP_CONNECTOR_ENABLED', 'true') != 'false'
  end
end
