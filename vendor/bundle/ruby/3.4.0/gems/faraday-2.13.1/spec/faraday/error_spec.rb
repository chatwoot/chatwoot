# frozen_string_literal: true

RSpec.describe Faraday::Error do
  describe '.initialize' do
    subject { described_class.new(exception, response) }
    let(:response) { nil }

    context 'with exception only' do
      let(:exception) { RuntimeError.new('test') }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.inspect).to eq('#<Faraday::Error wrapped=#<RuntimeError: test>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with response hash' do
      let(:exception) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 400') }
      if RUBY_VERSION >= '3.4'
        it { expect(subject.inspect).to eq('#<Faraday::Error response={status: 400}>') }
      else
        it { expect(subject.inspect).to eq('#<Faraday::Error response={:status=>400}>') }
      end
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with string' do
      let(:exception) { 'custom message' }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('custom message') }
      it { expect(subject.inspect).to eq('#<Faraday::Error #<Faraday::Error: custom message>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with anything else #to_s' do
      let(:exception) { %w[error1 error2] }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('["error1", "error2"]') }
      it { expect(subject.inspect).to eq('#<Faraday::Error #<Faraday::Error: ["error1", "error2"]>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with exception string and response hash' do
      let(:exception) { 'custom message' }
      let(:response) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(response) }
      it { expect(subject.message).to eq('custom message') }
      if RUBY_VERSION >= '3.4'
        it { expect(subject.inspect).to eq('#<Faraday::Error response={status: 400}>') }
      else
        it { expect(subject.inspect).to eq('#<Faraday::Error response={:status=>400}>') }
      end
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with exception and response object' do
      let(:exception) { RuntimeError.new('test') }
      let(:body) { { test: 'test' } }
      let(:headers) { { 'Content-Type' => 'application/json' } }
      let(:response) { Faraday::Response.new(status: 400, response_headers: headers, response_body: body) }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to eq(response) }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to eq(headers) }
      it { expect(subject.response_body).to eq(body) }
    end
  end
end
