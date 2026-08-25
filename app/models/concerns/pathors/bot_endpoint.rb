# A Pathors agent bot's `outgoing_url` is the whole configuration surface of the
# connection: it carries the backend origin and the id of the project that
# answers for the bot. The call relay needs both, the voice wizard needs the
# project id to route a phone number, so the parsing lives on the record instead
# of being re-derived by every caller.
module Pathors::BotEndpoint
  extend ActiveSupport::Concern

  # https://api.pathors.com/project/{projectId}/integration/chatwoot/callback
  CALLBACK_PATH_PATTERN = %r{\A/project/([^/]+)/integration/chatwoot/callback/*\z}

  def pathors_project_id
    pathors_callback_uri&.path&.match(CALLBACK_PATH_PATTERN)&.captures&.first
  end

  # "https://api.pathors.com/project/42/integration/chatwoot/callback"
  #   -> "https://api.pathors.com"
  def pathors_origin
    uri = pathors_callback_uri
    return if uri.nil?

    port = uri.port == uri.default_port ? '' : ":#{uri.port}"
    "#{uri.scheme}://#{uri.host}#{port}"
  end

  private

  def pathors_callback_uri
    return if outgoing_url.blank?

    uri = URI.parse(outgoing_url)
    uri.host.present? ? uri : nil
  rescue URI::InvalidURIError
    nil
  end
end
