# frozen_string_literal: true

RSpec.describe Faraday::Request::Instrumentation do
  class FakeInstrumenter
    attr_reader :instrumentations

    def initialize
      @instrumentations = []
    end

    def instrument(name, env)
      @instrumentations << [name, env]
      yield
    end
  end

  let(:config) { {} }
  let(:options) { Faraday::Request::Instrumentation::Options.from config }
  let(:instrumenter) { FakeInstrumenter.new }
  let(:conn) do
    Faraday.new do |f|
      f.request :instrumentation, config.merge(instrumenter: instrumenter)
      f.adapter :test do |stub|
        stub.get '/' do
          [200, {}, 'ok']
        end
      end
    end
  end

  it { expect(options.name).to eq('request.faraday') }
  it 'defaults to ActiveSupport::Notifications' do
    res = options.instrumenter
  rescue NameError => e
    expect(e.to_s).to match('ActiveSupport')
  else
    expect(res).to eq(ActiveSupport::Notifications)
  end

  it 'instruments with default name' do
    expect(instrumenter.instrumentations.size).to eq(0)

    res = conn.get '/'
    expect(res.body).to eq('ok')
    expect(instrumenter.instrumentations.size).to eq(1)

    name, env = instrumenter.instrumentations.first
    expect(name).to eq('request.faraday')
    expect(env[:url].path).to eq('/')
  end

  context 'with custom name' do
    let(:config) { { name: 'custom' } }

    it { expect(options.name).to eq('custom') }
    it 'instruments with custom name' do
      expect(instrumenter.instrumentations.size).to eq(0)

      res = conn.get '/'
      expect(res.body).to eq('ok')
      expect(instrumenter.instrumentations.size).to eq(1)

      name, env = instrumenter.instrumentations.first
      expect(name).to eq('custom')
      expect(env[:url].path).to eq('/')
    end
  end

  context 'with custom instrumenter' do
    let(:config) { { instrumenter: :custom } }

    it { expect(options.instrumenter).to eq(:custom) }
  end
end
