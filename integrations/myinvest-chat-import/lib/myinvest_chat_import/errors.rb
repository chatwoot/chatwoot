# frozen_string_literal: true

module MyinvestChatImport
  class ImportError < StandardError
    attr_reader :code

    def initialize(code = 'import_error')
      @code = code
      super(code)
    end
  end

  class ValidationError < ImportError
    def initialize(code = 'validation_error')
      super
    end
  end

  class InvalidEncodingError < ValidationError
    def initialize
      super('invalid_utf8')
    end
  end

  class UnsafePathError < ValidationError
    def initialize
      super('unsafe_bundle_path')
    end
  end

  class UnsupportedAttachmentError < ValidationError
    def initialize
      super('attachments_not_supported_v1')
    end
  end

  class KnowledgeSeparationError < ValidationError
    def initialize
      super('knowledge_import_must_be_false')
    end
  end

  class FingerprintConflictError < ImportError
    def initialize
      super('payload_fingerprint_conflict')
    end
  end

  class LedgerIntegrityError < ImportError
    def initialize
      super('ledger_integrity_error')
    end
  end

  class TenantResolutionError < ImportError
    def initialize
      super('tenant_resolution_error')
    end
  end

  class UnsafeInboxError < ImportError
    def initialize
      super('history_inbox_not_bot_free')
    end
  end
end
