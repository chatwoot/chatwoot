class Integrations::Zalo::OfficialAccount
  def initialize(access_token)
    @access_token = access_token.presence || raise('Access token is required')
  end

  def detail
    Integrations::Zalo::Client.new
                              .headers({ 'access_token' => access_token })
                              .get('v2.0/oa/getoa')
  end

  private

  attr_reader :access_token
end
