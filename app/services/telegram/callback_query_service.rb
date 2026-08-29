class Telegram::CallbackQueryService
  pattr_initialize [:inbox!, :params!]

  def perform
    callback_query_id = params.dig(:callback_query, :id)
    return if callback_query_id.blank?

    response = HTTParty.post("#{inbox.channel.telegram_api_url}/answerCallbackQuery",
                             body: { callback_query_id: callback_query_id }, timeout: 3)
    return if callback_query_acknowledged?(response)

    Rails.logger.warn(
      'Telegram callback ack failed ' \
      "inbox_id=#{inbox.id} callback_query_id=#{callback_query_id} " \
      "status=#{response&.code} body=#{response&.body}"
    )
  rescue StandardError => e
    Rails.logger.warn(
      'Telegram callback ack error ' \
      "inbox_id=#{inbox&.id} callback_query_id=#{callback_query_id} " \
      "#{e.class}: #{e.message}"
    )
  end

  private

  def callback_query_acknowledged?(response)
    return false unless response&.success?

    parsed_response = response.parsed_response
    !parsed_response.is_a?(Hash) || parsed_response['ok'] != false
  end
end
