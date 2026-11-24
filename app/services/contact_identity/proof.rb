# The result of checking the identity proof a request carries.
class ContactIdentity::Proof
  NONE = :none
  VERIFIED = :verified
  INVALID = :invalid

  # identifier is the one a verified proof covers. attributes are the contact details a signed token carries.
  attr_reader :status, :identifier, :attributes

  def self.none
    new(NONE)
  end

  def self.verified(identifier:, attributes: {})
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
