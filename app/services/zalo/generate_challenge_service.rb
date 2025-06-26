require 'digest'
require 'base64'

class Zalo::GenerateChallengeService
  VERIFIER_LENGTH = 43

  def perform
    {
      state: state,
      code_challenge: code_challenge,
      app_id: Integrations::Zalo::Constants.app_id
    }
  end

  private

  def state
    @state ||= Random.hex(VERIFIER_LENGTH).first(VERIFIER_LENGTH)
  end

  def code_challenge
    @code_challenge ||= Base64.urlsafe_encode64(Digest::SHA256.digest(state), padding: false)
  end
end
