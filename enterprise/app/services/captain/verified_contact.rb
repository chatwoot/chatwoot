# The contact the customer in a conversation proved they are. Each proof names the contact it vouches for.
# The customer is verified only when every proof they gave names the same contact.
class Captain::VerifiedContact
  # Every way a customer can prove who they are. A proof takes the conversation and answers #proven? and #contact.
  # HMAC identity is not a proof: it signs only the identifier, and the contact it points to can change.
  PROOFS = [Captain::VerifiedContact::EmailCodeProof].freeze

  def initialize(conversation)
    proofs = conversation ? PROOFS.map { |proof| proof.new(conversation) }.select(&:proven?) : []
    @claims = proofs.map(&:contact).uniq
  end

  # :verified, :unverified when the customer gave no proof, :mismatch when proofs name different contacts,
  # or :not_found when the proofs agree but name no contact
  def status
    return :unverified if @claims.empty?
    return :mismatch if @claims.many?

    @claims.first ? :verified : :not_found
  end

  def contact
    @claims.first if status == :verified
  end
end
