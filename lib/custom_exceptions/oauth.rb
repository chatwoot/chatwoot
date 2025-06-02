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
end