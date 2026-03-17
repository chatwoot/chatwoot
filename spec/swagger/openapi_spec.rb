require 'rails_helper'

RSpec.describe 'OpenAPI document', type: :request do
  it 'is valid against the OpenAPI 3.1.0 meta-schema' do
    expect(skooma_openapi_schema).to be_valid_document
  end
end
