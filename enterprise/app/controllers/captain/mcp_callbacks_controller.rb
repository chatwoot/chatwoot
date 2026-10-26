# OAuth sign-in for a Captain MCP server ends here. The state finds the server the sign-in started for.
# RubyLLM then checks the state and the issuer against the pending sign-in before it exchanges the code.
class Captain::McpCallbacksController < ApplicationController
  CALLBACK_PARAMS = %w[code state iss error error_description].freeze

  def show
    server = Captain::Mcp::Connection.server_for_oauth_state(params[:state])
    # The callback can arrive on another host than FRONTEND_URL, such as localhost behind a tunnel
    unless server&.account&.feature_enabled?(Captain::McpServer::FEATURE_FLAG)
      return redirect_to("#{ENV.fetch('FRONTEND_URL', '')}/app", allow_other_host: true)
    end

    redirect_to servers_page_url(server, sign_in_result(server)), allow_other_host: true
  end

  private

  def sign_in_result(server)
    connection = Captain::Mcp::Connection.new(server)
    connection.track_status { connection.authorize(params.to_unsafe_h.slice(*CALLBACK_PARAMS)) }
    'success'
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.warn("Captain MCP sign-in failed for server #{server.id}: #{e.message}")
    'failed'
  end

  def servers_page_url(server, result)
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{server.account_id}/captain/#{server.assistant_id}/tools/mcp" \
      "?mcp_server_id=#{server.id}&sign_in=#{result}"
  end
end
