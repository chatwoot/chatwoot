# coding: utf-8
# frozen_string_literal: true

RSpec.describe HTTP::Request::Writer do
  let(:io)          { StringIO.new }
  let(:body)        { HTTP::Request::Body.new("") }
  let(:headers)     { HTTP::Headers.new }
  let(:headerstart) { "GET /test HTTP/1.1" }

  subject(:writer)  { described_class.new(io, body, headers, headerstart) }

  describe "#stream" do
    context "when multiple headers are set" do
      let(:headers) { HTTP::Headers.coerce "Host" => "example.org" }

      it "separates headers with carriage return and line feed" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n",
          "Host: example.org\r\nContent-Length: 0\r\n\r\n"
        ].join
      end
    end

    context "when headers are specified as strings with mixed case" do
      let(:headers) { HTTP::Headers.coerce "content-Type" => "text", "X_MAX" => "200" }

      it "writes the headers with the same casing" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n",
          "content-Type: text\r\nX_MAX: 200\r\nContent-Length: 0\r\n\r\n"
        ].join
      end
    end

    context "when body is nonempty" do
      let(:body) { HTTP::Request::Body.new("content") }

      it "writes it to the socket and sets Content-Length" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n",
          "Content-Length: 7\r\n\r\n",
          "content"
        ].join
      end
    end

    context "when body is not set" do
      let(:body) { HTTP::Request::Body.new(nil) }

      it "doesn't write anything to the socket and doesn't set Content-Length" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n\r\n"
        ].join
      end
    end

    context "when body is empty" do
      let(:body) { HTTP::Request::Body.new("") }

      it "doesn't write anything to the socket and sets Content-Length" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n",
          "Content-Length: 0\r\n\r\n"
        ].join
      end
    end

    context "when Content-Length header is set" do
      let(:headers) { HTTP::Headers.coerce "Content-Length" => "12" }
      let(:body)    { HTTP::Request::Body.new("content") }

      it "keeps the given value" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n",
          "Content-Length: 12\r\n\r\n",
          "content"
        ].join
      end
    end

    context "when Transfer-Encoding is chunked" do
      let(:headers) { HTTP::Headers.coerce "Transfer-Encoding" => "chunked" }
      let(:body)    { HTTP::Request::Body.new(%w[request body]) }

      it "writes encoded content and omits Content-Length" do
        writer.stream
        expect(io.string).to eq [
          "#{headerstart}\r\n",
          "Transfer-Encoding: chunked\r\n\r\n",
          "7\r\nrequest\r\n4\r\nbody\r\n0\r\n\r\n"
        ].join
      end
    end

    context "when server won't accept any more data" do
      before do
        expect(io).to receive(:write).and_raise(Errno::EPIPE)
      end

      it "aborts silently" do
        writer.stream
      end
    end

    context "when writing to socket raises an exception" do
      before do
        expect(io).to receive(:write).and_raise(Errno::ECONNRESET)
      end

      it "raises a ConnectionError" do
        expect { writer.stream }.to raise_error(HTTP::ConnectionError)
      end
    end
  end
end
