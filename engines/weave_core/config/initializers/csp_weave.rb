# Content Security Policy baseline tuned for Vite + Sentry
# Disabled by default; enable by setting WSC_CSP_ENABLED=true

if ActiveModel::Type::Boolean.new.cast(ENV.fetch('WSC_CSP_ENABLED', false))
  Rails.application.config.content_security_policy do |policy|
    # Defaults
    policy.default_src :self
    policy.base_uri :self

    # Assets & scripts
    policy.script_src :self, :https, :blob
    policy.style_src  :self, :https, :unsafe_inline
    policy.img_src    :self, :https, :data, :blob
    policy.font_src   :self, :https, :data
    policy.connect_src :self, :https
    policy.object_src :none

    # Allow Sentry if configured
    if ENV['SENTRY_CSP_CONNECT_SRC'].present?
      policy.connect_src :self, :https, ENV['SENTRY_CSP_CONNECT_SRC']
    end

    # Frame ancestors for embedding dashboards if needed
    policy.frame_ancestors :self
  end

  # Report-only mode by default to avoid breakage; set WSC_CSP_REPORT_ONLY=false to enforce
  report_only = ActiveModel::Type::Boolean.new.cast(ENV.fetch('WSC_CSP_REPORT_ONLY', true))
  Rails.application.config.content_security_policy_report_only = report_only
end

