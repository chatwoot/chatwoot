require 'erb'
require 'yaml'

module Koala
  module MockHTTPService
    include Koala::HTTPService

    # Mocks all HTTP requests for with koala_spec_with_mocks.rb
    # Mocked values to be included in TEST_DATA used in specs
    ACCESS_TOKEN = '*'
    APP_ACCESS_TOKEN = "********************"
    OAUTH_CODE = 'OAUTHCODE'

    # Loads testing data
    TEST_DATA = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'fixtures', 'facebook_data.yml'))
    TEST_DATA.merge!('oauth_token' => Koala::MockHTTPService::ACCESS_TOKEN)
    TEST_DATA['oauth_test_data'].merge!('code' => Koala::MockHTTPService::OAUTH_CODE)
    TEST_DATA['search_time'] = (Time.now - 3600).to_s

    # Useful in mock_facebook_responses.yml
    OAUTH_DATA = TEST_DATA['oauth_test_data']
    OAUTH_DATA.merge!({
      'app_access_token' => APP_ACCESS_TOKEN,
      'session_key' => "session_key",
      'multiple_session_keys' => ["session_key", "session_key_2"]
    })
    APP_ID = OAUTH_DATA['app_id']
    SECRET = OAUTH_DATA['secret']
    SUBSCRIPTION_DATA = TEST_DATA["subscription_test_data"]

    # Loads the mock response data via ERB to substitue values for TEST_DATA (see oauth/access_token)
    mock_response_file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'mock_facebook_responses.yml')
    RESPONSES = YAML.safe_load(ERB.new(IO.read(mock_response_file_path)).result(binding), [], [], true)

    def self.make_request(request)
      if response = match_response(request.raw_path, request.raw_args, request.raw_verb, request.raw_options)
        # create response class object
        response_object = if response.is_a? String
          Koala::HTTPService::Response.new(200, response, {})
        else
          Koala::HTTPService::Response.new(response["code"] || 200, response["body"] || "", response["headers"] || {})
        end
      else
        # Raises an error message with the place in the data YML
        # to place a mock as well as a URL to request from
        # Facebook's servers for the actual data
        # (Don't forget to replace ACCESS_TOKEN with a real access token)
        data_trace = [request.raw_path, request.raw_args, request.raw_verb, request.raw_options] * ': '

        args = request.raw_args == 'no_args' ? '' : "#{request.raw_args}&"
        args += 'format=json'

        raise "Missing a mock response for #{data_trace}\nAPI PATH: #{[request.path, request.raw_args].join('?')}"
      end

      response_object
    end

    def self.encode_params(*args)
      # use HTTPService's encode_params
      HTTPService.encode_params(*args)
    end

    protected

    # For a given query, see if our mock responses YAML has a resopnse for it.
    def self.match_response(path, args, verb, options = {})
      server = 'graph_api'
      path = 'root' if path == '' || path == '/'
      verb = (verb || 'get').to_s
      token = args.delete('access_token')
      with_token = (token == ACCESS_TOKEN || token == APP_ACCESS_TOKEN) ? 'with_token' : 'no_token'

      if endpoint = RESPONSES[server][path]
        # see if we have a match for the arguments
        if arg_match = endpoint.find {|query, v| decode_query(query) == massage_args(args)}
          # we have a match for the server/path/arguments
          # so if it's the right verb and authentication, we're good
          # arg_match will be [query, hash_response]
          arg_match.last[verb][with_token]
        end
      end
    end

    # Since we're comparing the arguments with data in a yaml file, we need to
    # massage them slightly to get to the format we expect.
    def self.massage_args(arguments)
      args = arguments.inject({}) do |hash, (k, v)|
        # ensure our args are all stringified
        value = if v.is_a?(String)
          should_json_decode?(v) ? JSON.parse(v) : v
        elsif v.is_a?(Koala::HTTPService::UploadableIO)
          # obviously there are no files in the yaml
          "[FILE]"
        else
          v
        end
        # make sure all keys are strings
        hash.merge(k.to_s => value)
      end

      # Assume format is always JSON
      args.delete('format')

      # if there are no args, return the special keyword no_args
      args.empty? ? "no_args" : args
    end

    # Facebook sometimes requires us to encode JSON values in an HTTP query
    # param. This complicates test matches, since we get into JSON-encoding
    # issues (what order keys are written into).  To avoid string comparisons
    # and the hacks required to make it work, we decode the query into a
    # Ruby object.
    def self.decode_query(string)
      if string == "no_args"
        string
      else
        # we can't use Faraday's decode_query because that CGI-unencodes, which
        # will remove +'s in restriction strings
        string.split("&").reduce({}) do |hash, component|
          k, v = component.split("=", 2) # we only care about the first =
          value = should_json_decode?(v) ? JSON.parse(v) : v.to_s rescue v.to_s
          # some special-casing, unfortunate but acceptable in this testing
          # environment
          value = nil if value.empty?
          value = true if value == "true"
          value = false if value == "false"
          hash.merge(k => value)
        end
      end
    end

    # We want to decode JSON because it may not be encoded in the same order
    # all the time -- different Rubies may create a strings with equivalent
    # content but different order.  We want to compare the objects.
    def self.should_json_decode?(v)
      v.match(/^[\[\{]/)
    end
  end
end
