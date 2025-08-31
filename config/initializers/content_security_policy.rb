# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https
  policy.connect_src :self, :https, 'ws:', 'wss:'
  policy.media_src   :self, :https, :data, :blob
  policy.worker_src  :self, :blob
  policy.child_src   :self, :https
  policy.frame_src   :self, :https
  policy.form_action :self, :https

  # Allow @vite/client to hot reload javascript changes in development
  if Rails.env.development?
    policy.script_src *policy.script_src, :unsafe_eval, :unsafe_inline, "http://#{ViteRuby.config.host_with_port}"
    policy.style_src *policy.style_src, :unsafe_inline
    policy.connect_src *policy.connect_src, "ws://#{ViteRuby.config.host_with_port}"
  end

  # You may need to enable this in production as well depending on your setup.
  policy.script_src *policy.script_src, :blob if Rails.env.test?

  # WSC specific CSP adjustments for production
  if Rails.env.production?
    # Tighten up production CSP
    policy.script_src  :self, :https
    policy.style_src   :self, :https
    policy.connect_src :self, :https, 'wss:'
  end
end

# Generate session nonces for permitted importmap and inline scripts
Rails.application.config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = %w[script-src style-src]

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
