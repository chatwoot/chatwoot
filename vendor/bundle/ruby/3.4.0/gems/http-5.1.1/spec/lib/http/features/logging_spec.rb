# frozen_string_literal: true

require "logger"

RSpec.describe HTTP::Features::Logging do
  subject(:feature) do
    logger           = Logger.new(logdev)
    logger.formatter = ->(severity, _, _, message) { format("** %s **\n%s\n", severity, message) }

    described_class.new(:logger => logger)
  end

  let(:logdev) { StringIO.new }

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

      expect(logdev.string).to eq <<~OUTPUT
        ** INFO **
        > POST https://example.com/
        ** DEBUG **
        Accept: application/json
        Host: example.com
        User-Agent: http.rb/#{HTTP::VERSION}

        {"hello": "world!"}
      OUTPUT
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

      expect(logdev.string).to eq <<~OUTPUT
        ** INFO **
        < 200 OK
        ** DEBUG **
        Content-Type: application/json

        {"success": true}
      OUTPUT
    end
  end
end
