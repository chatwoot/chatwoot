# frozen_string_literal: true

module CustomExceptions::OAuth
  class InsufficientScopes < CustomExceptions::Base
    def message
      I18n.t('errors.oauth.insufficient_scopes', scopes: @data[:missing_scopes].join(', '))
    end

    def code
      'SCOPE_ERR'
    end

    def to_hash
      {
        message: message,
        code: code,
        missing_scopes: @data[:missing_scopes]
      }
    end
  end

  class AuthorizationFailed < CustomExceptions::Base
    def message
      I18n.t('errors.oauth.authorization_failed', provider: @data[:provider])
    end

    def code
      'AUTH_ERR'
    end

    def to_hash
      {
        message: message,
        code: code,
        provider: @data[:provider]
      }
    end
  end

  class TokenExchangeFailed < CustomExceptions::Base
    def message
      I18n.t('errors.oauth.token_exchange_failed', provider: @data[:provider])
    end

    def code
      'TOKEN_ERR'
    end

    def to_hash
      {
        message: message,
        code: code,
        provider: @data[:provider]
      }
    end
  end

  class InvalidState < CustomExceptions::Base
    def message
      I18n.t('errors.oauth.invalid_state')
    end

    def code
      'STATE_ERR'
    end

    def to_hash
      {
        message: message,
        code: code
      }
    end
  end
end