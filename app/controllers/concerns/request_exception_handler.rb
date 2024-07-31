module RequestExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  end

  private

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    log_handled_error(e)
    render_not_found_error(I18n.t('errors.not_found', resource: e.model.to_s.underscore.humanize))
  rescue ActiveRecord::RecordNotUnique => e
    log_handled_error(e)
    render_unprocessable_entity(I18n.t('errors.unprocessable_entity'))
  rescue Pundit::NotAuthorizedError => e
    log_handled_error(e)
    render_unauthorized(I18n.t('errors.unauthorized'))
  rescue ActionController::ParameterMissing => e
    log_handled_error(e)
    render_could_not_create_error(e.message)
  rescue CustomExceptions::Ticket => e
    log_handled_error(e)
    render_unprocessable_entity(e.message)
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_unprocessable_entity(message)
    render json: { error: message }, status: :unprocessable_entity
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
