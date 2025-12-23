require 'uri'

module Helpers

  # @param [Hash] opts A hash of methods, passed directly to the double
  #   definition. Use this to stub other required methods.
  #
  # @return double for Net::HTTPResponse
  def res_double(opts={})
    instance_double('Net::HTTPResponse', {to_hash: {}, body: 'response body'}.merge(opts))
  end

  # Given a Net::HTTPResponse or double and a Request or double, create a
  # RestClient::Response object.
  #
  # @param net_http_res_double an rspec double for Net::HTTPResponse
  # @param request A RestClient::Request or rspec double
  #
  # @return [RestClient::Response]
  #
  def response_from_res_double(net_http_res_double, request=nil, duration: 1)
    request ||= request_double()
    start_time = Time.now - duration

    response = RestClient::Response.create(net_http_res_double.body, net_http_res_double, request, start_time)

    # mock duration to ensure it gets the value we expect
    allow(response).to receive(:duration).and_return(duration)

    response
  end

  # Redirect stderr to a string for the duration of the passed block.
  def fake_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end

  # Create a double for RestClient::Request
  def request_double(url: 'http://example.com', method: 'get')
    instance_double('RestClient::Request',
      url: url, uri: URI.parse(url), method: method, user: nil, password: nil,
      cookie_jar: HTTP::CookieJar.new, redirection_history: nil,
      args: {url: url, method: method})
  end

  def test_image_path
    File.dirname(__FILE__) + "/ISS.jpg"
  end
end
