# frozen_string_literal: true

require 'rails_helper'

# Exercises the real GET /widget throttle blocks in config/initializers/rack_attack.rb
# via Rack::Attack::Throttle#block (public attribute on rack-attack 6.x).
# rubocop:disable RSpec/DescribeClass -- throttles are defined in an initializer, not a constant
RSpec.describe 'GET /widget Rack::Attack throttle keys' do
  def widget_get_env(remote_ip:, path: '/widget')
    Rack::MockRequest.env_for(path, 'REMOTE_ADDR' => remote_ip)
  end

  def call_throttle_block(name, env)
    Rack::Attack.configuration.throttles.fetch(name).block.call(Rack::Attack::Request.new(env))
  end

  let(:token) { 'website-token-abc' }

  describe "throttle 'widget:get' (token + IP when token present)" do
    it 'uses distinct keys for the same website_token and different client IPs' do
      path = "/widget?website_token=#{token}"
      key_a = call_throttle_block('widget:get', widget_get_env(remote_ip: '198.51.100.1', path: path))
      key_b = call_throttle_block('widget:get', widget_get_env(remote_ip: '198.51.100.2', path: path))
      expect(key_a).not_to eq(key_b)
    end

    it 'does not apply (nil discriminator) when website_token is absent' do
      ip = '203.0.113.7'
      expect(call_throttle_block('widget:get', widget_get_env(remote_ip: ip))).to be_nil
    end

    it 'uses distinct keys for the same client IP and different website_tokens' do
      ip = '192.0.2.50'
      key_one = call_throttle_block('widget:get', widget_get_env(remote_ip: ip, path: '/widget?website_token=token-one'))
      key_two = call_throttle_block('widget:get', widget_get_env(remote_ip: ip, path: '/widget?website_token=token-two'))
      expect(key_one).not_to eq(key_two)
    end
  end

  describe "throttle 'widget:get:ip' (per client IP)" do
    it 'uses the client IP so the cap cannot be reset by rotating website_token' do
      ip = '198.51.100.9'
      env_one = widget_get_env(remote_ip: ip, path: '/widget?website_token=token-a')
      env_two = widget_get_env(remote_ip: ip, path: '/widget?website_token=token-b')
      expect(call_throttle_block('widget:get:ip', env_one)).to eq(ip)
      expect(call_throttle_block('widget:get:ip', env_two)).to eq(ip)
    end

    it 'falls back to client IP when website_token is absent' do
      ip = '203.0.113.7'
      expect(call_throttle_block('widget:get:ip', widget_get_env(remote_ip: ip))).to eq(ip)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
