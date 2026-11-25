# An error as it travels on the wire, inside a reply, a command.failed event or a failed
# receipt. Maps 1:1 to the Errors hierarchy.
class Whatsapp::Session::Model::WireError < Data.define(:code, :message, :retryable)
  include Whatsapp::Session::Model::Serializable
  defaults retryable: false

  def to_exception
    Whatsapp::Session::Errors.build(code, message)
  end
end
