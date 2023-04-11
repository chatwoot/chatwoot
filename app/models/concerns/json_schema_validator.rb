# This file defines a custom validator class `JsonSchemaValidator` for validating a JSON object against a schema.
# To use this validator, define a schema as a Ruby hash and include it in the validation options when validating a model.
# The schema should define the expected structure and types of the JSON object, as well as any validation rules.
# Here's an example schema:
#
# schema = {
#   'name' => { required: true, type: 'string' },
#   'age' => { required: true, type: 'integer' },
#   'is_active' => { required: false, type: 'boolean' },
#   'tags' => { required: false, type: 'array' },
#   'address' => {
#     required: false,
#     type: 'hash',
#     properties: {
#       'street' => { required: true, type: 'string' },
#       'city' => { required: true, type: 'string' }
#     }
#   }
# }.freeze
#
# To validate a model using this schema, include the `JsonSchemaValidator` in the model's validations and pass the schema
# as an option:
#
# class MyModel < ApplicationRecord
#   validates_with JsonSchemaValidator, schema: schema
# end

class JsonSchemaValidator < ActiveModel::Validator
  def validate(record)
    # get the attribute resolver function from options or use a default one
    attribute_resolver = options[:attribute_resolver] || ->(rec) { rec.additional_attributes }

    # resolve the JSON data to be validated
    json_data = attribute_resolver.call(record)

    # get the schema to be used for validation
    schema = options[:schema]

    # call the private method to validate the schema
    validate_schema(json_data, schema, 'root', record)
  end

  private

  def validate_schema(json_data, schema, path, record)
    schema.each do |key, rule|
      value = json_data[key] # get the value for the current key

      # check if the value is required and not present
      if rule[:required] && value.nil?
        record.errors.add(path, "#{key} is required")
      elsif !value.nil? # check if the value is present
        validate_type(value, rule[:type], "#{path}.#{key}", record) # validate the type of the value

        # validate the nested schema if the value is a Hash
        validate_schema(value, rule[:properties], "#{path}.#{key}", record) if rule[:properties] && value.is_a?(Hash)
      end
    end
  end

  def validate_type(value, type, path, record)
    case type
    when 'string'
      validate_string(value, path, record)
    when 'integer'
      validate_integer(value, path, record)
    when 'hash'
      validate_hash(value, path, record)
    when 'array'
      validate_array(value, path, record)
    when 'boolean'
      validate_boolean(value, path, record)
    else
      raise ArgumentError, "Unsupported type: #{type}"
    end
  end

  def validate_string(value, path, record)
    record.errors.add(path, 'must be a string') unless value.is_a?(String)
  end

  def validate_integer(value, path, record)
    record.errors.add(path, 'must be an integer') unless value.is_a?(Integer)
  end

  def validate_hash(value, path, record)
    record.errors.add(path, 'must be a hash') unless value.is_a?(Hash)
  end

  def validate_array(value, path, record)
    record.errors.add(path, 'must be an array') unless value.is_a?(Array)
  end

  def validate_boolean(value, path, record)
    record.errors.add(path, 'must be a boolean') unless [true, false].include?(value)
  end
end
