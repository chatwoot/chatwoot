module Weave
  module Core
    module RateLimits
      module_function

      PLAN_LIMITS = {
        'basic' => {
          account_rpm: 300,
          messaging_write_rpm: 120,
          widget_write_rpm: 60,
          whatsapp_inbound_rpm: 60,
          reports_rpm: 60
        },
        'pro' => {
          account_rpm: 600,
          messaging_write_rpm: 240,
          widget_write_rpm: 90,
          whatsapp_inbound_rpm: 120,
          reports_rpm: 120
        },
        'premium' => {
          account_rpm: 1200,
          messaging_write_rpm: 480,
          widget_write_rpm: 120,
          whatsapp_inbound_rpm: 240,
          reports_rpm: 240
        },
        'app' => {
          account_rpm: 300,
          messaging_write_rpm: 60,
          widget_write_rpm: 60,
          whatsapp_inbound_rpm: 30,
          reports_rpm: 30
        },
        'custom' => {
          account_rpm: 1200,
          messaging_write_rpm: 480,
          widget_write_rpm: 120,
          whatsapp_inbound_rpm: 240,
          reports_rpm: 240
        }
      }.freeze

      def category_limit_for_plan(plan_key, category)
        PLAN_LIMITS.fetch(plan_key, PLAN_LIMITS['basic']).fetch(category)
      end

      def plan_for_account_id(account_id)
        Rails.cache.fetch(["wsc:plan", account_id], expires_in: 5.minutes) do
          account = ::Account.find_by(id: account_id)
          Weave::Core::Features.plan_for(account) if account
        end || 'basic'
      end

      def limit_for_account_id(account_id, category)
        # Check for active admin overrides first
        override = Rails.cache.fetch(["wsc:override", account_id, category], expires_in: 1.minute) do
          Weave::Core::RateLimitOverride.active
                                       .find_by(account_id: account_id, category: category)
        end
        
        return override.override_limit if override

        # Fall back to plan-based limits
        plan = plan_for_account_id(account_id)
        category_limit_for_plan(plan, category)
      end

      # Helpers to extract tenant/account context from Rack::Request
      def extract_account_id_from_path(req)
        path = req.path
        if (m = %r{^/api/v1/accounts/(?<id>\d+)}.match(path))
          m[:id].to_i
        elsif (m = %r{^/api/v2/accounts/(?<id>\d+)}.match(path))
          m[:id].to_i
        else
          nil
        end
      end

      def extract_account_id_from_whatsapp(req)
        return nil unless req.path.start_with?("/webhooks/whatsapp/")
        if (m = %r{^/webhooks/whatsapp/(?<phone>[^/]+)}.match(req.path))
          phone = m[:phone]
          channel = ::Channel::Whatsapp.find_by(phone_number: phone)
          channel&.account_id
        end
      end

      def extract_account_id_from_widget(req)
        return nil unless req.path.start_with?("/api/v1/widget/")
        params = ActionDispatch::Request.new(req.env).params
        token = params['website_token']
        return nil if token.blank?
        widget = ::Channel::WebWidget.find_by(website_token: token)
        widget&.account_id
      end

      # Admin management helpers
      def current_limits_for_account(account_id)
        plan = plan_for_account_id(account_id)
        base_limits = PLAN_LIMITS.fetch(plan, PLAN_LIMITS['basic'])
        
        result = {}
        base_limits.each do |category, base_limit|
          override = Weave::Core::RateLimitOverride.active
                                                  .find_by(account_id: account_id, category: category)
          
          result[category] = {
            base_limit: base_limit,
            current_limit: override ? override.override_limit : base_limit,
            override: override,
            plan: plan
          }
        end
        result
      end

      def create_override!(account_id, category, override_limit, expires_at, reason, created_by_user_id, notes: nil)
        Weave::Core::RateLimitOverride.create!(
          account_id: account_id,
          category: category,
          override_limit: override_limit,
          expires_at: expires_at,
          reason: reason,
          created_by_user_id: created_by_user_id,
          notes: notes
        ).tap do
          # Clear cache after creating override
          Rails.cache.delete(["wsc:override", account_id, category])
        end
      end

      def expire_override!(override_id)
        override = Weave::Core::RateLimitOverride.find(override_id)
        override.update!(expires_at: Time.current)
        Rails.cache.delete(["wsc:override", override.account_id, override.category])
        override
      end

      # Burst detection and monitoring
      def current_usage_for_account(account_id, category)
        throttle_key = case category
        when :account_rpm then "acct:#{account_id}"
        when :messaging_write_rpm then "acct:#{account_id}"
        when :whatsapp_inbound_rpm then "acct:#{account_id}:whatsapp"
        when :widget_write_rpm then "acct:#{account_id}:widget"
        when :reports_rpm then "acct:#{account_id}:reports"
        else "acct:#{account_id}"
        end

        cache_key = "rack::attack:#{Time.current.to_i / 60}:#{throttle_key}"
        Rails.cache.read(cache_key) || 0
      end

      def usage_percentage_for_account(account_id, category)
        current = current_usage_for_account(account_id, category)
        limit = limit_for_account_id(account_id, category)
        (current.to_f / limit * 100).round(2)
      end
    end
  end
end

