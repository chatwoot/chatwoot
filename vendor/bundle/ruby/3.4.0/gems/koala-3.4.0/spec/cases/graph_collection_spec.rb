require 'spec_helper'

describe Koala::Facebook::API::GraphCollection do
  let(:paging){ {"paging" => true} }

  before(:each) do
    @headers = {'Content-Type' => 'application/json'}
    @data = {
      "data" => [1, 2, 'three'],
      "paging" => paging,
      "summary" => [3]
    }
    @result = Koala::HTTPService::Response.new(200, @data.to_json, @headers)
    @api = Koala::Facebook::API.new("123")
    @collection = Koala::Facebook::API::GraphCollection.new(@result, @api)
  end

  it "subclasses Array" do
    expect(Koala::Facebook::API::GraphCollection.ancestors).to include(Array)
  end

  it "creates an array-like object" do
    expect(Koala::Facebook::API::GraphCollection.new(@result, @api)).to be_an(Array)
  end

  it "contains the result data" do
    @data["data"].each_with_index {|r, i| expect(@collection[i]).to eq(r)}
  end

  it "has a read-only paging attribute" do
    expect(@collection.methods.map(&:to_sym)).to include(:paging)
    expect(@collection.methods.map(&:to_sym)).not_to include(:paging=)
  end

  it "sets paging to results['paging']" do
    expect(@collection.paging).to eq(@data["paging"])
  end

  it "sets summary to results['summary']" do
    expect(@collection.summary).to eq(@data["summary"])
  end

  it "sets raw_response to the original results" do
    expect(@collection.raw_response).to eq(@result.data)
  end

  it "sets the API to the provided API" do
    expect(@collection.api).to eq(@api)
  end

  it "sets the headers correctly" do
    expect(@collection.headers).to eq(@headers)
  end

  describe "when getting a whole page" do
    before(:each) do
      @second_page = {
        "data" => ["second", "page", "data"],
        "paging" => {}
      }
      @base = double("base")
      @args = {"a" => 1}
      @page_of_results = double("page of results")
      @result = Koala::HTTPService::Response.new(200, @second_page.to_json, {})
      @result.data
    end

    it "should return the previous page of results" do
      expect(@collection).to receive(:previous_page_params).and_return([@base, @args])
      expect(@api).to receive(:api).with(@base, @args, anything, anything).and_return(@result)
      expect(Koala::Facebook::API::GraphCollection).to receive(:new).with(@result, @api).and_return(@page_of_results)
      expect(@collection.previous_page).to eq(@page_of_results)
    end

    it "should return the next page of results" do
      expect(@collection).to receive(:next_page_params).and_return([@base, @args])
      expect(@api).to receive(:api).with(@base, @args, anything, anything).and_return(@result)
      expect(Koala::Facebook::API::GraphCollection).to receive(:new).with(@result, @api).and_return(@page_of_results)

      expect(@collection.next_page).to eq(@page_of_results)
    end

    it "should return nil it there are no other pages" do
      %w{next previous}.each do |this|
        expect(@collection).to receive("#{this}_page_params".to_sym).and_return(nil)
        expect(@collection.send("#{this}_page")).to eq(nil)
      end
    end
  end

  describe "when parsing page paramters" do
    describe "#parse_page_url" do
      it "should pass the url to the class method" do
        url = double("url")
        expect(Koala::Facebook::API::GraphCollection).to receive(:parse_page_url).with(url)
        @collection.parse_page_url(url)
      end

      it "should return the result of the class method" do
        parsed_content = double("parsed_content")
        allow(Koala::Facebook::API::GraphCollection).to receive(:parse_page_url).and_return(parsed_content)
        expect(@collection.parse_page_url(double("url"))).to eq(parsed_content)
      end
    end

    describe ".parse_page_url" do
      it "should return the base as the first array entry" do
        base = "url_path"
        expect(Koala::Facebook::API::GraphCollection.parse_page_url("http://facebook.com/#{base}?anything").first).to eq(base)
      end

      it "should return the arguments as a hash as the last array entry" do
        args_hash = {"one" => "val_one", "two" => "val_two"}
        expect(Koala::Facebook::API::GraphCollection.parse_page_url("http://facebook.com/anything?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}").last).to eq(args_hash)
      end

      it "works with non-.com addresses" do
        base = "url_path"
        args_hash = {"one" => "val_one", "two" => "val_two"}
        expect(Koala::Facebook::API::GraphCollection.parse_page_url("http://facebook.com/#{base}?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}")).to eq([base, args_hash])
      end

      it "works with addresses with irregular characters" do
        access_token = "appid123a|fdcba"
        base, args_hash = Koala::Facebook::API::GraphCollection.parse_page_url("http://facebook.com/foo?token=#{access_token}")
        expect(args_hash["token"]).to eq(access_token)
      end
    end
  end

  describe ".evaluate" do
    it "returns the body of the original response if it's provided a Response with a non-hash data key" do
      result = double('fake response')
      allow(result).to receive(:is_a?).with(Hash).and_return(false)
      allow(result).to receive(:data).and_return([])
      expect(Koala::Facebook::API::GraphCollection.evaluate(result, @api)).to eq([])
    end

    it "returns the original result if it's provided a nil result" do
      result = nil
      expect(Koala::Facebook::API::GraphCollection.evaluate(result, @api)).to eq(result)
    end

    it "returns the original result body if the result doesn't have a data key" do
      paging = {"paging" => {}}
      result = Koala::HTTPService::Response.new(200, paging.to_json, {})
      expect(Koala::Facebook::API::GraphCollection.evaluate(result, @api)).to eq(paging)
    end

    it "returns the original result if the result's data key isn't an array" do
      body = {"data" => {}, "paging" => {}}
      result = Koala::HTTPService::Response.new(200, body.to_json, {})
      expect(Koala::Facebook::API::GraphCollection.evaluate(result, @api)).to eq(body)
    end

    it "returns a new GraphCollection of the result if it has an array data key and a paging key" do
      body = {"data" => [], "paging" => {}}
      result = Koala::HTTPService::Response.new(200, body.to_json, {})
      expected = :foo
      expect(Koala::Facebook::API::GraphCollection).to receive(:new).with(result, @api).and_return(expected)
      expect(Koala::Facebook::API::GraphCollection.evaluate(result, @api)).to eq(expected)
    end
  end

  describe "#next_page" do
    let(:paging){ {"next" => "http://example.com/abc?a=2&b=3"} }

    it "should get next page" do
      expect(@api).to receive(:get_page).with(["abc", {"a" => "2", "b" => "3"}])
      @collection.next_page
    end

    it "should get next page with extra parameters" do
      expect(@api).to receive(:get_page).with(["abc", {"a" => "2", "b" => "3", "c" => "4"}])
      @collection.next_page("c" => "4")
    end
  end

  describe "#previous_page" do
    let(:paging){ {"previous" => "http://example.com/?a=2&b=3"} }

    it "should get previous page" do
      expect(@api).to receive(:get_page).with(["", {"a" => "2", "b" => "3"}])
      @collection.previous_page
    end

    it "should get previous page with extra parameters" do
      expect(@api).to receive(:get_page).with(["", {"a" => "2", "b" => "3", "c" => "4"}])
      @collection.previous_page("c" => "4")
    end
  end
end
