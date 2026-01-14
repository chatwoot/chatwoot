# frozen_string_literal: true

# CommMate: Override Enterprise plan reconciliation
# Skip plan reconciliation when Chatwoot Hub connections are disabled
# This prevents "Unauthorized premium changes" warnings in self-hosted instances

if defined?(Enterprise::Internal::CheckNewVersionsJob)
  module CommMateEnterpriseOverrides
    module CheckNewVersionsJobOverride
      def reconcile_premium_config_and_features
        # Skip reconciliation when Chatwoot connections are disabled
        return if ENV['DISABLE_CHATWOOT_CONNECTIONS'] == 'true'

        super
      end
    end
  end

  Enterprise::Internal::CheckNewVersionsJob.prepend(CommMateEnterpriseOverrides::CheckNewVersionsJobOverride)
  Rails.logger.info 'CommMate: Disabled Enterprise plan reconciliation (DISABLE_CHATWOOT_CONNECTIONS=true)'
end
