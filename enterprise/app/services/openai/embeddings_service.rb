class Openai::EmbeddingsService
  def get_embedding(content)
    fetch_embeddings(content)
  end

  private

  def fetch_embeddings(input)
    url = 'https://api.openai.com/v1/embeddings'
    headers = {
      'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY', '')}",
      'Content-Type' => 'application/json'
    }
    data = {
      input: input,
      model: 'text-embedding-ada-002'
    }

    response = Net::HTTP.post(URI(url), data.to_json, headers)
    JSON.parse(response.body)['data']&.pick('embedding')
  end
end
