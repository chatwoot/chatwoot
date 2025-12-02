# frozen_string_literal: true

# CommMate Instance Status Controller Extension
# Monkey patches SuperAdmin::InstanceStatusesController to show CommMate versions

Rails.application.config.to_prepare do
  SuperAdmin::InstanceStatusesController.class_eval do
    # Override to add CommMate version info
    def show
      @metrics = {}
      commmate_version
      chatwoot_base_version
      sha
      postgres_status
      redis_metrics
      chatwoot_edition
      instance_meta
    end

    private

    def commmate_version
      @metrics['CommMate version'] = COMMMATE_VERSION
    end

    def chatwoot_base_version
      @metrics['Base Chatwoot version'] = COMMMATE_BASE_VERSION
    end

    # Override sha method to show CommMate git SHA
    def sha
      @metrics['CommMate Git SHA'] = GIT_HASH
      if defined?(CHATWOOT_GIT_HASH) && CHATWOOT_GIT_HASH != GIT_HASH
        @metrics['Chatwoot Base Git SHA'] = CHATWOOT_GIT_HASH
      end
    end
  end

  Rails.logger.info '✅ CommMate Instance Status controller customized'
end

