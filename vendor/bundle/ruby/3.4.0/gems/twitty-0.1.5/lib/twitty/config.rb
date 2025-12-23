class Twitty::Config
  attr_accessor :consumer_key,
                :consumer_secret,
                :access_token,
                :access_token_secret,
                :base_url,
                :environment

  def initialize(params = {})
    @base_url = params[:base_url]

    @consumer_key = params[:consumer_key]
    @consumer_secret = params[:consumer_secret]
    @access_token = params[:access_token]
    @access_token_secret = params[:access_token_secret]
  end
end
