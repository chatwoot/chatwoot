class Api::V1::Accounts::AiController < Api::V1::Accounts::BaseController
  def process_event
    # Check if global key feature is enabled
    unless Current.account.feature_enabled?('use_global_openai_key')
      return render json: { error: 'Global OpenAI key feature not enabled' }, status: :forbidden
    end

    # Process the event using global key
    result = Integrations::Openai::GlobalProcessorService.new(
      account: Current.account,
      event: params[:event]
    ).perform

    render json: { message: result }
  rescue StandardError => e
    Rails.logger.error("AI process_event error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
