require 'rails_helper'

RSpec.describe JsonSchemaValidator, type: :validator do
  schema = {
    'name' => { required: true, type: 'string' },
    'age' => { required: true, type: 'integer' },
    'is_active' => { required: false, type: 'boolean' },
    'tags' => { required: false, type: 'array' },
    'address' => {
      required: false,
      type: 'hash',
      properties: {
        'street' => { required: true, type: 'string' },
        'city' => { required: true, type: 'string' }
      }
    }
  }.freeze
  # Create a simple test model for validation
  before_all do
    # rubocop:disable Lint/ConstantDefinitionInBlock
    # rubocop:disable RSpec/LeakyConstantDeclaration
    TestModelForJSONValidation = Struct.new(:additional_attributes) do
      include ActiveModel::Validations

      validates_with JsonSchemaValidator, schema: schema
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock
    # rubocop:enable RSpec/LeakyConstantDeclaration
  end

  context 'with valid data' do
    let(:valid_data) do
      {
        'name' => 'John Doe',
        'age' => 30,
        'tags' => %w[tag1 tag2],
        'is_active' => true,
        'address' => {
          'street' => '123 Main St',
          'city' => 'Iceland'
        }
      }
    end

    it 'passes validation' do
      model = TestModelForJSONValidation.new(valid_data)
      expect(model.valid?).to be true
      expect(model.errors.full_messages).to be_empty
    end
  end

  context 'with missing required attributes' do
    let(:invalid_data) do
      {
        'name' => 'John Doe',
        'address' => {
          'street' => '123 Main St',
          'city' => 'Iceland'
        }
      }
    end

    it 'fails validation' do
      model = TestModelForJSONValidation.new(invalid_data)
      expect(model.valid?).to be false
      expect(model.errors.messages).to eq({ :root => ['age is required'] })
    end
  end

  context 'with incorrect address hash' do
    let(:invalid_data) do
      {
        'name' => 'John Doe',
        'age' => 30,
        'address' => 'not-a-hash'
      }
    end

    it 'fails validation' do
      model = TestModelForJSONValidation.new(invalid_data)
      expect(model.valid?).to be false
      expect(model.errors.messages).to eq({ :'root.address' => ['must be a hash'] })
    end
  end

  context 'with incorrect types' do
    let(:invalid_data) do
      {
        'name' => 'John Doe',
        'age' => '30',
        'is_active' => 'some-value',
        'tags' => 'not-an-array',
        'address' => {
          'street' => 123,
          'city' => 'Iceland'
        }
      }
    end

    it 'fails validation' do
      model = TestModelForJSONValidation.new(invalid_data)
      expect(model.valid?).to be false
      expect(model.errors.messages).to eq({ :'root.age' => ['must be an integer'], :'root.address.street' => ['must be a string'],
                                            :'root.is_active' => ['must be a boolean'], :'root.tags' => ['must be an array'] })
    end
  end
end
