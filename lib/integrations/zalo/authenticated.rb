class Integrations::Zalo::Authenticated
  def initialize(access_token)
    @access_token = access_token.presence || raise('Access token is required')
  end

  private

  attr_reader :access_token

  def client
    Integrations::Zalo::Client.new.headers({ 'access_token' => access_token })
  end
end
