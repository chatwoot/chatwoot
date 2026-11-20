class Integrations::Slack::FileDownloadService
  FILE_HOST = 'files.slack.com'.freeze

  pattr_initialize [:url!, :access_token!]

  def perform
    return unless slack_file_url?

    Down::NetHttp.download(url, headers: { 'Authorization' => "Bearer #{access_token}" }, max_redirects: 0)
  rescue Down::TooManyRedirects
    nil
  end

  private

  def slack_file_url?
    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTPS) && uri.host&.downcase == FILE_HOST && uri.port == 443 && uri.userinfo.nil?
  rescue URI::InvalidURIError
    false
  end
end
