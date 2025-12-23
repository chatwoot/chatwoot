# frozen_string_literal: true

RSpec.describe Faraday::Response do
  subject { Faraday::Response.new(env) }

  let(:env) do
    Faraday::Env.from(status: 404, body: 'yikes', url: Faraday::Utils.URI('https://lostisland.github.io/faraday'),
                      response_headers: { 'Content-Type' => 'text/plain' })
  end

  it { expect(subject.finished?).to be_truthy }
  it { expect { subject.finish({}) }.to raise_error(RuntimeError) }
  it { expect(subject.success?).to be_falsey }
  it { expect(subject.status).to eq(404) }
  it { expect(subject.body).to eq('yikes') }
  it { expect(subject.headers['Content-Type']).to eq('text/plain') }
  it { expect(subject['content-type']).to eq('text/plain') }

  describe '#apply_request' do
    before { subject.apply_request(body: 'a=b', method: :post) }

    it { expect(subject.body).to eq('yikes') }
    it { expect(subject.env[:method]).to eq(:post) }
  end

  describe '#to_hash' do
    let(:hash) { subject.to_hash }

    it { expect(hash).to be_a(Hash) }
    it { expect(hash[:status]).to eq(subject.status) }
    it { expect(hash[:response_headers]).to eq(subject.headers) }
    it { expect(hash[:body]).to eq(subject.body) }
    it { expect(hash[:url]).to eq(subject.env.url) }
  end

  describe 'marshal serialization support' do
    subject { Faraday::Response.new }
    let(:loaded) { Marshal.load(Marshal.dump(subject)) }

    before do
      subject.on_complete {}
      subject.finish(env.merge(params: 'moo'))
    end

    it { expect(loaded.env[:params]).to be_nil }
    it { expect(loaded.env[:body]).to eq(env[:body]) }
    it { expect(loaded.env[:response_headers]).to eq(env[:response_headers]) }
    it { expect(loaded.env[:status]).to eq(env[:status]) }
    it { expect(loaded.env[:url]).to eq(env[:url]) }
  end

  describe '#on_complete' do
    subject { Faraday::Response.new }

    it 'parse body on finish' do
      subject.on_complete { |env| env[:body] = env[:body].upcase }
      subject.finish(env)

      expect(subject.body).to eq('YIKES')
    end

    it 'can access response body in on_complete callback' do
      subject.on_complete { |env| env[:body] = subject.body.upcase }
      subject.finish(env)

      expect(subject.body).to eq('YIKES')
    end

    it 'can access response body in on_complete callback' do
      callback_env = nil
      subject.on_complete { |env| callback_env = env }
      subject.finish({})

      expect(subject.env).to eq(callback_env)
    end
  end
end
