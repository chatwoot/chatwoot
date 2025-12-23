# frozen_string_literal: true

class Minitest::Spec
  def self.it_works_for_cache_backed_features(options)
    fetch_from_store = options.fetch(:fetch_from_store)

    it "works for throttle" do
      Rack::Attack.throttle("by ip", limit: 1, period: 60) do |request|
        request.ip
      end

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 200, last_response.status

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 429, last_response.status
    end

    it "works for fail2ban" do
      Rack::Attack.blocklist("fail2ban pentesters") do |request|
        Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
          request.path.include?("private-place")
        end
      end

      get "/"
      assert_equal 200, last_response.status

      get "/private-place"
      assert_equal 403, last_response.status

      get "/private-place"
      assert_equal 403, last_response.status

      get "/"
      assert_equal 403, last_response.status
    end

    it "works for allow2ban" do
      Rack::Attack.blocklist("allow2ban pentesters") do |request|
        Rack::Attack::Allow2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
          request.path.include?("scarce-resource")
        end
      end

      get "/"
      assert_equal 200, last_response.status

      get "/scarce-resource"
      assert_equal 200, last_response.status

      get "/scarce-resource"
      assert_equal 200, last_response.status

      get "/scarce-resource"
      assert_equal 403, last_response.status

      get "/"
      assert_equal 403, last_response.status
    end

    it "doesn't leak keys" do
      Rack::Attack.throttle("by ip", limit: 1, period: 1) do |request|
        request.ip
      end

      key = nil

      # Freeze time during these statement to be sure that the key used by rack attack is the same
      # we pre-calculate in local variable `key`
      Timecop.freeze do
        key = "rack::attack:#{Time.now.to_i}:by ip:1.2.3.4"

        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      end

      assert fetch_from_store.call(key)

      sleep 2.1

      assert_nil fetch_from_store.call(key)
    end
  end
end
