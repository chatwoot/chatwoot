class Digitaltolk::ToggleTicketReplied
  attr_accessor :status

  def initialize(status, conversation_id)
    @status = status
  end

  def perform
    return false # temporary disable

    post_status
  end

  private

  def post_status
    url = '' # dt url
    headers = {
      # 'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY', '')}",
      # 'Content-Type' => 'application/json'
    }
    data = {
      is_ticket_replied: status
    }

    response = Net::HTTP.post(URI(url), data.to_json, headers)
  end
end