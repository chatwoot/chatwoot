class Integrations::Slack::FileDownloadService
  FILE_HOST = 'files.slack.com'.freeze

  pattr_initialize [:url!, :access_token!]

  def perform
    return unless slack_file_url?

    SafeFetch.fetch(
      url,
      headers: { 'Authorization' => "Bearer #{access_token}" },
      validate_content_type: false
    ) { |result| retain_download(result) }
  rescue SafeFetch::InvalidUrlError, SafeFetch::UnsafeUrlError,
         SafeFetch::FileTooLargeError, SafeFetch::UnsupportedContentTypeError
    nil
  end

  private

  def slack_file_url?
    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTPS) && uri.host&.downcase == FILE_HOST && uri.port == 443 && uri.userinfo.nil?
  rescue URI::InvalidURIError
    false
  end

  def retain_download(result)
    filename = result.original_filename
    content_type = result.content_type

    result.tempfile.dup.tap do |file|
      file.define_singleton_method(:original_filename) { filename }
      file.define_singleton_method(:content_type) { content_type }
    end
  end
end
