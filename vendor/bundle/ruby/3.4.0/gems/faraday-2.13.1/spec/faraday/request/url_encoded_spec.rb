# frozen_string_literal: true

require 'stringio'

RSpec.describe Faraday::Request::UrlEncoded do
  let(:conn) do
    Faraday.new do |b|
      b.request :url_encoded
      b.adapter :test do |stub|
        stub.post('/echo') do |env|
          posted_as = env[:request_headers]['Content-Type']
          body = env[:body]
          if body.respond_to?(:read)
            body = body.read
          end
          [200, { 'Content-Type' => posted_as }, body]
        end
      end
    end
  end

  it 'does nothing without payload' do
    response = conn.post('/echo')
    expect(response.headers['Content-Type']).to be_nil
    expect(response.body.empty?).to be_truthy
  end

  it 'ignores custom content type' do
    response = conn.post('/echo', { some: 'data' }, 'content-type' => 'application/x-foo')
    expect(response.headers['Content-Type']).to eq('application/x-foo')
    expect(response.body).to eq(some: 'data')
  end

  it 'works with no headers' do
    response = conn.post('/echo', fruit: %w[apples oranges])
    expect(response.headers['Content-Type']).to eq('application/x-www-form-urlencoded')
    expect(response.body).to eq('fruit%5B%5D=apples&fruit%5B%5D=oranges')
  end

  it 'works with with headers' do
    response = conn.post('/echo', { 'a' => 123 }, 'content-type' => 'application/x-www-form-urlencoded')
    expect(response.headers['Content-Type']).to eq('application/x-www-form-urlencoded')
    expect(response.body).to eq('a=123')
  end

  it 'works with nested params' do
    response = conn.post('/echo', user: { name: 'Mislav', web: 'mislav.net' })
    expect(response.headers['Content-Type']).to eq('application/x-www-form-urlencoded')
    expected = { 'user' => { 'name' => 'Mislav', 'web' => 'mislav.net' } }
    expect(Faraday::Utils.parse_nested_query(response.body)).to eq(expected)
  end

  it 'works with non nested params' do
    response = conn.post('/echo', dimensions: %w[date location]) do |req|
      req.options.params_encoder = Faraday::FlatParamsEncoder
    end
    expect(response.headers['Content-Type']).to eq('application/x-www-form-urlencoded')
    expected = { 'dimensions' => %w[date location] }
    expect(Faraday::Utils.parse_query(response.body)).to eq(expected)
    expect(response.body).to eq('dimensions=date&dimensions=location')
  end

  it 'works with unicode' do
    err = capture_warnings do
      response = conn.post('/echo', str: 'eé cç aã aâ')
      expect(response.body).to eq('str=e%C3%A9+c%C3%A7+a%C3%A3+a%C3%A2')
    end
    expect(err.empty?).to be_truthy
  end

  it 'works with nested keys' do
    response = conn.post('/echo', 'a' => { 'b' => { 'c' => ['d'] } })
    expect(response.body).to eq('a%5Bb%5D%5Bc%5D%5B%5D=d')
  end

  it 'works with files' do
    response = conn.post('/echo', StringIO.new('str=apple'))
    expect(response.body).to eq('str=apple')
  end

  context 'customising default_space_encoding' do
    around do |example|
      Faraday::Utils.default_space_encoding = '%20'
      example.run
      Faraday::Utils.default_space_encoding = nil
    end

    it 'uses the custom character to encode spaces' do
      response = conn.post('/echo', str: 'apple banana')
      expect(response.body).to eq('str=apple%20banana')
    end
  end
end
