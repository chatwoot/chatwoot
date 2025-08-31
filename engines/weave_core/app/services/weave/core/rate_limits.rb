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
    end
  end
end

