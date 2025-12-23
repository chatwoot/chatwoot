require 'spec_helper'

describe Koala do
  it "has an http_service accessor" do
    expect(Koala).to respond_to(:http_service)
    expect(Koala).to respond_to(:http_service=)
  end

  describe "constants" do
    it "has a version" do
      expect(Koala.const_defined?("VERSION")).to be_truthy
    end
  end

  describe "make_request" do
    it "passes all its arguments to the http_service" do
      path = "foo"
      args = {:a => 2}
      verb = "get"
      options = {:c => :d}

      expect(Koala.http_service).to receive(:make_request) do |request|
        expect(request.raw_path).to eq(path)
        expect(request.raw_args).to eq(args)
        expect(request.raw_verb).to eq(verb)
        expect(request.raw_options).to eq(options)
      end
      Koala.make_request(path, args, verb, options)
    end
  end

  describe ".configure" do
    it "yields a configurable object" do
      Koala.configure {|c| expect(c).to be_a(Koala::Configuration)}
    end

    it "caches the config (singleton)" do
      c = Koala.config
      expect(c.object_id).to eq(Koala.config.object_id)
    end
  end

  describe ".config" do
    it "exposes the basic configuration" do
      Koala::HTTPService::DEFAULT_SERVERS.each_pair do |k, v|
        expect(Koala.config.send(k)).to eq(v)
      end
    end

    it "exposes the values configured" do
      Koala.configure do |config|
        config.graph_server = "some-new.graph_server.com"
      end
      expect(Koala.config.graph_server).to eq("some-new.graph_server.com")
    end
  end
end
