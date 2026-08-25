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

  # Pathors holds a different number or a different project than the one the
  # dashboard sent — the page was built from registry data that has since moved.
  class BindingRejected < CustomExceptions::Base
    def message
      I18n.t('errors.pathors.binding_rejected')
    end

    def to_hash
      { error: message }
    end

    def http_status
      :unprocessable_entity
    end
  end

  # A voice inbox is answered by a Pathors agent bot, and the bot is what tells
  # Pathors which project should pick up the call. Without one there is nothing
  # to bind the number to.
  class AgentBotRequired < CustomExceptions::Base
    def message
      I18n.t('errors.pathors.agent_bot_required')
    end

    def to_hash
      { error: message }
    end

    def http_status
      :unprocessable_entity
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
