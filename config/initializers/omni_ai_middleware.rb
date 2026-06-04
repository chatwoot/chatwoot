# frozen_string_literal: true

# Register Omni-AI Facebook Comment middleware.
# This must run before the facebook-messenger gem processes the /bot endpoint.

require_relative '../../app/middleware/omni_ai/facebook_comment_middleware'

if ENV.fetch('OMNI_AI_COMMENTS_ENABLED', 'false') == 'true'
  Rails.application.config.middleware.insert_before(
    ActionDispatch::Executor,
    OmniAi::FacebookCommentMiddleware
  )
  Rails.logger.info('[OmniAi] Facebook comment middleware registered')
end
