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
    # ALWAYS log to CloudWatch for operational visibility
    account_info = @account ? "[Account:#{@account.id}]" : ''
    user_info = @user ? "[User:#{@user.id}]" : ''
    
    # Handle both string and exception objects like develop branch
    if @exception.is_a?(String)
      Rails.logger.error @exception
    else
      Rails.logger.error "#{account_info}#{user_info} Exception: #{@exception.class}: #{@exception.message}"
    end

    # Also send to Sentry for detailed tracking
    capture_exception_with_sentry if ENV['SENTRY_DSN'].present?
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
