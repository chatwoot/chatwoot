require 'rails_helper'

RSpec.describe Captain::ToolCatalog::SlackOauthState do
  subject(:oauth_state) { described_class.new(secret: 'slack-client-secret') }

  it 'rejects tampered, expired, and wrong-audience state' do
    claims = {
      sub: 1,
      installation_id: 2,
      nonce: SecureRandom.hex(32),
      iat: 2.minutes.ago.to_i,
      exp: 1.minute.ago.to_i,
      aud: 'slack_oauth'
    }
    expired = JWT.encode(claims, 'slack-client-secret', 'HS256')
    wrong_audience = JWT.encode(claims.merge(exp: 1.minute.from_now.to_i, aud: 'another_oauth'), 'slack-client-secret', 'HS256')
    valid = oauth_state.generate(account_id: 1, installation_id: 2, nonce: claims.fetch(:nonce))

    expect(oauth_state.verify("#{valid}tampered")).to be_nil
    expect(oauth_state.verify(expired)).to be_nil
    expect(oauth_state.verify(wrong_audience)).to be_nil
  end
end
