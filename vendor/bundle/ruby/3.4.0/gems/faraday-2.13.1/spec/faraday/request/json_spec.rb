# frozen_string_literal: true

RSpec.describe Faraday::Request::Json do
  let(:middleware) { described_class.new(->(env) { Faraday::Response.new(env) }) }

  def process(body, content_type = nil)
    env = { body: body, request_headers: Faraday::Utils::Headers.new }
    env[:request_headers]['content-type'] = content_type if content_type
    middleware.call(Faraday::Env.from(env)).env
  end

  def result_body
    result[:body]
  end

  def result_type
    result[:request_headers]['content-type']
  end

  context 'no body' do
    let(:result) { process(nil) }

    it "doesn't change body" do
      expect(result_body).to be_nil
    end

    it "doesn't add content type" do
      expect(result_type).to be_nil
    end
  end

  context 'empty body' do
    let(:result) { process('') }

    it "doesn't change body" do
      expect(result_body).to be_empty
    end

    it "doesn't add content type" do
      expect(result_type).to be_nil
    end
  end

  context 'string body' do
    let(:result) { process('{"a":1}') }

    it "doesn't change body" do
      expect(result_body).to eq('{"a":1}')
    end

    it 'adds content type' do
      expect(result_type).to eq('application/json')
    end
  end

  context 'object body' do
    let(:result) { process(a: 1) }

    it 'encodes body' do
      expect(result_body).to eq('{"a":1}')
    end

    it 'adds content type' do
      expect(result_type).to eq('application/json')
    end
  end

  context 'empty object body' do
    let(:result) { process({}) }

    it 'encodes body' do
      expect(result_body).to eq('{}')
    end
  end

  context 'true body' do
    let(:result) { process(true) }

    it 'encodes body' do
      expect(result_body).to eq('true')
    end

    it 'adds content type' do
      expect(result_type).to eq('application/json')
    end
  end

  context 'false body' do
    let(:result) { process(false) }

    it 'encodes body' do
      expect(result_body).to eq('false')
    end

    it 'adds content type' do
      expect(result_type).to eq('application/json')
    end
  end

  context 'object body with json type' do
    let(:result) { process({ a: 1 }, 'application/json; charset=utf-8') }

    it 'encodes body' do
      expect(result_body).to eq('{"a":1}')
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/json; charset=utf-8')
    end
  end

  context 'object body with vendor json type' do
    let(:result) { process({ a: 1 }, 'application/vnd.myapp.v1+json; charset=utf-8') }

    it 'encodes body' do
      expect(result_body).to eq('{"a":1}')
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/vnd.myapp.v1+json; charset=utf-8')
    end
  end

  context 'object body with incompatible type' do
    let(:result) { process({ a: 1 }, 'application/xml; charset=utf-8') }

    it "doesn't change body" do
      expect(result_body).to eq(a: 1)
    end

    it "doesn't change content type" do
      expect(result_type).to eq('application/xml; charset=utf-8')
    end
  end

  context 'with encoder' do
    let(:encoder) do
      double('Encoder').tap do |e|
        allow(e).to receive(:dump) { |s, opts| JSON.generate(s, opts) }
      end
    end

    let(:result) { process(a: 1) }

    context 'when encoder is passed as object' do
      let(:middleware) { described_class.new(->(env) { Faraday::Response.new(env) }, { encoder: encoder }) }

      it 'calls specified JSON encoder\'s dump method' do
        expect(encoder).to receive(:dump).with({ a: 1 })

        result
      end

      it 'encodes body' do
        expect(result_body).to eq('{"a":1}')
      end

      it 'adds content type' do
        expect(result_type).to eq('application/json')
      end
    end

    context 'when encoder is passed as an object-method pair' do
      let(:middleware) { described_class.new(->(env) { Faraday::Response.new(env) }, { encoder: [encoder, :dump] }) }

      it 'calls specified JSON encoder' do
        expect(encoder).to receive(:dump).with({ a: 1 })

        result
      end

      it 'encodes body' do
        expect(result_body).to eq('{"a":1}')
      end

      it 'adds content type' do
        expect(result_type).to eq('application/json')
      end
    end

    context 'when encoder is not passed' do
      let(:middleware) { described_class.new(->(env) { Faraday::Response.new(env) }) }

      it 'calls JSON.generate' do
        expect(JSON).to receive(:generate).with({ a: 1 })

        result
      end

      it 'encodes body' do
        expect(result_body).to eq('{"a":1}')
      end

      it 'adds content type' do
        expect(result_type).to eq('application/json')
      end
    end
  end
end
