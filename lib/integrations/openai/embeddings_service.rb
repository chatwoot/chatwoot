# TODO : clean up abstractions
# Going dirty here, but it's a POC
class Integrations::Openai::EmbeddingsService
  pattr_initialize [:hook!]

  def create_article_embeddings
    hook.account.articles.find_each do |article|
      embedding = fetch_embeddings("#{article.title}: #{article.content}")
      embeddings_obj = Embeddings.find_or_initialize_by(obj: article, account_id: article.account_id)
      embeddings_obj.embedding = embedding
      embeddings_obj.save
    end
  end

  def search_article_embeddings(query)
    embedding = fetch_embeddings(query)
    Embeddings.nearest_neighbors(:embedding, embedding, distance: 'euclidean').first(5)
  end

  private

  def fetch_embeddings(input)
    url = 'https://api.openai.com/v1/embeddings'
    headers = {
      'Authorization' => "Bearer #{hook.settings['api_key']}",
      'Content-Type' => 'application/json'
    }
    data = {
      input: input,
      model: 'text-embedding-ada-002'
    }

    response = Net::HTTP.post(URI(url), data.to_json, headers)
    JSON.parse(response.body)['data'].pick('embedding')
  end
end
