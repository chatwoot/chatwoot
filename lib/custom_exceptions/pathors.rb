# frozen_string_literal: true

module CustomExceptions::Pathors
  # The account has no usable Pathors grant, so there is no registry to read and
  # no project to bind a number into.
  class IntegrationNotConnected < CustomExceptions::Base
    def message
      I18n.t('errors.pathors.integration_not_connected')
    end

    def to_hash
      { error: message }
    end

    def http_status
      :unprocessable_entity
    end
  end

  # Pathors already routes this number to another inbox — the one case an admin
  # can act on themselves, so it gets its own message.
  class PhoneNumberAlreadyBound < CustomExceptions::Base
    def message
      I18n.t('errors.pathors.phone_number_already_bound')
    end

    def to_hash
      { error: message }
    end

    def http_status
      :conflict
    end
  end

  class RequestFailed < CustomExceptions::Base
    def message
      I18n.t('errors.pathors.request_failed')
    end

    def to_hash
      { error: message }
    end

    def http_status
      :bad_gateway
    end
  end
end
