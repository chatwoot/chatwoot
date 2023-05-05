# This file defines a custom validator class `JsonSchemaValidator` for validating a JSON object against a schema.
# To use this validator, define a schema as a Ruby hash and include it in the validation options when validating a model.
# The schema should define the expected structure and types of the JSON object, as well as any validation rules.
# Here's an example schema:
#
# schema = {
#   'type' => 'object',
#   'properties' => {
#     'name' => { 'type' => 'string' },
#     'age' => { 'type' => 'integer' },
#     'is_active' => { 'type' => 'boolean' },
#     'tags' => { 'type' => 'array' },
#     'address' => {
#       'type' => 'object',
#       'properties' => {
#         'street' => { 'type' => 'string' },
#         'city' => { 'type' => 'string' }
#       },
#       'required' => ['street', 'city']
#     }
#   },
#   'required': ['name', 'age']
# }.to_json.freeze
#
# To validate a model using this schema, include the `JsonSchemaValidator` in the model's validations and pass the schema
# as an option:
#
# class MyModel < ApplicationRecord
#   validates_with JsonSchemaValidator, schema: schema
# end

class JsonSchemaValidator < ActiveModel::Validator
  def validate(record)
    # Get the attribute resolver function from options or use a default one
    attribute_resolver = options[:attribute_resolver] || ->(rec) { rec.additional_attributes }

    # Resolve the JSON data to be validated
    json_data = attribute_resolver.call(record)

    # Get the schema to be used for validation
    schema = options[:schema]

    # Create a JSONSchemer instance using the schema
    schemer = JSONSchemer.schema(schema)

    # Validate the JSON data against the schema
    validation_errors = schemer.validate(json_data)

    # Add validation errors to the record with a formatted statement
    validation_errors.each do |error|
      format_and_append_error(error, record)
    end
  end

  private

  def format_and_append_error(error, record)
    return handle_required(error, record) if error['type'] == 'required'

    type = error['type'] == 'object' ? 'hash' : error['type']

    handle_type(error, record, type)
  end

  def handle_required(error, record)
    missing_values = error['details']['missing_keys']
    missing_values.each do |missing|
      record.errors.add(missing, 'is required')
    end
  end

  def handle_type(error, record, expected_type)
    data = get_name_from_data_pointer(error)
    record.errors.add(data, "must be of type #{expected_type}")
  end

  def get_name_from_data_pointer(error)
    data = error['data_pointer']

    # if data starts with a "/" remove it
    data[1..] if data[0] == '/'
  end
end
