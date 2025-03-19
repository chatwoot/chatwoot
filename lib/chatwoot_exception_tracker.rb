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
      if @account.present?
        scope.set_context('account', { id: @account.id, name: @account.name })
        scope.set_tags(account_id: @account.id)
      end

      scope.set_user(id: @user.id, email: @user.email) if @user.is_a?(User)

      # Add additional context if provided
      @additional_context.each do |context_name, context_data|
        scope.set_context(context_name.to_s, context_data)
      end

      Sentry.capture_exception(@exception)
    end
  end
end
