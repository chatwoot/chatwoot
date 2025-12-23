# frozen_string_literal: true

# Requires Ruby with test-unit and faraday gems.
# ruby client_test.rb

require 'faraday'
require 'json'
require 'test/unit'

# Example API client
class Client
  def initialize(conn)
    @conn = conn
  end

  def httpbingo(jname, params: {})
    res = @conn.get("/#{jname}", params)
    data = JSON.parse(res.body)
    data['origin']
  end

  def foo(params)
    res = @conn.post('/foo', JSON.dump(params))
    res.status
  end
end

# Example API client test
class ClientTest < Test::Unit::TestCase
  def test_httpbingo_name
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/api') do |env|
      # optional: you can inspect the Faraday::Env
      assert_equal '/api', env.url.path
      [
        200,
        { 'Content-Type': 'application/javascript' },
        '{"origin": "127.0.0.1"}'
      ]
    end

    # uncomment to trigger stubs.verify_stubbed_calls failure
    # stubs.get('/unused') { [404, {}, ''] }

    cli = client(stubs)
    assert_equal '127.0.0.1', cli.httpbingo('api')
    stubs.verify_stubbed_calls
  end

  def test_httpbingo_not_found
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/api') do
      [
        404,
        { 'Content-Type': 'application/javascript' },
        '{}'
      ]
    end

    cli = client(stubs)
    assert_nil cli.httpbingo('api')
    stubs.verify_stubbed_calls
  end

  def test_httpbingo_exception
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/api') do
      raise Faraday::ConnectionFailed
    end

    cli = client(stubs)
    assert_raise Faraday::ConnectionFailed do
      cli.httpbingo('api')
    end
    stubs.verify_stubbed_calls
  end

  def test_strict_mode
    stubs = Faraday::Adapter::Test::Stubs.new(strict_mode: true)
    stubs.get('/api?abc=123') do
      [
        200,
        { 'Content-Type': 'application/javascript' },
        '{"origin": "127.0.0.1"}'
      ]
    end

    cli = client(stubs)
    assert_equal '127.0.0.1', cli.httpbingo('api', params: { abc: 123 })

    # uncomment to raise Stubs::NotFound
    # assert_equal '127.0.0.1', cli.httpbingo('api', params: { abc: 123, foo: 'Kappa' })
    stubs.verify_stubbed_calls
  end

  def test_non_default_params_encoder
    stubs = Faraday::Adapter::Test::Stubs.new(strict_mode: true)
    stubs.get('/api?a=x&a=y&a=z') do
      [
        200,
        { 'Content-Type': 'application/javascript' },
        '{"origin": "127.0.0.1"}'
      ]
    end
    conn = Faraday.new(request: { params_encoder: Faraday::FlatParamsEncoder }) do |builder|
      builder.adapter :test, stubs
    end

    cli = Client.new(conn)
    assert_equal '127.0.0.1', cli.httpbingo('api', params: { a: %w[x y z] })

    # uncomment to raise Stubs::NotFound
    # assert_equal '127.0.0.1', cli.httpbingo('api', params: { a: %w[x y] })
    stubs.verify_stubbed_calls
  end

  def test_with_string_body
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/foo', '{"name":"YK"}') { [200, {}, ''] }
    end
    cli = client(stubs)
    assert_equal 200, cli.foo(name: 'YK')

    stubs.verify_stubbed_calls
  end

  def test_with_proc_body
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      check = ->(request_body) { JSON.parse(request_body).slice('name') == { 'name' => 'YK' } }
      stub.post('/foo', check) { [200, {}, ''] }
    end
    cli = client(stubs)
    assert_equal 200, cli.foo(name: 'YK', created_at: Time.now)

    stubs.verify_stubbed_calls
  end

  def client(stubs)
    conn = Faraday.new do |builder|
      builder.adapter :test, stubs
    end
    Client.new(conn)
  end
end
