require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ResponseClassifier do
  it 'classifies Slack response-level authentication failures' do
    classifier = described_class.new(provider_key: 'slack', source: 'openapi')

    expect { classifier.classify(JSON.generate(ok: false, error: 'invalid_auth')) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'authentication', code: 'provider_authentication_failed')
      end
  end

  it 'classifies Slack missing scopes and missing trusted resources' do
    classifier = described_class.new(provider_key: 'slack', source: 'openapi')

    expect { classifier.classify(JSON.generate(ok: false, error: 'missing_scope')) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'authorization', code: 'provider_authorization_failed')
      end
    expect { classifier.classify(JSON.generate(ok: false, error: 'message_not_found')) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'not_found', code: 'provider_resource_not_found')
      end
    expect { classifier.classify(JSON.generate(ok: false, error: 'not_in_channel')) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'authorization', code: 'provider_authorization_failed')
      end
  end

  it 'classifies top-level GraphQL errors returned with HTTP 200' do
    classifier = described_class.new(provider_key: 'linear', source: 'graphql')
    response = { errors: [{ message: 'rate limited', extensions: { code: 'RATELIMITED' } }] }

    expect { classifier.classify(JSON.generate(response)) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'rate_limit', code: 'provider_rate_limited')
      end
  end

  it 'classifies Shopify mutation user errors before exposing data' do
    classifier = described_class.new(provider_key: 'shopify', source: 'graphql')
    response = { data: { tagsAdd: { userErrors: [{ field: ['id'], message: 'invalid' }] } } }

    expect { classifier.classify(JSON.generate(response)) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'validation', code: 'provider_validation_failed')
      end
  end

  it 'classifies Shopify mutation-specific user error collections' do
    classifier = described_class.new(provider_key: 'shopify', source: 'graphql')
    response = { data: { orderCancel: { orderCancelUserErrors: [{ field: ['orderId'], message: 'invalid' }] } } }

    expect { classifier.classify(JSON.generate(response)) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'validation', code: 'provider_validation_failed')
      end
  end

  it 'classifies unsuccessful Linear mutation payloads returned with HTTP 200' do
    classifier = described_class.new(provider_key: 'linear', source: 'graphql')
    response = { data: { commentCreate: { success: false, comment: nil } } }

    expect { classifier.classify(JSON.generate(response)) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'validation', code: 'provider_validation_failed')
      end
  end

  it 'unwraps successful GraphQL data only after error checks' do
    classifier = described_class.new(provider_key: 'linear', source: 'graphql')

    expect(classifier.classify(JSON.generate(data: { issue: { id: 'issue_1' } })))
      .to eq('issue' => { 'id' => 'issue_1' })
  end
end
