# Be sure to restart your server when you modify this file.
#
# Define an application-wide Content Security Policy. Chatwoot ships this in
# Report-Only mode and only when ENABLE_CSP_REPORT_ONLY is truthy, so existing
# installations are unaffected by default. Operators can opt-in to surface
# violation reports for their installation, then iteratively tighten the policy
# before flipping it to enforcement mode.
#
# Refs:
#   * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
#   * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
#   * https://github.com/chatwoot/chatwoot/issues/404

return unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_CSP_REPORT_ONLY', false))

Rails.application.config.content_security_policy do |policy|
  # Deliberately permissive starter policy. The goal of the first rollout is to
  # collect real-world violation reports without breaking pages, so we keep
  # 'unsafe-inline'/'unsafe-eval' for now. They should be removed once nonces
  # or hashes are in place for inline scripts/styles.
  policy.default_src     :self, :https
  policy.font_src        :self, :https, :data
  policy.img_src         :self, :https, :data, :blob
  policy.media_src       :self, :https, :data, :blob
  policy.object_src      :none
  policy.script_src      :self, :https, :unsafe_inline, :unsafe_eval
  policy.style_src       :self, :https, :unsafe_inline
  policy.connect_src     :self, :https, 'wss:'
  policy.frame_src       :self, :https
  policy.frame_ancestors :self
  policy.base_uri        :self
  policy.form_action     :self, :https

  # Vite dev server needs http+ws to its host for HMR.
  if Rails.env.development? && defined?(ViteRuby)
    vite_host = ViteRuby.config.host_with_port
    policy.script_src(*policy.script_src, "http://#{vite_host}")
    policy.connect_src(*policy.connect_src, "http://#{vite_host}", "ws://#{vite_host}")
  end

  report_uri = ENV.fetch('CSP_REPORT_URI', nil)
  policy.report_uri(report_uri) if report_uri.present?
end

# Report-only: log violations but never block. Operators flip this to false
# (and remove unsafe-inline/unsafe-eval) once they have audited their reports.
Rails.application.config.content_security_policy_report_only = true
