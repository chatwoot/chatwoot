# Vapi's server messages for calls Captain answers: tool calls during the call, and the report when it ends
class Vapi::WebhooksController < ActionController::API
  before_action :authenticate!
  before_action :set_session!

  def create
    case message['type']
    when 'tool-calls'
      render json: { results: tool_results }
    when 'end-of-call-report'
      Voice::Captain::CallReportService.new(session: @session, report: message).perform
      head :ok
    else
      head :ok
    end
  end

  private

  def tool_results
    Array(message['toolCallList']).map do |tool_call|
      function = tool_call['function'] || {}
      result = Voice::Captain::ToolRunner.new(session: @session, name: function['name'], arguments: tool_arguments(function)).perform
      { toolCallId: tool_call['id'], result: result }
    end
  end

  # Vapi's examples send arguments as an object; accept a JSON string too, as OpenAI does
  def tool_arguments(function)
    arguments = function['arguments']
    arguments = JSON.parse(arguments) if arguments.is_a?(String)
    arguments.to_h
  end

  def message
    @message ||= params.require(:message).permit!.to_h
  end

  def authenticate!
    head :unauthorized unless Voice::Captain::WebhookAuth.valid?(request.headers[Voice::Captain::WebhookAuth::HEADER])
  end

  def set_session!
    @session = Voice::Captain::CallSession.for_vapi_call(message.dig('call', 'id'))
    head :not_found if @session.nil?
  end
end
