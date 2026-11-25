# Provider-neutral layer for the "session" family of WhatsApp channels: providers that
# pair against a phone (QR code or pairing code) and speak the multi-device protocol,
# as opposed to the hosted Cloud API family (`default`, `whatsapp_cloud`).
#
# Two backends ship with it: `native` (our Go connector, over Redis Streams) and
# `uazapi` (HTTP + webhook). `baileys` and `zapi` are the frozen legacy of the same
# family: they keep their own services and are only converted away from.
#
# Everything above the Backend boundary speaks the canonical model in
# Whatsapp::Session::Model. No JID, no provider payload and no provider name leaks
# into handlers, jobs or the outbound path.
module Whatsapp::Session
  # Major of the wire contract in spec/fixtures/whatsapp/session/contract. Additive
  # changes (new event type, new optional field) do not bump it; a drift spec keeps
  # this constant and the vendored PROTOCOL_VERSION in sync.
  PROTOCOL_VERSION = 1

  # Oldest major we still read. Both sides serve a range so a connector and a Rails
  # process can be deployed minutes apart without dropping traffic; this is bumped in
  # lockstep with the connector's own MinVersion, never on its own.
  MIN_PROTOCOL_VERSION = 1

  # A frame from outside the range is a mismatched deployment. It is refused rather than
  # read as if it were this major: the whole point of the version field is that a
  # breaking payload must not reach a handler written for the previous one.
  def self.protocol_compatible?(version)
    version.present? && (MIN_PROTOCOL_VERSION..PROTOCOL_VERSION).cover?(version.to_i)
  end

  # Providers served by this layer. Legacy session providers are NOT here: they are
  # described by the registry (so the UI can label them) but routed to their own services.
  PROVIDERS = %w[native uazapi].freeze
end
