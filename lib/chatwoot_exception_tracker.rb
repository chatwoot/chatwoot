class ChatwootExceptionTracker
  def initialize(exception, user: nil, account: nil)
    @exception = exception
    @user = user
    @account = account
  end

  def capture_exception
    write_exception_to_file if Rails.env.development?
    capture_exception_with_sentry if ENV['SENTRY_DSN'].present?
    Rails.logger.error @exception
  end

  private

  def write_exception_to_file
    error_dir = Rails.root.join('errors')
    FileUtils.mkdir_p(error_dir)
    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
    filename = "#{timestamp}-#{SecureRandom.hex(4)}.log"
    filepath = error_dir.join(filename)

    File.open(filepath, 'w') do |file|
      file.puts "Exception: #{@exception.class} - #{@exception.message}"
      file.puts "User: #{@user&.id} (#{@user&.email})" if @user
      file.puts "Account: #{@account&.id} (#{@account&.name})" if @account
      file.puts "Backtrace:\n#{@exception.backtrace&.join("\n")}"
    end
  end

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
