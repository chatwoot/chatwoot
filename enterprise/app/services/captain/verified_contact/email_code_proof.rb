# The customer typed the code emailed to an address, so they are the contact with that email
class Captain::VerifiedContact::EmailCodeProof
  def initialize(conversation)
    @conversation = conversation
  end

  def proven?
    email.present?
  end

  def contact
    @conversation.account.contacts.from_email(email)
  end

  private

  def email
    @email ||= Captain::EmailVerification.new(@conversation).verified_email
  end
end
