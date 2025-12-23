# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Rack::Attack' do
  it_allows_ok_requests

  describe 'normalizing paths' do
    before do
      Rack::Attack.blocklist("banned_path") { |req| req.path == '/foo' }
    end

    it 'blocks requests with trailing slash' do
      if Rack::Attack::PathNormalizer == Rack::Attack::FallbackPathNormalizer
        skip "Normalization is only present on Rails"
      end

      get '/foo/'
      _(last_response.status).must_equal 403
    end
  end

  describe 'blocklist' do
    before do
      @bad_ip = '1.2.3.4'
      Rack::Attack.blocklist("ip #{@bad_ip}") { |req| req.ip == @bad_ip }
    end

    it 'has a blocklist' do
      _(Rack::Attack.blocklists.key?("ip #{@bad_ip}")).must_equal true
    end

    describe "a bad request" do
      before { get '/', {}, 'REMOTE_ADDR' => @bad_ip }

      it "should return a blocklist response" do
        _(last_response.status).must_equal 403
        _(last_response.body).must_equal "Forbidden\n"
      end

      it "should tag the env" do
        _(last_request.env['rack.attack.matched']).must_equal "ip #{@bad_ip}"
        _(last_request.env['rack.attack.match_type']).must_equal :blocklist
      end

      it_allows_ok_requests
    end

    describe "and safelist" do
      before do
        @good_ua = 'GoodUA'
        Rack::Attack.safelist("good ua") { |req| req.user_agent == @good_ua }
      end

      it('has a safelist') { Rack::Attack.safelists.key?("good ua") }

      describe "with a request match both safelist & blocklist" do
        before { get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua }

        it "should allow safelists before blocklists" do
          _(last_response.status).must_equal 200
        end

        it "should tag the env" do
          _(last_request.env['rack.attack.matched']).must_equal 'good ua'
          _(last_request.env['rack.attack.match_type']).must_equal :safelist
        end
      end
    end

    describe '#blocklisted_responder' do
      it 'should exist' do
        _(Rack::Attack.blocklisted_responder).must_respond_to :call
      end
    end

    describe '#throttled_responder' do
      it 'should exist' do
        _(Rack::Attack.throttled_responder).must_respond_to :call
      end
    end
  end

  describe 'enabled' do
    it 'should be enabled by default' do
      _(Rack::Attack.enabled).must_equal true
    end

    it 'should directly pass request when disabled' do
      bad_ip = '1.2.3.4'
      Rack::Attack.blocklist("ip #{bad_ip}") { |req| req.ip == bad_ip }

      get '/', {}, 'REMOTE_ADDR' => bad_ip
      _(last_response.status).must_equal 403

      prev_enabled = Rack::Attack.enabled
      begin
        Rack::Attack.enabled = false
        get '/', {}, 'REMOTE_ADDR' => bad_ip
        _(last_response.status).must_equal 200
      ensure
        Rack::Attack.enabled = prev_enabled
      end
    end
  end

  describe 'reset!' do
    it 'raises an error when is not supported by cache store' do
      Rack::Attack.cache.store = Class.new
      assert_raises(Rack::Attack::IncompatibleStoreError) do
        Rack::Attack.reset!
      end
    end

    if defined?(Redis)
      it 'should delete rack attack keys' do
        redis = Redis.new
        redis.set('key', 'value')
        redis.set("#{Rack::Attack.cache.prefix}::key", 'value')
        Rack::Attack.cache.store = redis
        Rack::Attack.reset!

        _(redis.get('key')).must_equal 'value'
        _(redis.get("#{Rack::Attack.cache.prefix}::key")).must_be_nil
      end
    end
  end
end
