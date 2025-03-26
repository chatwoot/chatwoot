module RequestExceptionHandler
  extend ActiveSupport::Concern
  include Database::ConnectionDiagnostics

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from ActiveRecord::ConnectionTimeoutError, with: :handle_connection_timeout
  end

  private

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    log_handled_error(e)
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError => e
    log_handled_error(e)
    render_unauthorized('You are not authorized to do this action')
  rescue ActionController::ParameterMissing => e
    log_handled_error(e)
    render_could_not_create_error(e.message)
  rescue ActiveRecord::ConnectionTimeoutError => e
    handle_connection_timeout(e)
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
  end

  def handle_connection_timeout(exception)
    connection_pool = ActiveRecord::Base.connection_pool
    connection_info = log_connection_pool_stats(connection_pool)

    # Gather diagnostic info
    diagnostics = fetch_connection_diagnostics
    connection_info.merge!(diagnostics)
    connection_info[:caller_info] = caller_info(exception)

    # Log error details
    log_timeout_error(exception, connection_info)

    # Report to exception tracker
    ChatwootExceptionTracker.new(
      exception,
      user: Current.user,
      account: Current.account,
      additional_context: { connection_info: connection_info }
    ).capture_exception

    render_service_unavailable('Database connection timeout. Please try again later.')
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_payment_required(message)
    render json: { error: message }, status: :payment_required
  end

  def render_internal_server_error(message)
    render json: { error: message }, status: :internal_server_error
  end

  def render_service_unavailable(message)
    render json: { error: message }, status: :service_unavailable
  end

  def render_record_invalid(exception)
    log_handled_error(exception)
    render json: {
      message: exception.record.errors.full_messages.join(', '),
      attributes: exception.record.errors.attribute_names
    }, status: :unprocessable_entity
  end

  def render_error_response(exception)
    log_handled_error(exception)
    render json: exception.to_hash, status: exception.http_status
  end

  def log_handled_error(exception)
    logger.info("Handled error: #{exception.inspect}")
  end
end
