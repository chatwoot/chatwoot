# frozen_string_literal: true

require Rails.root.join('lib/trusted_proxy_cidrs')
require 'action_dispatch/middleware/remote_ip'

extra_proxies = TrustedProxyCidrs.build_from_env(ENV.fetch('TRUSTED_PROXY_CIDRS', ''))
existing = Rails.application.config.action_dispatch.trusted_proxies
base_proxies = existing.nil? ? ActionDispatch::RemoteIp::TRUSTED_PROXIES : existing

Rails.application.config.action_dispatch.trusted_proxies = base_proxies + extra_proxies
