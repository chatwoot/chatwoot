class ArticleKeyConverter
  def initialize(article)
    @article = article
  end

  def process
    new_content = replace(@article.content)
    @article.update(content: new_content)
  end

  private

  def convert_key(id)
    verifier_name = 'ActiveStorage'
    key_generator =  ActiveSupport::KeyGenerator.new(Rails.application.secrets.secret_key_base, iterations: 1000,
                                                                                                hash_digest_class: OpenSSL::Digest::SHA1)
    key_generator = ActiveSupport::CachingKeyGenerator.new(key_generator)
    secret = key_generator.generate_key(verifier_name.to_s)
    verifier = ActiveSupport::MessageVerifier.new(secret)

    begin
      ActiveStorage::Blob.find(verifier.verify(id, purpose: :blob_id))
                         .try(:signed_id)
    rescue StandardError
      nil
    end
  end

  def replace(text)
    keys = get_keys(text)
    keys.each do |key|
      new_key = convert_key(key)
      text = text.gsub(key, new_key) if new_key
    end
    text
  end

  def get_keys(text)
    uris = text.scan(URI::DEFAULT_PARSER.make_regexp).flatten.select do |x|
      x.to_s.include?('rails/active_storage')
    end

    uris.map { |x| x.split('/')[-2] }
  end
end

class UpdateArticleImageKeys < ActiveRecord::Migration[7.0]
  def change
    # Iterate through all articles
    Article.find_each do |article|
      # Run the ArticleKeyConverter for each one
      ArticleKeyConverter.new(article).process
    end
  end
end
