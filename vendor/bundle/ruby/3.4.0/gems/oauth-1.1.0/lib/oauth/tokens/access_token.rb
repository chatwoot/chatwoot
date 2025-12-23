# frozen_string_literal: true

module OAuth
  # The Access Token is used for the actual "real" web service calls that you perform against the server
  class AccessToken < ConsumerToken
    # The less intrusive way. Otherwise, if we are to do it correctly inside consumer,
    # we need to restructure and touch more methods: request(), sign!(), etc.
    def request(http_method, path, *arguments)
      request_uri = URI.parse(path)
      site_uri = consumer.uri
      is_service_uri_different = (request_uri.absolute? && request_uri != site_uri)
      begin
        consumer.uri(request_uri) if is_service_uri_different
        @response = super(http_method, path, *arguments)
      ensure
        # NOTE: reset for wholesomeness? meaning that we admit only AccessToken service calls may use different URIs?
        # so reset in case consumer is still used for other token-management tasks subsequently?
        consumer.uri(site_uri) if is_service_uri_different
      end
      @response
    end

    # Make a regular GET request using AccessToken
    #
    #   @response = @token.get('/people')
    #   @response = @token.get('/people', { 'Accept'=>'application/xml' })
    #
    def get(path, headers = {})
      request(:get, path, headers)
    end

    # Make a regular HEAD request using AccessToken
    #
    #   @response = @token.head('/people')
    #
    def head(path, headers = {})
      request(:head, path, headers)
    end

    # Make a regular POST request using AccessToken
    #
    #   @response = @token.post('/people')
    #   @response = @token.post('/people', { :name => 'Bob', :email => 'bob@mailinator.com' })
    #   @response = @token.post('/people', { :name => 'Bob', :email => 'bob@mailinator.com' }, { 'Accept' => 'application/xml' })
    #   @response = @token.post('/people', nil, {'Accept' => 'application/xml' })
    #   @response = @token.post('/people', @person.to_xml, { 'Accept'=>'application/xml', 'Content-Type' => 'application/xml' })
    #
    def post(path, body = "", headers = {})
      request(:post, path, body, headers)
    end

    # Make a regular PUT request using AccessToken
    #
    #   @response = @token.put('/people/123')
    #   @response = @token.put('/people/123', { :name => 'Bob', :email => 'bob@mailinator.com' })
    #   @response = @token.put('/people/123', { :name => 'Bob', :email => 'bob@mailinator.com' }, { 'Accept' => 'application/xml' })
    #   @response = @token.put('/people/123', nil, { 'Accept' => 'application/xml' })
    #   @response = @token.put('/people/123', @person.to_xml, { 'Accept' => 'application/xml', 'Content-Type' => 'application/xml' })
    #
    def put(path, body = "", headers = {})
      request(:put, path, body, headers)
    end

    # Make a regular PATCH request using AccessToken
    #
    #   @response = @token.patch('/people/123')
    #   @response = @token.patch('/people/123', { :name => 'Bob', :email => 'bob@mailinator.com' })
    #   @response = @token.patch('/people/123', { :name => 'Bob', :email => 'bob@mailinator.com' }, { 'Accept' => 'application/xml' })
    #   @response = @token.patch('/people/123', nil, { 'Accept' => 'application/xml' })
    #   @response = @token.patch('/people/123', @person.to_xml, { 'Accept' => 'application/xml', 'Content-Type' => 'application/xml' })
    #
    def patch(path, body = "", headers = {})
      request(:patch, path, body, headers)
    end

    # Make a regular DELETE request using AccessToken
    #
    #   @response = @token.delete('/people/123')
    #   @response = @token.delete('/people/123', { 'Accept' => 'application/xml' })
    #
    def delete(path, headers = {})
      request(:delete, path, headers)
    end
  end
end
