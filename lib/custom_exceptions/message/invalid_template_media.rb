# frozen_string_literal: true

# Raised when WhatsApp template header media references an invalid or expired blob.
# Caught by Conversations::CreateWithInitialMessage to rollback without masking RecordInvalid.
class CustomExceptions::Message::InvalidTemplateMedia < StandardError; end
