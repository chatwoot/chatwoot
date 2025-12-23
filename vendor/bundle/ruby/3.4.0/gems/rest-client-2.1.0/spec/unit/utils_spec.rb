require_relative '_lib'

describe RestClient::Utils do
  describe '.get_encoding_from_headers' do
    it 'assumes no encoding by default for text' do
      headers = {:content_type => 'text/plain'}
      expect(RestClient::Utils.get_encoding_from_headers(headers)).
        to eq nil
    end

    it 'returns nil on failures' do
      expect(RestClient::Utils.get_encoding_from_headers(
        {:content_type => 'blah'})).to eq nil
      expect(RestClient::Utils.get_encoding_from_headers(
        {})).to eq nil
      expect(RestClient::Utils.get_encoding_from_headers(
        {:content_type => 'foo; bar=baz'})).to eq nil
    end

    it 'handles various charsets' do
      expect(RestClient::Utils.get_encoding_from_headers(
        {:content_type => 'text/plain; charset=UTF-8'})).to eq 'UTF-8'
      expect(RestClient::Utils.get_encoding_from_headers(
        {:content_type => 'application/json; charset=ISO-8859-1'})).
        to eq 'ISO-8859-1'
      expect(RestClient::Utils.get_encoding_from_headers(
        {:content_type => 'text/html; charset=windows-1251'})).
        to eq 'windows-1251'

      expect(RestClient::Utils.get_encoding_from_headers(
        {:content_type => 'text/html; charset="UTF-16"'})).
        to eq 'UTF-16'
    end
  end

  describe '.cgi_parse_header' do
    it 'parses headers', :unless => RUBY_VERSION.start_with?('2.0') do
      expect(RestClient::Utils.cgi_parse_header('text/plain')).
        to eq ['text/plain', {}]

      expect(RestClient::Utils.cgi_parse_header('text/vnd.just.made.this.up')).
        to eq ['text/vnd.just.made.this.up', {}]

      expect(RestClient::Utils.cgi_parse_header('text/plain;charset=us-ascii')).
        to eq ['text/plain', {'charset' => 'us-ascii'}]

      expect(RestClient::Utils.cgi_parse_header('text/plain ; charset="us-ascii"')).
        to eq ['text/plain', {'charset' => 'us-ascii'}]

      expect(RestClient::Utils.cgi_parse_header(
        'text/plain ; charset="us-ascii"; another=opt')).
        to eq ['text/plain', {'charset' => 'us-ascii', 'another' => 'opt'}]

      expect(RestClient::Utils.cgi_parse_header(
        'foo/bar; filename="silly.txt"')).
        to eq ['foo/bar', {'filename' => 'silly.txt'}]

      expect(RestClient::Utils.cgi_parse_header(
        'foo/bar; filename="strange;name"')).
        to eq ['foo/bar', {'filename' => 'strange;name'}]

      expect(RestClient::Utils.cgi_parse_header(
        'foo/bar; filename="strange;name";size=123')).to eq \
        ['foo/bar', {'filename' => 'strange;name', 'size' => '123'}]

      expect(RestClient::Utils.cgi_parse_header(
        'foo/bar; name="files"; filename="fo\\"o;bar"')).to eq \
        ['foo/bar', {'name' => 'files', 'filename' => 'fo"o;bar'}]
    end
  end

  describe '.encode_query_string' do
    it 'handles simple hashes' do
      {
        {foo: 123, bar: 456} => 'foo=123&bar=456',
        {'foo' => 123, 'bar' => 456} => 'foo=123&bar=456',
        {foo: 'abc', bar: 'one two'} => 'foo=abc&bar=one+two',
        {escaped: '1+2=3'} => 'escaped=1%2B2%3D3',
        {'escaped + key' => 'foo'} => 'escaped+%2B+key=foo',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles simple arrays' do
      {
        {foo: [1, 2, 3]} => 'foo[]=1&foo[]=2&foo[]=3',
        {foo: %w{a b c}, bar: [1, 2, 3]} => 'foo[]=a&foo[]=b&foo[]=c&bar[]=1&bar[]=2&bar[]=3',
        {foo: ['one two', 3]} => 'foo[]=one+two&foo[]=3',
        {'a+b' => [1,2,3]} => 'a%2Bb[]=1&a%2Bb[]=2&a%2Bb[]=3',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles nested hashes' do
      {
        {outer: {foo: 123, bar: 456}} => 'outer[foo]=123&outer[bar]=456',
        {outer: {foo: [1, 2, 3], bar: 'baz'}} => 'outer[foo][]=1&outer[foo][]=2&outer[foo][]=3&outer[bar]=baz',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles null and empty values' do
      {
        {string: '', empty: nil, list: [], hash: {}, falsey: false } =>
          'string=&empty&list&hash&falsey=false',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles nested nulls' do
      {
        {foo: {string: '', empty: nil}} => 'foo[string]=&foo[empty]',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles deep nesting' do
      {
        {coords: [{x: 1, y: 0}, {x: 2}, {x: 3}]} => 'coords[][x]=1&coords[][y]=0&coords[][x]=2&coords[][x]=3',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles multiple fields with the same name using ParamsArray' do
      {
        RestClient::ParamsArray.new([[:foo, 1], [:foo, 2], [:foo, 3]]) => 'foo=1&foo=2&foo=3',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end

    it 'handles nested ParamsArrays' do
      {
        {foo: RestClient::ParamsArray.new([[:a, 1], [:a, 2]])} => 'foo[a]=1&foo[a]=2',
        RestClient::ParamsArray.new([[:foo, {a: 1}], [:foo, {a: 2}]]) => 'foo[a]=1&foo[a]=2',
      }.each_pair do |input, expected|
        expect(RestClient::Utils.encode_query_string(input)).to eq expected
      end
    end
  end
end
