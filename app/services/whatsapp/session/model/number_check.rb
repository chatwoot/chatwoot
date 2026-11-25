# The answer to "is this number on WhatsApp?" for a single phone.
#
# `phone` is the number WhatsApp answered with, not the one that was asked about: a
# backend that echoes the query here throws away the only thing the check was for. The
# LID, when the provider serves one, belongs in `address` and nowhere else.
class Whatsapp::Session::Model::NumberCheck < Data.define(:phone, :exists, :address)
  include Whatsapp::Session::Model::Serializable
  coerce address: Whatsapp::Session::Model::Address
  defaults exists: false

  alias exists? exists
end
