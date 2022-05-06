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
      scope.set_context('account',{ id: @account.id, name: @account.name }) if @account.present?
      scope.set_tags(account_id: @account.id) if @account.present?
      scope.set_user(id: @user.id, email: @user.email) if @user.present?
      Sentry.capture_exception(@exception)
    end
  end
end
