module DeviseTokenAuth::Concerns::TokensSerialization
  extend self
  # Serialization hash to json
  def dump(object)
    JSON.generate(object && object.transform_values do |token|
      serialize_updated_at(token).compact
    end.compact)
  end

  # Deserialization json to hash
  def load(json)
    case json
    when String
      JSON.parse(json)
    when NilClass
      {}
    else
      json
    end
  end

  private

  def serialize_updated_at(token)
    updated_at_key = ['updated_at', :updated_at].find(&token.method(:[]))

    return token unless token[updated_at_key].respond_to?(:iso8601)

    token.merge updated_at_key => token[updated_at_key].iso8601
  end
end
