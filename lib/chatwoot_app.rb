# frozen_string_literal: true

require 'pathname'

module ChatwootApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  def self.saas?
    @saas ||= root.join('saas').exist?
  end

  # Kept for upstream core code compatibility. The enterprise/ directory was
  # replaced by saas/. This always returns false.
  def self.enterprise?
    false
  end

  def self.chatwoot_cloud?
    false
  end

  def self.self_hosted_enterprise?
    false
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.help_center_root
    ENV.fetch('HELPCENTER_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
  end

  def self.extensions
    if custom? && saas?
      %w[saas custom]
    elsif saas?
      %w[saas]
    elsif custom?
      %w[custom]
    else
      %w[]
    end
  end

  def self.advanced_search_allowed?
    ENV.fetch('OPENSEARCH_URL', nil).present?
  end

  def self.otel_enabled?
    otel_provider = InstallationConfig.find_by(name: 'OTEL_PROVIDER')&.value
    secret_key = InstallationConfig.find_by(name: 'LANGFUSE_SECRET_KEY')&.value

    otel_provider.present? && secret_key.present? && otel_provider == 'langfuse'
  end
end
