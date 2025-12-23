# frozen_string_literal: true

RSpec.describe HTTP::Features::AutoInflate do
  subject(:feature) { HTTP::Features::AutoInflate.new }

  let(:connection) { double }
  let(:headers)    { {} }

  let(:response) do
    HTTP::Response.new(
      :version    => "1.1",
      :status     => 200,
      :headers    => headers,
      :connection => connection,
      :request    => HTTP::Request.new(:verb => :get, :uri => "http://example.com")
    )
  end

  describe "#wrap_response" do
    subject(:result) { feature.wrap_response(response) }

    context "when there is no Content-Encoding header" do
      it "returns original request" do
        expect(result).to be response
      end
    end

    context "for identity Content-Encoding header" do
      let(:headers) { {:content_encoding => "identity"} }

      it "returns original request" do
        expect(result).to be response
      end
    end

    context "for unknown Content-Encoding header" do
      let(:headers) { {:content_encoding => "not-supported"} }

      it "returns original request" do
        expect(result).to be response
      end
    end

    context "for deflate Content-Encoding header" do
      let(:headers) { {:content_encoding => "deflate"} }

      it "returns a HTTP::Response wrapping the inflated response body" do
        expect(result.body).to be_instance_of HTTP::Response::Body
      end
    end

    context "for gzip Content-Encoding header" do
      let(:headers) { {:content_encoding => "gzip"} }

      it "returns a HTTP::Response wrapping the inflated response body" do
        expect(result.body).to be_instance_of HTTP::Response::Body
      end
    end

    context "for x-gzip Content-Encoding header" do
      let(:headers) { {:content_encoding => "x-gzip"} }

      it "returns a HTTP::Response wrapping the inflated response body" do
        expect(result.body).to be_instance_of HTTP::Response::Body
      end
    end

    # TODO(ixti): We should refactor API to either make uri non-optional,
    #   or add reference to request into response object (better).
    context "when response has uri" do
      let(:response) do
        HTTP::Response.new(
          :version    => "1.1",
          :status     => 200,
          :headers    => {:content_encoding => "gzip"},
          :connection => connection,
          :request    => HTTP::Request.new(:verb => :get, :uri => "https://example.com")
        )
      end

      it "preserves uri in wrapped response" do
        expect(result.uri).to eq HTTP::URI.parse("https://example.com")
      end
    end
  end
end
