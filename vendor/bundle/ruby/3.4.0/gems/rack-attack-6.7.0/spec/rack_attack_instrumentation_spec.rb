# frozen_string_literal: true

require_relative "spec_helper"
require 'active_support'

# ActiveSupport::Subscribers added in ~> 4.0.2.0
if ActiveSupport::VERSION::MAJOR > 3
  require_relative 'spec_helper'
  require 'active_support/subscriber'
  class CustomSubscriber < ActiveSupport::Subscriber
    @notification_count = 0

    class << self
      attr_accessor :notification_count
    end

    def throttle(_event)
      self.class.notification_count += 1
    end
  end

  describe 'Rack::Attack.instrument' do
    before do
      @period = 60 # Use a long period; failures due to cache key rotation less likely
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      Rack::Attack.throttle('ip/sec', limit: 1, period: @period) { |req| req.ip }
    end

    describe "with throttling" do
      before do
        ActiveSupport::Notifications.stub(:notifier, ActiveSupport::Notifications::Fanout.new) do
          CustomSubscriber.attach_to("rack_attack")
          2.times { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
        end
      end

      it 'should instrument without error' do
        _(last_response.status).must_equal 429
        assert_equal 1, CustomSubscriber.notification_count
      end
    end
  end
end
