class Whatsapp::TemplateMetaErrorDetails
  def self.from(response)
    parsed = JSON.parse(response.body)
    error = parsed['error'] || {}
    {
      error: error['error_user_msg'].presence || error['message'].presence || 'Template creation failed',
      meta_error_code: error['code'],
      meta_error_subcode: error['error_subcode'],
      meta_error_title: error['error_user_title'],
      meta_error_message: error['message'],
      meta_error_user_msg: error['error_user_msg'],
      meta_fbtrace_id: error['fbtrace_id']
    }.compact
  rescue JSON::ParserError
    { error: 'Template creation failed' }
  end
end
