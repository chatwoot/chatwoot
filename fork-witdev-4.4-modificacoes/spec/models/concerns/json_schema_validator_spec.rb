require 'rails_helper'

RSpec.describe JsonSchemaValidator, type: :validator do
  schema = {
    'type' => 'object',
    'properties' => {
      'name' => { 'type' => 'string' },
      'age' => { 'type' => 'integer', 'minimum' => 18, 'maximum' => 100 },
      'is_active' => { 'type' => 'boolean' },
      'tags' => { 'type' => 'array' },
      'score' => { 'type' => 'number', 'minimum' => 0, 'maximum' => 10 },
      'address' => {
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string' },
          'city' => { 'type' => 'string' }
        },
        'required' => %w[street city]
      }
    },
    :required => %w[name age]
  }.to_json.freeze

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
      expect(model.errors.messages).to eq({ :age => ['is required'] })
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
      expect(model.errors.messages).to eq({ :address => ['must be of type hash'] })
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
      expect(model.errors.messages).to eq({ :age => ['must be of type integer'], :'address/street' => ['must be of type string'],
                                            :is_active => ['must be of type boolean'], :tags => ['must be of type array'] })
    end
  end

  context 'with value below minimum' do
    let(:invalid_data) do
      {
        'name' => 'John Doe',
        'age' => 15,
        'score' => -1,
        'is_active' => true
      }
    end

    it 'fails validation' do
      model = TestModelForJSONValidation.new(invalid_data)
      expect(model.valid?).to be false
      expect(model.errors.messages).to eq({
                                            :age => ['must be greater than or equal to 18'],
                                            :score => ['must be greater than or equal to 0']
                                          })
    end
  end

  context 'with value above maximum' do
    let(:invalid_data) do
      {
        'name' => 'John Doe',
        'age' => 120,
        'score' => 11,
        'is_active' => true
      }
    end

    it 'fails validation' do
      model = TestModelForJSONValidation.new(invalid_data)
      expect(model.valid?).to be false
      expect(model.errors.messages).to eq({
                                            :age => ['must be less than or equal to 100'],
                                            :score => ['must be less than or equal to 10']
                                          })
    end
  end
end
