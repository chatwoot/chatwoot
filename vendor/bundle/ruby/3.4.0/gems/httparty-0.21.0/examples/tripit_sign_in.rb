dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')

class TripIt
  include HTTParty
  base_uri 'https://www.tripit.com'
  debug_output

  def initialize(email, password)
    @email = email
    get_response = self.class.get('/account/login')
    get_response_cookie = parse_cookie(get_response.headers['Set-Cookie'])

    post_response = self.class.post(
      '/account/login',
      body: {
        login_email_address: email,
        login_password: password
      },
      headers: {'Cookie' => get_response_cookie.to_cookie_string }
    )

    @cookie = parse_cookie(post_response.headers['Set-Cookie'])
  end

  def account_settings
    self.class.get('/account/edit', headers: { 'Cookie' => @cookie.to_cookie_string })
  end

  def logged_in?
    account_settings.include? "You're logged in as #{@email}"
  end

  private

  def parse_cookie(resp)
    cookie_hash = CookieHash.new
    resp.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
    cookie_hash
  end
end

tripit = TripIt.new('email', 'password')
puts "Logged in: #{tripit.logged_in?}"
