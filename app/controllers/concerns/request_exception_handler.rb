module RequestExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  end

  private

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    Sentry.capture_exception(e)
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError
    render_unauthorized('You are not authorized to do this action')
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
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

  def render_record_invalid(exception)
    render json: {
      message: exception.record.errors.full_messages.join(', '),
      attributes: exception.record.errors.attribute_names
    }, status: :unprocessable_entity
  end

  def render_error_response(exception)
    render json: exception.to_hash, status: exception.http_status
  end
end
