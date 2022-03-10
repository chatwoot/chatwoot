# frozen_string_literal: true

module CustomExceptions::Account
  class InvalidEmail < CustomExceptions::Base
    def message
      if @data[:disposable]
        I18n.t 'errors.signup.disposable_email'
      elsif !@data[:valid]
        I18n.t 'errors.signup.invalid_email'
      end
    end
  end

  class UserExists < CustomExceptions::Base
    def message
      I18n.t('errors.signup.email_already_exists', email: @data[:email])
    end
  end

  class UserErrors < CustomExceptions::Base
    def message
      @data[:errors].full_messages.join(',')
    end
  end

  class SignupFailed < CustomExceptions::Base
    def message
      I18n.t 'errors.signup.failed'
    end
  end

  class PlanUpgradeRequired < CustomExceptions::Base
    def message
      I18n.t 'errors.plan_upgrade_required.failed'
    end
  end
end
