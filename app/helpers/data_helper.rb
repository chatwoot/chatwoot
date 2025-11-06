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

  # Converts the given object to a hash.
  # If it's an instance of ActionController::Parameters, converts it to an unsafe hash.
  # Otherwise, returns the object as-is.
  def convert_to_hash(obj)
    return obj.to_unsafe_h if obj.instance_of?(ActionController::Parameters)

    obj
  end

  # Attempts to parse a string as JSON.
  # If successful, returns the parsed hash with symbolized names.
  # If unsuccessful, returns nil.
  def safe_parse_json(content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end
end
