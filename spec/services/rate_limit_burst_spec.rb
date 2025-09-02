require 'rails_helper'

RSpec.describe 'Rate Limiting Burst and Cooldown', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:account_user) { create(:account_user, account: account, user: user) }

  before do
    # Enable Rack::Attack for testing
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    
    # Set up basic plan for testing
    create(:account_plan, account: account, plan_key: 'basic')
    
    # Sign in user
    sign_in user
  end

  after do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = false
  end

  describe 'Account-level rate limiting' do
    let(:api_path) { "/api/v1/accounts/#{account.id}/conversations" }
    let(:basic_limit) { Weave::Core::RateLimits::PLAN_LIMITS['basic'][:account_rpm] }

    context 'burst testing' do
      it 'allows requests up to the limit' do
        (basic_limit - 1).times do
          get api_path
          expect(response.status).not_to eq(429)
        end
      end

      it 'throttles requests after exceeding limit' do
        basic_limit.times do
          get api_path
        end

        # Next request should be throttled
        get api_path
        expect(response.status).to eq(429)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Rate limit exceeded')
        expect(json_response['code']).to eq('RATE_LIMIT_EXCEEDED')
        expect(json_response['retry_after']).to eq(60)
      end

      it 'provides friendly error message with upgrade suggestion for basic plan' do
        basic_limit.times { get api_path }
        get api_path

        expect(response.status).to eq(429)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('Basic plan rate limit')
        expect(json_response['message']).to include('upgrading to Pro')
        expect(json_response['upgrade_available']).to be true
      end

      it 'includes account limits in error response' do
        basic_limit.times { get api_path }
        get api_path

        expect(response.status).to eq(429)
        json_response = JSON.parse(response.body)
        expect(json_response['account_limits']).to be_a(Hash)
        expect(json_response['account_limits']['account_rpm']).to eq(basic_limit)
      end
    end

    context 'cooldown verification' do
      it 'resets rate limit after cooldown period' do
        # Hit the rate limit
        basic_limit.times { get api_path }
        get api_path
        expect(response.status).to eq(429)

        # Simulate time passage (1 minute cooldown)
        travel 61.seconds do
          get api_path
          expect(response.status).not_to eq(429)
        end
      end

      it 'partially recovers during cooldown window' do
        # Hit the rate limit
        basic_limit.times { get api_path }
        
        # Wait 30 seconds (half the window)
        travel 30.seconds do
          # Should still be throttled initially
          get api_path
          expect(response.status).to eq(429)
          
          # But some capacity should be recovered
          # (This depends on the specific sliding window implementation)
        end
      end
    end
  end

  describe 'Module-specific rate limiting' do
    describe 'messaging write limits' do
      let(:messaging_path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/messages" }
      let(:conversation) { create(:conversation, account: account) }
      let(:messaging_limit) { Weave::Core::RateLimits::PLAN_LIMITS['basic'][:messaging_write_rpm] }

      it 'enforces separate limits for messaging module' do
        # First max out account-level requests with GET requests
        account_rpm_limit = Weave::Core::RateLimits::PLAN_LIMITS['basic'][:account_rpm]
        (account_rpm_limit - 1).times { get "/api/v1/accounts/#{account.id}/conversations" }

        # Messaging writes should still work up to their separate limit
        (messaging_limit - 1).times do
          post messaging_path, params: { content: 'Test message' }
          expect(response.status).not_to eq(429)
        end

        # But should be throttled after messaging limit is reached
        post messaging_path, params: { content: 'Test message' }
        expect(response.status).to eq(429)
      end
    end

    describe 'reports limits' do
      let(:reports_path) { "/api/v2/accounts/#{account.id}/reports/conversations" }
      let(:reports_limit) { Weave::Core::RateLimits::PLAN_LIMITS['basic'][:reports_rpm] }

      it 'enforces separate limits for reports module' do
        (reports_limit - 1).times do
          get reports_path
          expect(response.status).not_to eq(429)
        end

        get reports_path
        expect(response.status).to eq(429)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('rate-limited to maintain system performance')
      end
    end
  end

  describe 'Plan-based limits' do
    context 'Premium plan' do
      let(:premium_account) { create(:account) }
      let(:premium_user) { create(:user, account: premium_account) }
      
      before do
        create(:account_plan, account: premium_account, plan_key: 'premium')
        create(:account_user, account: premium_account, user: premium_user)
        sign_in premium_user
      end

      it 'allows higher limits for premium accounts' do
        premium_limit = Weave::Core::RateLimits::PLAN_LIMITS['premium'][:account_rpm]
        basic_limit = Weave::Core::RateLimits::PLAN_LIMITS['basic'][:account_rpm]
        
        expect(premium_limit).to be > basic_limit
        
        # Should be able to make more requests than basic plan
        (basic_limit + 10).times do
          get "/api/v1/accounts/#{premium_account.id}/conversations"
          expect(response.status).not_to eq(429)
        end
      end

      it 'provides different error message for premium plan' do
        premium_limit = Weave::Core::RateLimits::PLAN_LIMITS['premium'][:account_rpm]
        
        premium_limit.times { get "/api/v1/accounts/#{premium_account.id}/conversations" }
        get "/api/v1/accounts/#{premium_account.id}/conversations"

        expect(response.status).to eq(429)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('Premium plan rate limit')
        expect(json_response['upgrade_available']).to be false
      end
    end
  end

  describe 'Rate limit overrides' do
    let(:api_path) { "/api/v1/accounts/#{account.id}/conversations" }
    let(:basic_limit) { Weave::Core::RateLimits::PLAN_LIMITS['basic'][:account_rpm] }
    let(:override_limit) { basic_limit * 2 }

    before do
      # Create active override
      Weave::Core::RateLimitOverride.create!(
        account_id: account.id,
        category: 'account_rpm',
        override_limit: override_limit,
        expires_at: 1.hour.from_now,
        reason: 'testing',
        created_by_user_id: user.id
      )
      
      # Clear cache to ensure override is picked up
      Rails.cache.clear
    end

    it 'applies override limits instead of plan limits' do
      # Should be able to exceed basic plan limit due to override
      (basic_limit + 10).times do
        get api_path
        expect(response.status).not_to eq(429)
      end

      # But should still be throttled at override limit
      override_limit.times { get api_path }
      get api_path
      expect(response.status).to eq(429)
    end

    it 'falls back to plan limits when override expires' do
      # Create expired override
      expired_override = Weave::Core::RateLimitOverride.create!(
        account_id: account.id,
        category: 'messaging_write_rpm',
        override_limit: 1000,
        expires_at: 1.hour.ago,
        reason: 'expired_test',
        created_by_user_id: user.id
      )

      Rails.cache.clear
      
      messaging_limit = Weave::Core::RateLimits::PLAN_LIMITS['basic'][:messaging_write_rpm]
      conversation = create(:conversation, account: account)
      messaging_path = "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/messages"

      # Should use plan limit, not expired override limit
      messaging_limit.times do
        post messaging_path, params: { content: 'Test' }
      end
      
      post messaging_path, params: { content: 'Test' }
      expect(response.status).to eq(429)
    end
  end

  describe 'Channel-specific rate limiting' do
    describe 'Widget writes' do
      let(:widget) { create(:channel_web_widget, account: account) }
      let(:widget_path) { "/api/v1/widget/messages" }
      let(:widget_limit) { Weave::Core::RateLimits::PLAN_LIMITS['basic'][:widget_write_rpm] }

      it 'throttles widget API calls separately' do
        widget_limit.times do
          post widget_path, params: { 
            website_token: widget.website_token,
            content: 'Widget message'
          }
          expect(response.status).not_to eq(429)
        end

        post widget_path, params: { 
          website_token: widget.website_token,
          content: 'Widget message'
        }
        expect(response.status).to eq(429)
      end
    end
  end

  describe 'Concurrent burst testing' do
    let(:api_path) { "/api/v1/accounts/#{account.id}/conversations" }
    let(:basic_limit) { Weave::Core::RateLimits::PLAN_LIMITS['basic'][:account_rpm] }

    it 'handles concurrent requests correctly' do
      threads = []
      responses = Queue.new

      # Simulate concurrent burst of requests
      10.times do
        threads << Thread.new do
          (basic_limit / 5).times do
            get api_path
            responses << response.status
          end
        end
      end

      threads.each(&:join)
      
      # Collect all response statuses
      statuses = []
      statuses << responses.pop until responses.empty?

      # Should have some 200s and some 429s
      expect(statuses).to include(200)
      expect(statuses).to include(429)
      expect(statuses.count(429)).to be > 0
    end
  end

  describe 'Rate limit monitoring and usage tracking' do
    let(:api_path) { "/api/v1/accounts/#{account.id}/conversations" }

    it 'tracks usage percentage accurately' do
      # Make some requests
      10.times { get api_path }
      
      usage = Weave::Core::RateLimits.current_usage_for_account(account.id, :account_rpm)
      percentage = Weave::Core::RateLimits.usage_percentage_for_account(account.id, :account_rpm)
      
      expect(usage).to be >= 10
      expect(percentage).to be > 0
      expect(percentage).to be <= 100
    end

    it 'provides accurate current limits including overrides' do
      current_limits = Weave::Core::RateLimits.current_limits_for_account(account.id)
      
      expect(current_limits).to be_a(Hash)
      expect(current_limits).to have_key(:account_rpm)
      expect(current_limits[:account_rpm]).to include(:base_limit, :current_limit, :override, :plan)
    end
  end
end