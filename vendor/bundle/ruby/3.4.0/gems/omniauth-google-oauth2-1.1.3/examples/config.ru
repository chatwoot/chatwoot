# frozen_string_literal: true

# Sample app for Google OAuth2 Strategy
# Make sure to setup the ENV variables GOOGLE_KEY and GOOGLE_SECRET
# Run with "bundle exec rackup"

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'

# Do not use for production code.
# This is only to make setup easier when running through the sample.
#
# If you do have issues with certs in production code, this could help:
# http://railsapps.github.io/openssl-certificate-verify-failed.html
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Main example app for omniauth-google-oauth2
class App < Sinatra::Base
  configure do
    set :sessions, true
    set :inline_templates, true
  end

  use Rack::Session::Cookie, secret: ENV['RACK_COOKIE_SECRET']

  use OmniAuth::Builder do
    # For additional provider examples please look at 'omni_auth.rb'
    # The key provider_ignores_state is only for AJAX flows. It is not recommended for normal logins.
    provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET'], access_type: 'offline', prompt: 'consent', provider_ignores_state: true, scope: 'email,profile,calendar'
  end

  get '/' do
    <<-HTML
    <!DOCTYPE html>
    <html>
      <head>
        <title>Google OAuth2 Example</title>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
        <script>
          jQuery(function() {
            return $.ajax({
              url: 'https://apis.google.com/js/client:plus.js?onload=gpAsyncInit',
              dataType: 'script',
              cache: true
            });
          });

          window.gpAsyncInit = function() {
            gapi.auth.authorize({
              immediate: true,
              response_type: 'code',
              cookie_policy: 'single_host_origin',
              client_id: '#{ENV['GOOGLE_KEY']}',
              scope: 'email profile'
            }, function(response) {
              return;
            });
            $('.googleplus-login').click(function(e) {
              e.preventDefault();
              gapi.auth.authorize({
                immediate: false,
                response_type: 'code',
                cookie_policy: 'single_host_origin',
                client_id: '#{ENV['GOOGLE_KEY']}',
                scope: 'email profile'
              }, function(response) {
                if (response && !response.error) {
                  // google authentication succeed, now post data to server.
                  jQuery.ajax({type: 'POST', url: "/auth/google_oauth2/callback", data: response,
                    success: function(data) {
                      // Log the data returning from google.
                      console.log(data)
                    }
                  });
                } else {
                  // google authentication failed.
                  console.log("FAILED")
                }
              });
            });
          };
        </script>
      </head>
      <body>
      <ul>
        <li>
          <form method='post' action='/auth/google_oauth2'>
            <input type="hidden" name="authenticity_token" value="#{request.env['rack.session']['csrf']}">
            <button type='submit'>Login with Google</button>
          </form>
        </li>
        <li><a href='#' class="googleplus-login">Sign in with Google via AJAX</a></li>
      </ul>
      </body>
    </html>
    HTML
  end

  post '/auth/:provider/callback' do
    content_type 'text/plain'
    begin
      request.env['omniauth.auth'].to_hash.inspect
    rescue StandardError
      'No Data'
    end
  end

  get '/auth/:provider/callback' do
    content_type 'text/plain'
    begin
      request.env['omniauth.auth'].to_hash.inspect
    rescue StandardError
      'No Data'
    end
  end

  get '/auth/failure' do
    content_type 'text/plain'
    begin
      request.env['omniauth.auth'].to_hash.inspect
    rescue StandardError
      'No Data'
    end
  end
end

run App.new
