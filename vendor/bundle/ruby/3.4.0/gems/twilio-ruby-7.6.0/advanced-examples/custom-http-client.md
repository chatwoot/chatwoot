# Custom HTTP Clients for the Twilio Ruby Helper Library

If you are working with the Twilio Ruby Helper Library, and you need to be able to modify the HTTP requests that the library makes to the Twilio servers, you’re in the right place. The most common need to alter the HTTP request is to connect and authenticate with an enterprise’s proxy server. We’ll provide sample code that you can drop right into your app to handle this use case.

Connect and authenticate with a proxy server
To connect and provide credentials to a proxy server that may be between your app and Twilio, you need a way to modify the HTTP requests that the Twilio helper library makes on your behalf to invoke the Twilio REST API.

The Twilio Ruby helper library uses the [Faraday](https://rubygems.org/gems/faraday) gem under the hood to make the HTTP requests. The following example shows a typical request, without a custom `http_client`:

```rb
@client = Twilio::REST::Client.new(account_sid, auth_token)

message = @client.messages
  .create(
    to: "+15558675310",
    body: "Hey there!",
    from: "+15017122661",
  )
```

Out of the box, the helper library is creating a default `Twilio::Http::Client` for you, using the Twilio credentials you provide. However, you can create your own `Twilio::Http::Client`, and pass it to any Twilio REST API resource action you want.

Here’s an example of sending an SMS message with a custom client:

```rb
# Download the helper library from https://www.twilio.com/docs/ruby/install
require "rubygems"
require "twilio-ruby"
require "dotenv/load"

# Custom HTTP Client
require_relative "MyRequestClass"

# Your Account Sid and Auth Token from twilio.com/console
account_sid = ENV["ACCOUNT_SID"]
auth_token = ENV["AUTH_TOKEN"]
proxy_address = ENV["PROXY_ADDRESS"]
proxy_protocol = ENV["PROXY_PROTOCOL"]
proxy_port = ENV["PROXY_PORT"]

my_request_client = MyRequestClass.new(proxy_protocol, proxy_address, proxy_port)

@client = Twilio::REST::Client.new(account_sid, auth_token,
                                   nil, nil, my_request_client)

message = @client.messages
  .create(
    to: "+593978613041",
    body: "RB This is the ship that made the Kesssssel Run in fourteen parsecs?",
    from: "+13212855389",
  )

puts "Message SID: #{message.sid}"
```

## Create your custom TwilioRestClient

When you take a closer look at the constructor for `Twilio::Http::Client`, you see that this class provides it to the Twilio helper library to make the necessary HTTP requests.

## Call Twilio through the proxy server

Now that we understand how all the components fit together, we can create our own `http_client` that can connect through a proxy server. To make this reusable, here’s a class that you can use to create this `http_client` whenever you need one.

```rb
class MyRequestClass
  attr_accessor :adapter
  attr_reader :timeout, :last_response, :last_request

  def initialize(proxy_prot = nil, proxy_addr = nil, proxy_port = nil, timeout: nil)
    @proxy_prot = proxy_prot
    @proxy_addr = proxy_addr
    @proxy_port = proxy_port
    @timeout = timeout
    @adapter = Faraday.default_adapter
  end

  def _request(request)
    @connection = Faraday.new(url: request.host + ":" + request.port.to_s, ssl: { verify: true }) do |f|
      f.options.params_encoder = Faraday::FlatParamsEncoder
      f.request :url_encoded
      f.adapter @adapter
      f.headers = request.headers
      f.basic_auth(request.auth[0], request.auth[1])
      if @proxy_addr
        f.proxy = "#{@proxy_prot}://#{@proxy_addr}:#{@proxy_port}"
      end
      f.options.open_timeout = request.timeout || @timeout
      f.options.timeout = request.timeout || @timeout
    end

    @last_request = request
    @last_response = nil
    response = @connection.send(request.method.downcase.to_sym,
                                request.url,
                                request.method == "GET" ? request.params : request.data)

    if response.body && !response.body.empty?
      object = response.body
    elsif response.status == 400
      object = { message: "Bad request", code: 400 }.to_json
    end

    twilio_response = Twilio::Response.new(response.status, object, headers: response.headers)
    @last_response = twilio_response

    twilio_response
  end

  def request(host, port, method, url, params = {}, data = {}, headers = {}, auth = nil, timeout = nil)
    request = Twilio::Request.new(host, port, method, url, params, data, headers, auth, timeout)
    _request(request)
  end
end
```

In this example, we are using some environment variables loaded at the program startup to retrieve various configuration settings:

- Your Twilio Account Sid and Auth Token ([found here, in the Twilio console](https://console.twilio.com))
- A proxy address in the form of `http://127.0.0.1:8888`

These settings are located in a file like `.env` like so:

```env
ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AUTH_TOKEN= your_auth_token

HTTPS_PROXY=https://127.0.0.1:8888
HTTP_PROXY=http://127.0.0.1:8888
```

Here’s the full console program that sends a text message and shows how it all can work together. It loads the `.env` file.

```rb
# Download the helper library from https://www.twilio.com/docs/ruby/install
require "rubygems"
require "twilio-ruby"
require "dotenv/load"

# Custom HTTP Client
require_relative "MyRequestClass"

# Your Account Sid and Auth Token from twilio.com/console
account_sid = ENV["ACCOUNT_SID"]
auth_token = ENV["AUTH_TOKEN"]
proxy_address = ENV["PROXY_ADDRESS"]
proxy_protocol = ENV["PROXY_PROTOCOL"]
proxy_port = ENV["PROXY_PORT"]

my_request_client = MyRequestClass.new(proxy_protocol, proxy_address, proxy_port)

@client = Twilio::REST::Client.new(account_sid, auth_token,
                                   nil, nil, my_request_client)

message = @client.messages
  .create(
    to: "+593978613041",
    body: "RB This is the ship that made the Kesssssel Run in fourteen parsecs?",
    from: "+13212855389",
  )

puts "Message SID: #{message.sid}"
```

## What else can this technique be used for?

Now that you know how to inject your own `http_client` into the Twilio API request pipeline, you could use this technique to add custom HTTP headers and authorization to the requests (perhaps as required by an upstream proxy server).

You could also implement your own `http_client` to mock the Twilio API responses so your unit and integration tests can run quickly without the need to make a connection to Twilio. In fact, there’s already an example online showing [how to do exactly that with Node.js and Prism](https://www.twilio.com/docs/openapi/mock-api-generation-with-twilio-openapi-spec).

We can’t wait to see what you build!
