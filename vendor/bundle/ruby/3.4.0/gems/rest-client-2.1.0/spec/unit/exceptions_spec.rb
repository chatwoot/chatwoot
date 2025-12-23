require_relative '_lib'

describe RestClient::Exception do
  it "returns a 'message' equal to the class name if the message is not set, because 'message' should not be nil" do
    e = RestClient::Exception.new
    expect(e.message).to eq "RestClient::Exception"
  end

  it "returns the 'message' that was set" do
    e = RestClient::Exception.new
    message = "An explicitly set message"
    e.message = message
    expect(e.message).to eq message
  end

  it "sets the exception message to ErrorMessage" do
    expect(RestClient::ResourceNotFound.new.message).to eq 'Not Found'
  end

  it "contains exceptions in RestClient" do
    expect(RestClient::Unauthorized.new).to be_a_kind_of(RestClient::Exception)
    expect(RestClient::ServerBrokeConnection.new).to be_a_kind_of(RestClient::Exception)
  end
end

describe RestClient::ServerBrokeConnection do
  it "should have a default message of 'Server broke connection'" do
    e = RestClient::ServerBrokeConnection.new
    expect(e.message).to eq 'Server broke connection'
  end
end

describe RestClient::RequestFailed do
  before do
    @response = double('HTTP Response', :code => '502')
  end

  it "stores the http response on the exception" do
    response = "response"
    begin
      raise RestClient::RequestFailed, response
    rescue RestClient::RequestFailed => e
      expect(e.response).to eq response
    end
  end

  it "http_code convenience method for fetching the code as an integer" do
    expect(RestClient::RequestFailed.new(@response).http_code).to eq 502
  end

  it "http_body convenience method for fetching the body (decoding when necessary)" do
    expect(RestClient::RequestFailed.new(@response).http_code).to eq 502
    expect(RestClient::RequestFailed.new(@response).message).to eq 'HTTP status code 502'
  end

  it "shows the status code in the message" do
    expect(RestClient::RequestFailed.new(@response).to_s).to match(/502/)
  end
end

describe RestClient::ResourceNotFound do
  it "also has the http response attached" do
    response = "response"
    begin
      raise RestClient::ResourceNotFound, response
    rescue RestClient::ResourceNotFound => e
      expect(e.response).to eq response
    end
  end

  it 'stores the body on the response of the exception' do
    body = "body"
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 404)
    begin
      RestClient.get "www.example.com"
      raise
    rescue RestClient::ResourceNotFound => e
      expect(e.response.body).to eq body
    end
  end
end

describe "backwards compatibility" do
  it 'aliases RestClient::NotFound as ResourceNotFound' do
    expect(RestClient::ResourceNotFound).to eq RestClient::NotFound
  end

  it 'aliases old names for HTTP 413, 414, 416' do
    expect(RestClient::RequestEntityTooLarge).to eq RestClient::PayloadTooLarge
    expect(RestClient::RequestURITooLong).to eq RestClient::URITooLong
    expect(RestClient::RequestedRangeNotSatisfiable).to eq RestClient::RangeNotSatisfiable
  end

  it 'subclasses NotFound from RequestFailed, ExceptionWithResponse' do
    expect(RestClient::NotFound).to be < RestClient::RequestFailed
    expect(RestClient::NotFound).to be < RestClient::ExceptionWithResponse
  end

  it 'subclasses timeout from RestClient::RequestTimeout, RequestFailed, EWR' do
    expect(RestClient::Exceptions::OpenTimeout).to be < RestClient::Exceptions::Timeout
    expect(RestClient::Exceptions::ReadTimeout).to be < RestClient::Exceptions::Timeout

    expect(RestClient::Exceptions::Timeout).to be < RestClient::RequestTimeout
    expect(RestClient::Exceptions::Timeout).to be < RestClient::RequestFailed
    expect(RestClient::Exceptions::Timeout).to be < RestClient::ExceptionWithResponse
  end

end
