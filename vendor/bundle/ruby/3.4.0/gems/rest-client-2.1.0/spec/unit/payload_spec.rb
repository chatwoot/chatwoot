# encoding: binary

require_relative '_lib'

describe RestClient::Payload, :include_helpers do
  context "Base Payload" do
    it "should reset stream after to_s" do
      payload = RestClient::Payload::Base.new('foobar')
      expect(payload.to_s).to eq 'foobar'
      expect(payload.to_s).to eq 'foobar'
    end
  end

  context "A regular Payload" do
    it "should use standard enctype as default content-type" do
      expect(RestClient::Payload::UrlEncoded.new({}).headers['Content-Type']).
        to eq 'application/x-www-form-urlencoded'
    end

    it "should form properly encoded params" do
      expect(RestClient::Payload::UrlEncoded.new({:foo => 'bar'}).to_s).
        to eq "foo=bar"
      expect(["foo=bar&baz=qux", "baz=qux&foo=bar"]).to include(
                                                        RestClient::Payload::UrlEncoded.new({:foo => 'bar', :baz => 'qux'}).to_s)
    end

    it "should escape parameters" do
      expect(RestClient::Payload::UrlEncoded.new({'foo + bar' => 'baz'}).to_s).
        to eq "foo+%2B+bar=baz"
    end

    it "should properly handle hashes as parameter" do
      expect(RestClient::Payload::UrlEncoded.new({:foo => {:bar => 'baz'}}).to_s).
        to eq "foo[bar]=baz"
      expect(RestClient::Payload::UrlEncoded.new({:foo => {:bar => {:baz => 'qux'}}}).to_s).
        to eq "foo[bar][baz]=qux"
    end

    it "should handle many attributes inside a hash" do
      parameters = RestClient::Payload::UrlEncoded.new({:foo => {:bar => 'baz', :baz => 'qux'}}).to_s
      expect(parameters).to eq 'foo[bar]=baz&foo[baz]=qux'
    end

    it "should handle attributes inside an array inside an hash" do
      parameters = RestClient::Payload::UrlEncoded.new({"foo" => [{"bar" => 'baz'}, {"bar" => 'qux'}]}).to_s
      expect(parameters).to eq 'foo[][bar]=baz&foo[][bar]=qux'
    end

    it "should handle arrays inside a hash inside a hash" do
      parameters = RestClient::Payload::UrlEncoded.new({"foo" => {'even' => [0, 2], 'odd' => [1, 3]}}).to_s
      expect(parameters).to eq 'foo[even][]=0&foo[even][]=2&foo[odd][]=1&foo[odd][]=3'
    end

    it "should form properly use symbols as parameters" do
      expect(RestClient::Payload::UrlEncoded.new({:foo => :bar}).to_s).
        to eq "foo=bar"
      expect(RestClient::Payload::UrlEncoded.new({:foo => {:bar => :baz}}).to_s).
        to eq "foo[bar]=baz"
    end

    it "should properly handle arrays as repeated parameters" do
      expect(RestClient::Payload::UrlEncoded.new({:foo => ['bar']}).to_s).
        to eq "foo[]=bar"
      expect(RestClient::Payload::UrlEncoded.new({:foo => ['bar', 'baz']}).to_s).
        to eq "foo[]=bar&foo[]=baz"
    end

    it 'should not close if stream already closed' do
      p = RestClient::Payload::UrlEncoded.new({'foo ' => 'bar'})
      3.times {p.close}
    end

  end

  context "A multipart Payload" do
    it "should use standard enctype as default content-type" do
      m = RestClient::Payload::Multipart.new({})
      allow(m).to receive(:boundary).and_return(123)
      expect(m.headers['Content-Type']).to eq 'multipart/form-data; boundary=123'
    end

    it 'should not error on close if stream already closed' do
      m = RestClient::Payload::Multipart.new(:file => File.new(test_image_path))
      3.times {m.close}
    end

    it "should form properly separated multipart data" do
      m = RestClient::Payload::Multipart.new([[:bar, "baz"], [:foo, "bar"]])
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; name="bar"\r
\r
baz\r
--#{m.boundary}\r
Content-Disposition: form-data; name="foo"\r
\r
bar\r
--#{m.boundary}--\r
      EOS
    end

    it "should not escape parameters names" do
      m = RestClient::Payload::Multipart.new([["bar ", "baz"]])
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; name="bar "\r
\r
baz\r
--#{m.boundary}--\r
      EOS
    end

    it "should form properly separated multipart data" do
      f = File.new(test_image_path)
      m = RestClient::Payload::Multipart.new({:foo => f})
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; name="foo"; filename="ISS.jpg"\r
Content-Type: image/jpeg\r
\r
#{File.open(f.path, 'rb'){|bin| bin.read}}\r
--#{m.boundary}--\r
      EOS
    end

    it "should ignore the name attribute when it's not set" do
      f = File.new(test_image_path)
      m = RestClient::Payload::Multipart.new({nil => f})
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; filename="ISS.jpg"\r
Content-Type: image/jpeg\r
\r
#{File.open(f.path, 'rb'){|bin| bin.read}}\r
--#{m.boundary}--\r
      EOS
    end

    it "should detect optional (original) content type and filename" do
      f = File.new(test_image_path)
      expect(f).to receive(:content_type).and_return('text/plain')
      expect(f).to receive(:original_filename).and_return('foo.txt')
      m = RestClient::Payload::Multipart.new({:foo => f})
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; name="foo"; filename="foo.txt"\r
Content-Type: text/plain\r
\r
#{File.open(f.path, 'rb'){|bin| bin.read}}\r
--#{m.boundary}--\r
      EOS
    end

    it "should handle hash in hash parameters" do
      m = RestClient::Payload::Multipart.new({:bar => {:baz => "foo"}})
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; name="bar[baz]"\r
\r
foo\r
--#{m.boundary}--\r
      EOS

      f = File.new(test_image_path)
      f.instance_eval "def content_type; 'text/plain'; end"
      f.instance_eval "def original_filename; 'foo.txt'; end"
      m = RestClient::Payload::Multipart.new({:foo => {:bar => f}})
      expect(m.to_s).to eq <<-EOS
