# frozen_string_literal: true

require 'pathname'

module ChatwootApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  def self.enterprise?
    # -------------- Reason ---------------
    # Modified to check for 'extended' directory instead of 'enterprise'
    # ------------ Original -----------------------
    # return if ENV.fetch('DISABLE_ENTERPRISE', false)
    #
    # @enterprise ||= root.join('enterprise').exist?
    # ---------------------------------------------
    # ---------------------- Modification Begin ----------------------
    return if ENV.fetch('DISABLE_EXTENDED', false)

    @enterprise ||= root.join('extended').exist?
    # ---------------------- Modification End ------------------------
  end

  def self.chatwoot_cloud?
    enterprise? && GlobalConfig.get_value('DEPLOYMENT_ENV') == 'cloud'
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.help_center_root
    ENV.fetch('HELPCENTER_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
  end

  def self.extensions
    if custom?
      # -------------- Reason ---------------
      # Modified to return 'extended' extension
      # ------------ Original -----------------------
      # %w[enterprise custom]
      # ---------------------------------------------
      # ---------------------- Modification Begin ----------------------
      %w[extended custom]
      # ---------------------- Modification End ------------------------
    elsif enterprise?
      # -------------- Reason ---------------
      # Modified to return 'extended' extension
      # ------------ Original -----------------------
      # %w[enterprise]
      # ---------------------------------------------
      # ---------------------- Modification Begin ----------------------
      %w[extended]
      # ---------------------- Modification End ------------------------
    else
      %w[]
    end
  end

  def self.advanced_search_allowed?
    enterprise? && ENV.fetch('OPENSEARCH_URL', nil).present?
  end

  def self.otel_enabled?
    otel_provider = InstallationConfig.find_by(name: 'OTEL_PROVIDER')&.value
    secret_key = InstallationConfig.find_by(name: 'LANGFUSE_SECRET_KEY')&.value

    otel_provider.present? && secret_key.present? && otel_provider == 'langfuse'
  end
end
