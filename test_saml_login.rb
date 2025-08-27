#!/usr/bin/env ruby
# Run with: rails runner test_saml_login.rb

require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'base64'
require 'time'

# Find SAML settings for account 1
saml_settings = AccountSamlSettings.find_by(id: 1)

unless saml_settings
  puts "No SAML settings found with ID 1"
  exit 1
end

puts "Found SAML settings for account #{saml_settings.account_id}:"
puts "  SSO URL: #{saml_settings.sso_url}"
puts "  SP Entity ID: #{saml_settings.sp_entity_id_or_default}"
puts "  Certificate Fingerprint: #{saml_settings.certificate_fingerprint}"
puts ""

# Find a user to login as
user = User.first
unless user
  puts "No user found to test with"
  exit 1
end

puts "Testing with user: #{user.email}"
puts ""

# Generate a proper SAML response
def generate_saml_response(saml_settings, user)
  # Create a basic SAML response XML
  issue_instant = Time.now.utc.iso8601
  response_id = "_#{SecureRandom.hex(21)}"
  assertion_id = "_#{SecureRandom.hex(21)}"
  
  saml_response = <<-XML
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" 
                xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
                ID="#{response_id}" 
                Version="2.0" 
                IssueInstant="#{issue_instant}" 
                Destination="http://localhost:3000/saml/#{saml_settings.account_id}/callback">
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
                                      Recipient="http://localhost:3000/saml/#{saml_settings.account_id}/callback"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:AuthnStatement AuthnInstant="#{issue_instant}">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
        <saml:AttributeValue>#{user.email}</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name">
        <saml:AttributeValue>#{user.name}</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>
  XML
  
  Base64.encode64(saml_response)
end

# First, test the SSO endpoint
sso_url = "http://localhost:3000/api/v1/accounts/#{saml_settings.account_id}/saml/sso"
puts "Testing SSO endpoint: #{sso_url}"

uri = URI(sso_url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)
request['Content-Type'] = 'application/json'

response = http.request(request)
puts "SSO Response Status: #{response.code}"
puts "SSO Response Body: #{response.body}"
puts ""

# Now test the callback with a proper SAML response
callback_url = "http://localhost:3000/saml/#{saml_settings.account_id}/callback"
puts "Testing callback endpoint: #{callback_url}"

# Generate SAML response
saml_response = generate_saml_response(saml_settings, user)

# Create a form-encoded body (SAML callbacks are typically POST with form data)
callback_params = {
  'SAMLResponse' => saml_response,
  'RelayState' => '/app/dashboard'
}

uri = URI(callback_url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/x-www-form-urlencoded'
request.body = URI.encode_www_form(callback_params)

puts "Sending POST to callback with SAML response for user: #{user.email}"
response = http.request(request)
puts "Callback Response Status: #{response.code}"
puts "Callback Response Headers:"
response.each_header do |key, value|
  puts "  #{key}: #{value}" if key.downcase.include?('location') || key.downcase.include?('content-type')
end

if response.code == '302'
  puts "\nRedirect location: #{response['location']}"
  
  # Parse the redirect URL to extract SSO token
  if response['location']
    redirect_uri = URI(response['location'])
    params = URI.decode_www_form(redirect_uri.query || '')
    params_hash = params.to_h
    
    puts "\nRedirect parameters:"
    puts "  Email: #{params_hash['email']}"
    puts "  SSO Auth Token: #{params_hash['sso_auth_token']}"
    
    # Test if we can use this SSO token to login
    if params_hash['sso_auth_token']
      puts "\n\nTesting SSO token login:"
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
      
      if login_response.body && !login_response.body.empty?
        begin
          json = JSON.parse(login_response.body)
          puts "Login Response:"
          puts JSON.pretty_generate(json)
          
          # Check for auth headers
          puts "\nAuthentication Headers:"
          puts "  access-token: #{login_response['access-token']}" if login_response['access-token']
          puts "  client: #{login_response['client']}" if login_response['client']
          puts "  uid: #{login_response['uid']}" if login_response['uid']
        rescue
          puts "Login Response Body: #{login_response.body}"
        end
      end
    end
  end
elsif response.body && !response.body.empty?
  puts "\nCallback Response Body:"
  begin
    json = JSON.parse(response.body)
    puts JSON.pretty_generate(json)
  rescue
    puts response.body
  end
end

# Test direct OmniAuth request
puts "\n\nTesting OmniAuth request endpoint:"
omniauth_url = "http://localhost:3000/saml/#{saml_settings.account_id}"
puts "GET #{omniauth_url}"

uri = URI(omniauth_url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)

response = http.request(request)
puts "Response Status: #{response.code}"
if response.code == '302'
  puts "Redirected to: #{response['location']}"
end