require_relative '_lib'

describe RestClient::Request, :include_helpers do

  context 'params for GET requests' do
    it "manage params for get requests" do
      stub_request(:get, 'http://some/resource?a=b&c=d').with(:headers => {'Accept'=>'*/*', 'Foo'=>'bar'}).to_return(:body => 'foo', :status => 200)
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get, :headers => {:foo => :bar, :params => {:a => :b, 'c' => 'd'}}).body).to eq 'foo'

      stub_request(:get, 'http://some/resource').with(:headers => {'Accept'=>'*/*', 'Foo'=>'bar'}).to_return(:body => 'foo', :status => 200)
      expect(RestClient::Request.execute(:url => 'http://some/resource', :method => :get, :headers => {:foo => :bar, :params => :a}).body).to eq 'foo'
    end

    it 'adds GET params when params are present in URL' do
      stub_request(:get, 'http://some/resource?a=b&c=d').with(:headers => {'Accept'=>'*/*', 'Foo'=>'bar'}).to_return(:body => 'foo', :status => 200)
      expect(RestClient::Request.execute(:url => 'http://some/resource?a=b', :method => :get, :headers => {:foo => :bar, :params => {:c => 'd'}}).body).to eq 'foo'
    end

    it 'encodes nested GET params' do
      stub_request(:get, 'http://some/resource?a[foo][]=1&a[foo][]=2&a[bar]&b=foo+bar&math=2+%2B+2+%3D%3D+4').with(:headers => {'Accept'=>'*/*',}).to_return(:body => 'foo', :status => 200)
      expect(RestClient::Request.execute(url: 'http://some/resource', method: :get, headers: {
        params: {
          a: {
            foo: [1,2],
            bar: nil,
          },
          b: 'foo bar',
          math: '2 + 2 == 4',
        }
      }).body).to eq 'foo'
    end

  end

  it "can use a block to process response" do
    response_value = nil
    block = proc do |http_response|
      response_value = http_response.body
    end
    stub_request(:get, 'http://some/resource?a=b&c=d').with(:headers => {'Accept'=>'*/*', 'Foo'=>'bar'}).to_return(:body => 'foo', :status => 200)
    RestClient::Request.execute(:url => 'http://some/resource', :method => :get, :headers => {:foo => :bar, :params => {:a => :b, 'c' => 'd'}}, :block_response => block)
    expect(response_value).to eq "foo"
  end

  it 'closes payload if not nil' do
    test_file = File.new(test_image_path)

    stub_request(:post, 'http://some/resource').with(:headers => {'Accept'=>'*/*'}).to_return(:body => 'foo', :status => 200)
    RestClient::Request.execute(:url => 'http://some/resource', :method => :post, :payload => {:file => test_file})

    expect(test_file.closed?).to be true
  end

end
