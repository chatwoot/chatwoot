# The result of checking the identity proof a request carries.
class ContactIdentity::Proof
  NONE = :none
  VERIFIED = :verified
  INVALID = :invalid

  attr_reader :status

  def self.none
    new(NONE)
  end

  def self.verified
    new(VERIFIED)
  end

  def self.invalid
    new(INVALID)
  end

  def initialize(status)
    @status = status
  end

  def none?
    status == NONE
  end

  def verified?
    status == VERIFIED
  end
end
