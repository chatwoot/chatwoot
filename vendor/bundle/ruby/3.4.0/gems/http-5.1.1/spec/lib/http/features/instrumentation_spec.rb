# frozen_string_literal: true

RSpec.describe HTTP::Features::Instrumentation do
  subject(:feature) { HTTP::Features::Instrumentation.new(:instrumenter => instrumenter) }

  let(:instrumenter) { TestInstrumenter.new }

  before do
    test_instrumenter = Class.new(HTTP::Features::Instrumentation::NullInstrumenter) do
      attr_reader :output

      def initialize
        @output = {}
      end

      def start(_name, payload)
        output[:start] = payload
      end

      def finish(_name, payload)
        output[:finish] = payload
      end
    end

    stub_const("TestInstrumenter", test_instrumenter)
  end

  describe "logging the request" do
    let(:request) do
      HTTP::Request.new(
        :verb    => :post,
        :uri     => "https://example.com/",
        :headers => {:accept => "application/json"},
        :body    => '{"hello": "world!"}'
      )
    end

    it "should log the request" do
      feature.wrap_request(request)

      expect(instrumenter.output[:start]).to eq(:request => request)
    end
  end

  describe "logging the response" do
    let(:response) do
      HTTP::Response.new(
        :version => "1.1",
        :status  => 200,
        :headers => {:content_type => "application/json"},
        :body    => '{"success": true}',
        :request => HTTP::Request.new(:verb => :get, :uri => "https://example.com")
      )
    end

    it "should log the response" do
      feature.wrap_response(response)

      expect(instrumenter.output[:finish]).to eq(:response => response)
    end
  end
end
