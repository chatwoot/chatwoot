# Bytes fetched from a provider, ready to be attached to a message.
class Whatsapp::Session::Model::MediaPayload < Data.define(:io, :mime, :filename, :size)
  include Whatsapp::Session::Model::Serializable
end
