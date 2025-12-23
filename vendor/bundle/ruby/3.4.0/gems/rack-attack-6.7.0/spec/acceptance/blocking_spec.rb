# frozen_string_literal: true

require_relative "../spec_helper"

describe "#blocklist" do
  before do
    Rack::Attack.blocklist do |request|
      request.ip == "1.2.3.4"
    end
  end

  it "forbids request if blocklist condition is true" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status
  end

  it "succeeds if blocklist condition is false" do
    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end

  it "notifies when the request is blocked" do
    notification_matched = nil
    notification_type = nil

    ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _id, payload|
      notification_matched = payload[:request].env["rack.attack.matched"]
      notification_type = payload[:request].env["rack.attack.match_type"]
    end

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_nil notification_matched
    assert_nil notification_type

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_nil notification_matched
    assert_equal :blocklist, notification_type
  end
end

describe "#blocklist with name" do
  before do
    Rack::Attack.blocklist("block 1.2.3.4") do |request|
      request.ip == "1.2.3.4"
    end
  end

  it "forbids request if blocklist condition is true" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status
  end

  it "succeeds if blocklist condition is false" do
    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end

  it "notifies when the request is blocked" do
    notification_matched = nil
    notification_type = nil

    ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
      notification_matched = payload[:request].env["rack.attack.matched"]
      notification_type = payload[:request].env["rack.attack.match_type"]
    end

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_nil notification_matched
    assert_nil notification_type

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal "block 1.2.3.4", notification_matched
    assert_equal :blocklist, notification_type
  end
end
