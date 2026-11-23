# The result of checking the identity proof a request carries.
class ContactIdentity::Proof
  NONE = :none
  VERIFIED = :verified
  INVALID = :invalid

  # identifier and attributes are set only when the proof itself carries them, as a signed token does.
  attr_reader :status, :identifier, :attributes

  def self.none
    new(NONE)
  end

  def self.verified(identifier: nil, attributes: {})
    new(VERIFIED, identifier: identifier, attributes: attributes)
  end

  def self.invalid
    new(INVALID)
  end

  def initialize(status, identifier: nil, attributes: {})
    @status = status
    @identifier = identifier
    @attributes = attributes
  end

  def none?
    status == NONE
  end

  def verified?
    status == VERIFIED
  end
end
