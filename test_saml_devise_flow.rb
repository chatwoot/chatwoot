#!/usr/bin/env ruby
# Run with: rails runner test_saml_devise_flow.rb

require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'time'

# Enable OmniAuth debug logging
OmniAuth.config.logger = Rails.logger
OmniAuth.config.logger.level = Logger::DEBUG

puts "=== SAML Authentication Flow Test ==="
puts ""

# 1. Find SAML settings
account_id = 1
saml_settings = AccountSamlSettings.find_by(account_id: account_id, enabled: true)

unless saml_settings
  puts "❌ No SAML settings found for account #{account_id}"
  exit 1
end

puts "✅ Found SAML settings for account #{account_id}"
puts "   SSO URL: #{saml_settings.sso_url}"
puts "   SP Entity ID: #{saml_settings.sp_entity_id_or_default}"
puts ""

# 2. Find a test user
user = User.first
unless user
  puts "❌ No user found to test with"
  exit 1
end

puts "✅ Testing with user: #{user.email}"
puts ""

# 3. Test the initial SAML request endpoint
puts "=== Testing SAML Initiation ==="
saml_init_url = "http://localhost:3000/auth/saml?account_id=#{account_id}"
puts "GET #{saml_init_url}"

uri = URI(saml_init_url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = false
http.set_debug_output($stdout) if ENV['DEBUG']

# Enable cookie handling
http.start do |http_session|
  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'text/html'
  
  response = http_session.request(request)
  puts "Response Status: #{response.code}"
  
  # Store cookies
  cookies = response.get_fields('set-cookie')
  cookie_hash = {}
  if cookies
    cookies.each do |cookie|
      cookie_hash[cookie.split(';')[0].split('=')[0]] = cookie.split(';')[0]
    end
  end
  
  if response.code == '307'
    puts "✅ Got temporary redirect to: #{response['location']}"
    
    # Follow the redirect
    redirect_uri = URI(response['location'])
    redirect_request = Net::HTTP::Get.new(redirect_uri)
    redirect_request['Cookie'] = cookie_hash.values.join('; ') if cookie_hash.any?
    
    redirect_response = http_session.request(redirect_request)
    puts "Redirect Response Status: #{redirect_response.code}"
    
    if redirect_response.code == '302' || redirect_response.code == '303'
      puts "✅ Redirected to IdP: #{redirect_response['location']}"
      
      # Check if it's redirecting to the IdP
      if redirect_response['location']&.include?(saml_settings.sso_url)
        puts "✅ Correctly redirecting to IdP"
      else
        puts "❌ Not redirecting to expected IdP URL"
      end
    end
  elsif response.code == '302' || response.code == '303'
    puts "✅ Redirected to: #{response['location']}"
    
    # Check if it's redirecting to the IdP
    if response['location']&.include?(saml_settings.sso_url)
      puts "✅ Correctly redirecting to IdP"
    else
      puts "❌ Not redirecting to expected IdP URL"
    end
  else
    puts "❌ Expected redirect but got #{response.code}"
    puts "Response body: #{response.body[0..500]}"
  end
end

puts ""

# 4. Simulate SAML callback
puts "=== Simulating SAML Callback ==="

# Generate a mock SAML response
def generate_saml_response(saml_settings, user)
  issue_instant = Time.now.utc.iso8601
  response_id = "_#{SecureRandom.hex(21)}"
  assertion_id = "_#{SecureRandom.hex(21)}"
  
  # Create a simple unsigned SAML response for testing
  saml_response = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" 
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
                ID="#{response_id}" 
                Version="2.0" 
                IssueInstant="#{issue_instant}" 
                Destination="http://localhost:3000/omniauth/saml/callback">
  <saml:Issuer>#{saml_settings.sso_url}</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion ID="#{assertion_id}" Version="2.0" IssueInstant="#{issue_instant}">
    <saml:Issuer>#{saml_settings.sso_url}</saml:Issuer>
    <saml:Subject>
      <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">#{user.email}</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData NotOnOrAfter="#{(Time.now.utc + 300).iso8601}" 
                                      Recipient="http://localhost:3000/omniauth/saml/callback"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:AuthnStatement AuthnInstant="#{issue_instant}">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="email">
        <saml:AttributeValue>#{user.email}</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="name">
        <saml:AttributeValue>#{user.name}</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>
XML
  
  Base64.strict_encode64(saml_response)
end

callback_url = "http://localhost:3000/omniauth/saml/callback"
puts "POST #{callback_url}"

saml_response = generate_saml_response(saml_settings, user)

uri = URI(callback_url)
http = Net::HTTP.new(uri.host, uri.port)

# We need to maintain session cookies
cookie_jar = {}

# First, get a session by visiting the auth endpoint
session_uri = URI(saml_init_url)
session_http = Net::HTTP.new(session_uri.host, session_uri.port)
session_request = Net::HTTP::Get.new(session_uri)

session_response = session_http.request(session_request)
if session_response['set-cookie']
  cookie_jar['Cookie'] = session_response['set-cookie'].split(';')[0]
  puts "✅ Got session cookie"
end

# Now send the callback with the session
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/x-www-form-urlencoded'
request['Cookie'] = cookie_jar['Cookie'] if cookie_jar['Cookie']

callback_params = {
  'SAMLResponse' => saml_response,
  'RelayState' => ''
}

request.body = URI.encode_www_form(callback_params)

puts "Sending SAML response for user: #{user.email}"
response = http.request(request)

puts "Response Status: #{response.code}"

if response.code == '302' || response.code == '303'
  redirect_location = response['location']
  puts "✅ Redirected to: #{redirect_location}"
  
  # Parse redirect URL to check for SSO token
  if redirect_location
    redirect_uri = URI(redirect_location)
    if redirect_uri.path == '/app/login'
      params = URI.decode_www_form(redirect_uri.query || '')
      params_hash = params.to_h
      
      puts ""
      puts "=== Login Redirect Parameters ==="
      puts "Email: #{params_hash['email']}"
      puts "SSO Token: #{params_hash['sso_auth_token']}"
      
      if params_hash['sso_auth_token']
        puts ""
        puts "✅ Successfully generated SSO auth token!"
        
        # Optional: Test the SSO token login
        puts ""
        puts "=== Testing SSO Token Login ==="
        login_url = "http://localhost:3000/auth/sign_in"
        
        login_params = {
          email: params_hash['email'],
          sso_auth_token: params_hash['sso_auth_token']
        }
        
        uri = URI(login_url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = login_params.to_json
        
        login_response = http.request(request)
        puts "Login Response Status: #{login_response.code}"
        
        if login_response.code == '200'
          puts "✅ SSO token login successful!"
          
          # Check for auth headers
          if login_response['access-token']
            puts ""
            puts "Authentication Headers:"
            puts "  access-token: #{login_response['access-token']}"
            puts "  client: #{login_response['client']}"
            puts "  uid: #{login_response['uid']}"
          end
        else
          puts "❌ SSO token login failed"
          puts "Response: #{login_response.body}"
        end
      elsif params_hash['error']
        puts "❌ Error: #{params_hash['error']}"
      end
    else
      puts "❌ Unexpected redirect path: #{redirect_uri.path}"
    end
  end
else
  puts "❌ Expected redirect but got #{response.code}"
  puts "Response body: #{response.body[0..1000]}"
  
  # Check if it's an error page
  if response.body.include?('error') || response.body.include?('Error')
    puts ""
    puts "Possible error in response. Check Rails logs for details."
  end
end

puts ""
puts "=== Test Complete ==="
puts "Check your Rails server logs for detailed OmniAuth debug information"