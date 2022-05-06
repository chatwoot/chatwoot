###############
# One library to capture_exception and send to the specific service.
# # e as exception, u for user and a for account (user and account are optional)
# Usage: ChatwootExceptionTracker(e, user: u, account: a).capture_exception
############

class ChatwootExceptionTracker
  def initialize(exception, user: nil, account: nil)
    @exception = exception
    @user = user
    @account = account
  end

  def capture_exception
    capture_exception_with_sentry if ENV['SENTRY_DSN'].present?
    # Implement other providers like honeybadger, rollbar etc in future
  end

  private

  def capture_exception_with_sentry
    Sentry.with_scope do |scope|
      if @account.present?
        scope.set_context('account', { id: @account.id, name: @account.name })
        scope.set_tags(account_id: @account.id)
      end

      scope.set_user(id: @user.id, email: @user.email) if @user.is_a?(User)
      Sentry.capture_exception(@exception)
    end
  end
end
