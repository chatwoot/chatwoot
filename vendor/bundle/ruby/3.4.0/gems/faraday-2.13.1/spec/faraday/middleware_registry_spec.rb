# frozen_string_literal: true

RSpec.describe Faraday::MiddlewareRegistry do
  before do
    stub_const('CustomMiddleware', custom_middleware_klass)
  end
  let(:custom_middleware_klass) { Class.new(Faraday::Middleware) }
  let(:dummy) { Class.new { extend Faraday::MiddlewareRegistry } }

  after { dummy.unregister_middleware(:custom) }

  it 'allows to register with constant' do
    dummy.register_middleware(custom: custom_middleware_klass)
    expect(dummy.lookup_middleware(:custom)).to eq(custom_middleware_klass)
  end

  it 'allows to register with symbol' do
    dummy.register_middleware(custom: :CustomMiddleware)
    expect(dummy.lookup_middleware(:custom)).to eq(custom_middleware_klass)
  end

  it 'allows to register with string' do
    dummy.register_middleware(custom: 'CustomMiddleware')
    expect(dummy.lookup_middleware(:custom)).to eq(custom_middleware_klass)
  end

  it 'allows to register with Proc' do
    dummy.register_middleware(custom: -> { custom_middleware_klass })
    expect(dummy.lookup_middleware(:custom)).to eq(custom_middleware_klass)
  end
end
