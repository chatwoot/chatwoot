# How to fetch the bytes of a media message. Bytes never travel inside an event: the
# connector publishes a blob it serves over its internal HTTP port, Uazapi publishes
# either a direct URL or a message id that needs a /message/download round trip.
class Whatsapp::Session::Model::MediaRef < Data.define(:kind, :id, :url, :headers, :size, :mime, :sha256, :expires_at)
  include Whatsapp::Session::Model::Serializable

  KINDS = %w[url connector_blob uazapi_message].freeze

  # Two of the three kinds name something only the provider that issued them still holds:
  # a blob on that connector's disk, a message in that Uazapi instance. A `url` carries
  # everything needed to fetch it and travels anywhere.
  PROVIDER_KINDS = { 'connector_blob' => 'native', 'uazapi_message' => 'uazapi' }.freeze

  def self.url(url, mime: nil, size: nil)
    new(kind: 'url', url: url, mime: mime, size: size)
  end

  def initialize(**attributes)
    kind = attributes[:kind].to_s
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown media ref kind: #{kind}" unless KINDS.include?(kind)

    super(**attributes, kind: kind)
  end

  # A URL that has already lapsed is not something to try: the connector serves its blobs
  # for a bounded time and answers 404 afterwards, and the answer to that is to ask it for
  # the bytes again, not to tell the agent the media is gone.
  def fetchable?
    url.present? && !expired?
  end

  def expired?
    expires_at.present? && Time.zone.at(expires_at / 1000.0) <= Time.current
  end

  # Whether `provider` can still answer for this ref. Only anything but true for a ref
  # that outlived a conversion, which is the one path where the ref and the backend asked
  # to resolve it can come from different providers.
  def served_by?(provider)
    kind_owner = PROVIDER_KINDS[kind]
    kind_owner.nil? || kind_owner == provider.to_s
  end
end
