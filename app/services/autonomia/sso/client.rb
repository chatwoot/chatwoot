# frozen_string_literal: true

require 'net/http'
require 'uri'

class Autonomia::Sso::Client
  Token = Struct.new(:access_token, :id_token, :refresh_token, :expires_in, keyword_init: true) do
    def context_token
      id_token.presence || access_token
    end
  end

  def exchange_code!(code:, redirect_uri:, code_verifier:)
    response = post_form(token_endpoint, {
                           grant_type: 'authorization_code',
                           client_id: client_id,
                           code: code,
                           redirect_uri: redirect_uri,
                           code_verifier: code_verifier
                         })
    Token.new(
      access_token: response.fetch('access_token'),
      id_token: response['id_token'],
      refresh_token: response['refresh_token'],
      expires_in: response['expires_in']
    )
  end

  def refresh_token!(refresh_token:)
    response = post_form(token_endpoint, {
                           grant_type: 'refresh_token',
                           client_id: client_id,
                           refresh_token: refresh_token
                         })
    Token.new(
      access_token: response.fetch('access_token'),
      id_token: response['id_token'],
      refresh_token: response['refresh_token'].presence || refresh_token,
      expires_in: response['expires_in']
    )
  end

  def fetch_context!(access_token)
    get_json(context_endpoint, access_token)
  end

  private

  def post_form(url, body)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(body)
    parse_response(uri, request)
  end

  def get_json(url, access_token)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    parse_response(uri, request)
  end

  def parse_response(uri, request)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    payload = JSON.parse(response.body.presence || '{}')
    return payload if response.is_a?(Net::HTTPSuccess)

    raise "Autonomia Identity request failed: #{response.code} #{payload['error_description'] || payload['error'] || response.message}"
  end

  def token_endpoint
    ENV.fetch('AUTONOMIA_AUTH_TOKEN_ENDPOINT', 'https://auth.api-autonomia.com/oauth/token')
  end

  def context_endpoint
    ENV.fetch('AUTONOMIA_AUTH_CONTEXT_ENDPOINT', 'https://auth.api-autonomia.com/me/context')
  end

  def client_id
    ENV.fetch('AUTONOMIA_AUTH_CLIENT_ID', 'talkai')
  end
end
