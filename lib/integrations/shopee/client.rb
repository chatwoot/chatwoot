class Integrations::Shopee::Client
  pattr_initialize [:access_token, :shop_id]

  def query(params)
    @params = params
    self
  end

  def body(data)
    @body = data
    self
  end

  def get(path)
    request path: path do
      HTTParty.get(url, query: final_params, headers: headers)
    end
  end

  def delete(path)
    request path: path do
      HTTParty.delete(url, query: final_params, headers: headers)
    end
  end

  def put(path)
    request path: path do
      HTTParty.put(url, query: final_params, body: final_body, headers: headers)
    end
  end

  def post(path)
    request path: path do
      HTTParty.post(url, query: final_params, body: final_body, headers: headers)
    end
  end

  def patch(path)
    request path: path do
      HTTParty.patch(url, query: final_params, body: final_body, headers: headers)
    end
  end

  private

  attr_reader :shop_id, :access_token

  def final_params
    signature = Integrations::Shopee::Signature.new(@path, {
                                                      shop_id: shop_id,
                                                      access_token: access_token
                                                    })
    @params.to_h.merge(signature.generate)
  end

  def final_body
    return @final_body if defined?(@final_body)

    hash_data = @body.presence || {}
    file_uploading = hash_data.values.any? { |v| v.is_a?(File) || v.is_a?(Tempfile) }
    @final_body = file_uploading ? hash_data : hash_data.to_json
  end

  def headers
    if final_body.is_a?(Hash)
      { 'Content-Type' => 'multipart/form-data' }
    else
      { 'Content-Type' => 'application/json' }
    end
  end

  def url
    @url ||= [Integrations::Shopee::Constants.base_url, @path].join
  end

  def request(path:)
    @path = path # For building the final URL and Signature
    Rails.logger.info("Shopee Request: #{path}, #{@params}, #{@body}")
    response = yield
    if response.success?
      Rails.logger.info("Shopee Success: #{response.body}")
      JSON.parse(response.body)
    else
      message = "Shopee Error: #{response.code}, #{response.body}"
      Rails.logger.error(message)
      raise Integrations::Shopee::Error.new(message, response)
    end
  end
end
