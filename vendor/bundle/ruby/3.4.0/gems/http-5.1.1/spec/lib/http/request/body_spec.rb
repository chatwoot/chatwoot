# frozen_string_literal: true

RSpec.describe HTTP::Request::Body do
  let(:body) { "" }
  subject    { HTTP::Request::Body.new(body) }

  describe "#initialize" do
    context "when body is nil" do
      let(:body) { nil }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when body is a string" do
      let(:body) { "string body" }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when body is an IO" do
      let(:body) { FakeIO.new("IO body") }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when body is an Enumerable" do
      let(:body) { %w[bees cows] }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when body is of unrecognized type" do
      let(:body) { 123 }

      it "raises an error" do
        expect { subject }.to raise_error(HTTP::RequestError)
      end
    end
  end

  describe "#source" do
    it "returns the original object" do
      expect(subject.source).to eq ""
    end
  end

  describe "#size" do
    context "when body is nil" do
      let(:body) { nil }

      it "returns zero" do
        expect(subject.size).to eq 0
      end
    end

    context "when body is a string" do
      let(:body) { "Привет, мир!" }

      it "returns string bytesize" do
        expect(subject.size).to eq 21
      end
    end

    context "when body is an IO with size" do
      let(:body) { FakeIO.new("content") }

      it "returns IO size" do
        expect(subject.size).to eq 7
      end
    end

    context "when body is an IO without size" do
      let(:body) { IO.pipe[0] }

      it "raises a RequestError" do
        expect { subject.size }.to raise_error(HTTP::RequestError)
      end
    end

    context "when body is an Enumerable" do
      let(:body) { %w[bees cows] }

      it "raises a RequestError" do
        expect { subject.size }.to raise_error(HTTP::RequestError)
      end
    end
  end

  describe "#each" do
    let(:chunks) do
      chunks = []
      subject.each { |chunk| chunks << chunk.dup }
      chunks
    end

    context "when body is nil" do
      let(:body) { nil }

      it "yields nothing" do
        expect(chunks).to eq []
      end
    end

    context "when body is a string" do
      let(:body) { "content" }

      it "yields the string" do
        expect(chunks).to eq %w[content]
      end
    end

    context "when body is a non-Enumerable IO" do
      let(:body) { FakeIO.new(("a" * 16 * 1024) + ("b" * 10 * 1024)) }

      it "yields chunks of content" do
        expect(chunks.inject("", :+)).to eq ("a" * 16 * 1024) + ("b" * 10 * 1024)
      end
    end

    context "when body is a pipe" do
      let(:ios)  { IO.pipe }
      let(:body) { ios[0] }

      around do |example|
        writer = Thread.new(ios[1]) do |io|
          io << "abcdef"
          io.close
        end

        begin
          example.run
        ensure
          writer.join
        end
      end

      it "yields chunks of content" do
        expect(chunks.inject("", :+)).to eq("abcdef")
      end
    end

    context "when body is an Enumerable IO" do
      let(:data) { ("a" * 16 * 1024) + ("b" * 10 * 1024) }
      let(:body) { StringIO.new data }

      it "yields chunks of content" do
        expect(chunks.inject("", :+)).to eq data
      end

      it "allows to enumerate multiple times" do
        results = []

        2.times do
          result = ""
          subject.each { |chunk| result += chunk }
          results << result
        end

        aggregate_failures do
          expect(results.count).to eq 2
          expect(results).to all eq data
        end
      end
    end

    context "when body is an Enumerable" do
      let(:body) { %w[bees cows] }

      it "yields elements" do
        expect(chunks).to eq %w[bees cows]
      end
    end
  end

  describe "#==" do
    context "when sources are equivalent" do
      let(:body1) { HTTP::Request::Body.new("content") }
      let(:body2) { HTTP::Request::Body.new("content") }

      it "returns true" do
        expect(body1).to eq body2
      end
    end

    context "when sources are not equivalent" do
      let(:body1) { HTTP::Request::Body.new("content") }
      let(:body2) { HTTP::Request::Body.new(nil) }

      it "returns false" do
        expect(body1).not_to eq body2
      end
    end

    context "when objects are not of the same class" do
      let(:body1) { HTTP::Request::Body.new("content") }
      let(:body2) { "content" }

      it "returns false" do
        expect(body1).not_to eq body2
      end
    end
  end
end
