# Provides utility methods for data transformation, hash manipulation, and JSON parsing.
# This module contains helper methods for converting between different data types,
# normalizing hashes, and safely handling JSON operations.
module DataHelper
  # Ensures a hash supports indifferent access (string or symbol keys).
  # Returns an empty hash if the input is blank.
  def ensure_indifferent_access(hash)
    return {} if hash.blank?

    hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access : hash
  end

  def convert_to_hash(obj)
    return obj.to_unsafe_h if obj.instance_of?(ActionController::Parameters)

    obj
  end

  def safe_parse_json(content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end
end
