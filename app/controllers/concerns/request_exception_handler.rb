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
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError => e
    log_handled_error(e)
    render_unauthorized('You are not authorized to do this action')
  rescue ActionController::ParameterMissing => e
    log_handled_error(e)
    render_could_not_create_error(e.message)
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
  end

  def render_error(message, status, error = nil)
    log_handled_error(error) if error
    render json: { error: message }, status: status
  end

  def render_unauthorized(message)
    render_error(message, :unauthorized)
  end

  def render_not_found_error(message)
    render_error(message, :not_found)
  end

  def render_could_not_create_error(message)
    render_error(message, :unprocessable_entity)
  end

  def render_payment_required(message)
    render_error(message, :payment_required)
  end

  def render_internal_server_error(message)
    render_error(message, :internal_server_error)
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
    return unless exception

    logger.info("Handled error: #{exception.inspect}")
    report_to_apms(exception)
  end

  def report_to_apms(exception)
    apm_reporters = {
      'NewRelic::Agent' => -> { ::NewRelic::Agent.notice_error(exception) },
      'Datadog::Tracing' => -> { ::Datadog::Tracing.active_trace&.set_error(exception) },
      'ElasticAPM' => -> { ::ElasticAPM.report(exception) },
      'ScoutApm::Error' => -> { ::ScoutApm::Error.capture(exception) },
      'Sentry' => -> { ::Sentry.capture_exception(exception) }
    }

    apm_reporters.each do |module_name, reporter|
      reporter.call if Object.const_defined?(module_name)
    end
  end
end