--#{m.boundary}\r
Content-Disposition: form-data; name="foo[bar]"; filename="foo.txt"\r
Content-Type: text/plain\r
\r
#{File.open(f.path, 'rb'){|bin| bin.read}}\r
--#{m.boundary}--\r
      EOS
    end

    it 'should correctly format hex boundary' do
      allow(SecureRandom).to receive(:base64).with(12).and_return('TGs89+ttw/xna6TV')
      f = File.new(test_image_path)
      m = RestClient::Payload::Multipart.new({:foo => f})
      expect(m.boundary).to eq('-' * 4 + 'RubyFormBoundary' + 'TGs89AttwBxna6TV')
    end

  end

  context "streamed payloads" do
    it "should properly determine the size of file payloads" do
      f = File.new(test_image_path)
      payload = RestClient::Payload.generate(f)
      expect(payload.size).to eq 72_463
      expect(payload.length).to eq 72_463
    end

    it "should properly determine the size of other kinds of streaming payloads" do
      s = StringIO.new 'foo'
      payload = RestClient::Payload.generate(s)
      expect(payload.size).to eq 3
      expect(payload.length).to eq 3

      begin
        f = Tempfile.new "rest-client"
        f.write 'foo bar'

        payload = RestClient::Payload.generate(f)
        expect(payload.size).to eq 7
        expect(payload.length).to eq 7
      ensure
        f.close
      end
    end

    it "should have a closed? method" do
      f = File.new(test_image_path)
      payload = RestClient::Payload.generate(f)
      expect(payload.closed?).to be_falsey
      payload.close
      expect(payload.closed?).to be_truthy
    end
  end

  context "Payload generation" do
    it "should recognize standard urlencoded params" do
      expect(RestClient::Payload.generate({"foo" => 'bar'})).to be_kind_of(RestClient::Payload::UrlEncoded)
    end

    it "should recognize multipart params" do
      f = File.new(test_image_path)
      expect(RestClient::Payload.generate({"foo" => f})).to be_kind_of(RestClient::Payload::Multipart)
    end

    it "should be multipart if forced" do
      expect(RestClient::Payload.generate({"foo" => "bar", :multipart => true})).to be_kind_of(RestClient::Payload::Multipart)
    end

    it "should handle deeply nested multipart" do
      f = File.new(test_image_path)
      params = {foo: RestClient::ParamsArray.new({nested: f})}
      expect(RestClient::Payload.generate(params)).to be_kind_of(RestClient::Payload::Multipart)
    end


    it "should return data if no of the above" do
      expect(RestClient::Payload.generate("data")).to be_kind_of(RestClient::Payload::Base)
    end

    it "should recognize nested multipart payloads in hashes" do
      f = File.new(test_image_path)
      expect(RestClient::Payload.generate({"foo" => {"file" => f}})).to be_kind_of(RestClient::Payload::Multipart)
    end

    it "should recognize nested multipart payloads in arrays" do
      f = File.new(test_image_path)
      expect(RestClient::Payload.generate({"foo" => [f]})).to be_kind_of(RestClient::Payload::Multipart)
    end

    it "should recognize file payloads that can be streamed" do
      f = File.new(test_image_path)
      expect(RestClient::Payload.generate(f)).to be_kind_of(RestClient::Payload::Streamed)
    end

    it "should recognize other payloads that can be streamed" do
      expect(RestClient::Payload.generate(StringIO.new('foo'))).to be_kind_of(RestClient::Payload::Streamed)
    end

    # hashery gem introduces Hash#read convenience method. Existence of #read method used to determine of content is streameable :/
    it "shouldn't treat hashes as streameable" do
      expect(RestClient::Payload.generate({"foo" => 'bar'})).to be_kind_of(RestClient::Payload::UrlEncoded)
    end

    it "should recognize multipart payload wrapped in ParamsArray" do
      f = File.new(test_image_path)
      params = RestClient::ParamsArray.new([[:image, f]])
      expect(RestClient::Payload.generate(params)).to be_kind_of(RestClient::Payload::Multipart)
    end

    it "should handle non-multipart payload wrapped in ParamsArray" do
      params = RestClient::ParamsArray.new([[:arg, 'value1'], [:arg, 'value2']])
      expect(RestClient::Payload.generate(params)).to be_kind_of(RestClient::Payload::UrlEncoded)
    end

    it "should pass through Payload::Base and subclasses unchanged" do
      payloads = [
        RestClient::Payload::Base.new('foobar'),
        RestClient::Payload::UrlEncoded.new({:foo => 'bar'}),
        RestClient::Payload::Streamed.new(File.new(test_image_path)),
        RestClient::Payload::Multipart.new({myfile: File.new(test_image_path)}),
      ]

      payloads.each do |payload|
        expect(RestClient::Payload.generate(payload)).to equal(payload)
      end
    end
  end
end
