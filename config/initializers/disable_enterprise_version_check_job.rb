# frozen_string_literal: true

# This initializer disables the Enterprise::Internal::CheckNewVersionsJob
# Useful for self-hosted or development environments where version checking is unnecessary.
#
module SkipEnterpriseVersionCheckJob
  def perform
    Rails.logger.info('[Enterprise::Internal::CheckNewVersionsJob] Execution skipped (disabled via initializer)')
    # no-op
  end
end

Rails.application.config.after_initialize do
  version_check_job_class = 'Enterprise::Internal::CheckNewVersionsJob'.safe_constantize

  if version_check_job_class
    version_check_job_class.prepend(SkipEnterpriseVersionCheckJob)
    Rails.logger.info('[Enterprise::Internal::CheckNewVersionsJob] Disabled successfully (patch applied)')
  else
    Rails.logger.warn('[Enterprise::Internal::CheckNewVersionsJob] Class not found — patch skipped')
  end
End
