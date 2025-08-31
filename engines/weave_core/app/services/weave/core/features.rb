module Weave
  module Core
    module Features
      module_function

      # Canonical feature keys used by WSC
      FEATURE_KEYS = %w[
        ai.captain
        reporting.advanced
        sla
        queues
        departments
        billing.stripe
        billing.paypal
        channel.web_widget
        channel.email
        channel.whatsapp_official
        channel.whatsapp_third_party
        channel.telegram
        channel.facebook
        channel.instagram
        compliance.dsr
        compliance.retention
      ].freeze

      PLAN_DEFAULTS = {
        'basic' => %w[channel.web_widget channel.email compliance.dsr compliance.retention billing.stripe],
        'pro' => %w[channel.web_widget channel.email channel.whatsapp_third_party channel.telegram compliance.dsr compliance.retention billing.stripe],
        'premium' => %w[channel.web_widget channel.email channel.whatsapp_official channel.telegram channel.facebook channel.instagram ai.captain reporting.advanced sla queues departments compliance.dsr compliance.retention billing.stripe billing.paypal],
        'app' => %w[channel.web_widget],
        'custom' => FEATURE_KEYS
      }.freeze

      def effective_for(account)
        plan_key = plan_for(account)
        base = PLAN_DEFAULTS.fetch(plan_key, [])
        overrides = Weave::Core::FeatureToggle.where(account_id: account.id)
        map = base.map { |k| [k, true] }.to_h
        overrides.each do |ft|
          map[ft.feature_key] = ft.enabled
        end
        map
      end

      def plan_for(account)
        Weave::Core::AccountPlan.find_by(account_id: account.id)&.plan_key || 'basic'
      end
    end
  end
end

