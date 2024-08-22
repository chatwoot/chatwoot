###############
# One library to capture_exception and send to the specific service.
# # e as exception, u for user and a for account (user and account are optional)
# Usage: ChatwootExceptionTracker(e, user: u, account: a).capture_exception
############

class ChatwootExceptionTracker
  def initialize(exception, user: nil, account: nil, additional_context: {})
    @exception = exception
    @user = user
    @account = account
    @additional_context = additional_context
  end

  def capture_exception
    capture_exception_with_sentry if ENV['SENTRY_DSN'].present?
    Rails.logger.error @exception
  end

  private

  def capture_exception_with_sentry
    Sentry.with_scope do |scope|
      append_account_context(scope)
      append_additional_context(scope)
      append_user_context(scope)
      Sentry.capture_exception(@exception)
    end
  end

  def append_account_context(scope)
    return if @account.blank?

    scope.set_context('account', { id: @account.id, name: @account.name })
    scope.set_tags(account_id: @account.id)
  end

  def append_additional_context(scope)
    @additional_context.each do |key, value|
      scope.set_context(key.to_s, value)
    end
  end

  def append_user_context(scope)
    return unless @user.is_a?(User)

    scope.set_user(id: @user.id, email: @user.email)
  end
end
