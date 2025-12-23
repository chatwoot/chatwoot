# frozen_string_literal: true

RSpec.describe Faraday::Response::Json, type: :response do
  let(:options) { {} }
  let(:headers) { {} }
  let(:middleware) do
    described_class.new(lambda { |env|
      Faraday::Response.new(env)
    }, **options)
  end

  def process(body, content_type = 'application/json', options = {})
    env = {
      body: body, request: options,
      request_headers: Faraday::Utils::Headers.new,
      response_headers: Faraday::Utils::Headers.new(headers)
    }
    env[:response_headers]['content-type'] = content_type if content_type
    yield(env) if block_given?
    middleware.call(Faraday::Env.from(env))
  end

  context 'no type matching' do
    it "doesn't change nil body" do
      expect(process(nil).body).to be_nil
    end

    it 'nullifies empty body' do
      expect(process('').body).to be_nil
    end

    it 'parses json body' do
      response = process('{"a":1}')
      expect(response.body).to eq('a' => 1)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context 'with preserving raw' do
    let(:options) { { preserve_raw: true } }

    it 'parses json body' do
      response = process('{"a":1}')
      expect(response.body).to eq('a' => 1)
      expect(response.env[:raw_body]).to eq('{"a":1}')
    end
  end

  context 'with default regexp type matching' do
    it 'parses json body of correct type' do
      response = process('{"a":1}', 'application/x-json')
      expect(response.body).to eq('a' => 1)
    end

    it 'ignores json body of incorrect type' do
      response = process('{"a":1}', 'text/json-xml')
      expect(response.body).to eq('{"a":1}')
    end
  end

  context 'with array type matching' do
    let(:options) { { content_type: %w[a/b c/d] } }

    it 'parses json body of correct type' do
      expect(process('{"a":1}', 'a/b').body).to be_a(Hash)
      expect(process('{"a":1}', 'c/d').body).to be_a(Hash)
    end

    it 'ignores json body of incorrect type' do
      expect(process('{"a":1}', 'a/d').body).not_to be_a(Hash)
    end
  end

  it 'chokes on invalid json' do
    expect { process('{!') }.to raise_error(Faraday::ParsingError)
  end

  it 'includes the response on the ParsingError instance' do
    process('{') { |env| env[:response] = Faraday::Response.new }
    raise 'Parsing should have failed.'
  rescue Faraday::ParsingError => e
    expect(e.response).to be_a(Faraday::Response)
  end

  context 'HEAD responses' do
    it "nullifies the body if it's only one space" do
      response = process(' ')
      expect(response.body).to be_nil
    end

    it "nullifies the body if it's two spaces" do
      response = process(' ')
      expect(response.body).to be_nil
    end
  end

  context 'JSON options' do
    let(:body) { '{"a": 1}' }
    let(:result) { { a: 1 } }
    let(:options) do
      {
        parser_options: {
          symbolize_names: true
        }
      }
    end

    it 'passes relevant options to JSON parse' do
      expect(::JSON).to receive(:parse)
        .with(body, options[:parser_options])
        .and_return(result)

      response = process(body)
      expect(response.body).to eq(result)
    end
  end

  context 'with decoder' do
    let(:decoder) do
      double('Decoder').tap do |e|
        allow(e).to receive(:load) { |s, opts| JSON.parse(s, opts) }
      end
    end

    let(:body) { '{"a": 1}' }
    let(:result) { { a: 1 } }

    context 'when decoder is passed as object' do
      let(:options) do
        {
          parser_options: {
            decoder: decoder,
            option: :option_value,
            symbolize_names: true
          }
        }
      end

      it 'passes relevant options to specified decoder\'s load method' do
        expect(decoder).to receive(:load)
          .with(body, { option: :option_value, symbolize_names: true })
          .and_return(result)

        response = process(body)
        expect(response.body).to eq(result)
      end
    end

    context 'when decoder is passed as an object-method pair' do
      let(:options) do
        {
          parser_options: {
            decoder: [decoder, :load],
            option: :option_value,
            symbolize_names: true
          }
        }
      end

      it 'passes relevant options to specified decoder\'s method' do
        expect(decoder).to receive(:load)
          .with(body, { option: :option_value, symbolize_names: true })
          .and_return(result)

        response = process(body)
        expect(response.body).to eq(result)
      end
    end

    context 'when decoder is not passed' do
      let(:options) do
        {
          parser_options: {
            symbolize_names: true
          }
        }
      end

      it 'passes relevant options to JSON parse' do
        expect(JSON).to receive(:parse)
          .with(body, { symbolize_names: true })
          .and_return(result)

        response = process(body)
        expect(response.body).to eq(result)
      end

      it 'passes relevant options to JSON parse even when nil responds to :load' do
        original_allow_message_expectations_on_nil = RSpec::Mocks.configuration.allow_message_expectations_on_nil
        RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
        allow(nil).to receive(:respond_to?)
          .with(:load)
          .and_return(true)

        expect(JSON).to receive(:parse)
          .with(body, { symbolize_names: true })
          .and_return(result)

        response = process(body)
        expect(response.body).to eq(result)
      ensure
        RSpec::Mocks.configuration.allow_message_expectations_on_nil = original_allow_message_expectations_on_nil
      end
    end
  end
end
