require 'spec_helper'
require 'json' unless Hash.respond_to?(:to_json)

describe "Koala::Facebook::GraphAPI in batch mode" do

  before :each do
    @api = Koala::Facebook::API.new(@token)
    # app API
    @app_id = KoalaTest.app_id
    @app_access_token = KoalaTest.app_access_token
    @app_api = Koala::Facebook::API.new(@app_access_token)
  end

  describe Koala::Facebook::GraphBatchAPI::BatchOperation do
    before :each do
      @args = {
        :url => "my url",
        :args => {:a => 2, :b => 3},
        :method => "get",
        :access_token => "12345",
        :http_options => {},
        :post_processing => lambda { }
      }
    end

    describe ".new" do
      it "makes http_options accessible" do
        expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).http_options).to eq(@args[:http_options])
      end

      it "makes post_processing accessible" do
        expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).post_processing).to eq(@args[:post_processing])
      end

      it "makes access_token accessible" do
        expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).access_token).to eq(@args[:access_token])
      end

      it "doesn't change the original http_options" do
        @args[:http_options][:name] = "baz2"
        expected = @args[:http_options].dup
        Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)
        expect(@args[:http_options]).to eq(expected)
      end

      it "leaves the file array nil by default" do
        expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).files).to be_nil
      end

      it "raises a KoalaError if no access token supplied" do
        expect { Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args.merge(:access_token => nil)) }.to raise_exception(Koala::KoalaError)
      end

      describe "when supplied binary files" do
        before :each do
          @binary = double("Binary file")
          @uploadable_io = double("UploadableIO 1")

          @batch_queue = []
          allow(Koala::Facebook::API).to receive(:batch_calls).and_return(@batch_queue)

          allow(Koala::HTTPService::UploadableIO).to receive(:new).with(@binary).and_return(@uploadable_io)
          allow(Koala::HTTPService::UploadableIO).to receive(:binary_content?).and_return(false)
          allow(Koala::HTTPService::UploadableIO).to receive(:binary_content?).with(@binary).and_return(true)
          allow(Koala::HTTPService::UploadableIO).to receive(:binary_content?).with(@uploadable_io).and_return(true)
          allow(@uploadable_io).to receive(:is_a?).with(Koala::HTTPService::UploadableIO).and_return(true)

          @args[:method] = "post" # files are always post
        end

        it "adds binary files to the files attribute as UploadableIOs" do
          @args[:args].merge!("source" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          expect(batch_op.files).not_to be_nil
          expect(batch_op.files.find {|k, v| v == @uploadable_io}).not_to be_nil
        end

        it "works if supplied an UploadableIO as an argument" do
          # as happens with put_picture at the moment
          @args[:args].merge!("source" => @uploadable_io)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          expect(batch_op.files).not_to be_nil
          expect(batch_op.files.find {|k, v| v == @uploadable_io}).not_to be_nil
        end

        it "assigns each binary parameter unique name" do
          @args[:args].merge!("source" => @binary, "source2" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          # if the name wasn't unique, there'd just be one item
          expect(batch_op.files.size).to eq(2)
        end

        it "assigns each binary parameter unique name across batch requests" do
          @args[:args].merge!("source" => @binary, "source2" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          # simulate the batch operation, since it's used in determination
          @batch_queue << batch_op
          batch_op2 = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          @batch_queue << batch_op2
          # if the name wasn't unique, we should have < 4 items since keys would be the same
          expect(batch_op.files.merge(batch_op2.files).size).to eq(4)
        end

        it "removes the value from the arguments" do
          @args[:args].merge!("source" => @binary)
          expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:body]).not_to match(/source=/)
        end
      end

    end

    describe "#to_batch_params" do
      describe "handling arguments and URLs" do
        shared_examples_for "request with no body" do
          it "adds the args to the URL string, with ? if no args previously present" do
            test_args = "foo"
            @args[:url] = url = "/"
            allow(Koala.http_service).to receive(:encode_params).and_return(test_args)

            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:relative_url]).to eq("#{url}?#{test_args}")
          end

          it "adds the args to the URL string, with & if args previously present" do
            test_args = "foo"
            @args[:url] = url = "/?a=2"
            allow(Koala.http_service).to receive(:encode_params).and_return(test_args)

            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:relative_url]).to eq("#{url}&#{test_args}")
          end

          it "adds nothing to the URL string if there are no args to be added" do
            @args[:args] = {}
            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token], nil)[:relative_url]).to eq(@args[:url])
          end

          it "adds nothing to the body" do
            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:body]).to be_nil
          end
        end

        shared_examples_for "requests with a body param" do
          it "sets the body to the encoded args string, if there are args" do
            test_args = "foo"
            allow(Koala.http_service).to receive(:encode_params).and_return(test_args)

            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:body]).to eq(test_args)
          end

          it "does not set the body if there are no args" do
            test_args = ""
            allow(Koala.http_service).to receive(:encode_params).and_return(test_args)
            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:body]).to be_nil
          end


          it "doesn't change the url" do
            test_args = "foo"
            allow(Koala.http_service).to receive(:encode_params).and_return(test_args)

            expect(Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)[:relative_url]).to eq(@args[:url])
          end
        end

        context "for get operations" do
          before :each do
            @args[:method] = :get
          end

          it_should_behave_like "request with no body"
        end

        context "for delete operations" do
          before :each do
            @args[:method] = :delete
          end

          it_should_behave_like "request with no body"
        end

        context "for get operations" do
          before :each do
            @args[:method] = :put
          end

          it_should_behave_like "requests with a body param"
        end

        context "for delete operations" do
          before :each do
            @args[:method] = :post
          end

          it_should_behave_like "requests with a body param"
        end
      end

      it "includes the access token if the token is not the main one for the request" do
         params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)
         expect(params[:relative_url]).to match(/access_token=#{@args[:access_token]}/)
      end

      it "re-signs the access token if the token is not the main one for the request" do
         params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, '1234')
         expect(params[:relative_url]).to match(/appsecret_proof=[^?&]+/)
      end

      it "includes the other arguments if the token is not the main one for the request" do
        @args[:args] = {:a => 2}
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)
        expect(params[:relative_url]).to match(/a=2/)
      end

      it "does not include the access token if the token is the main one for the request" do
         params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token], nil)
         expect(params[:relative_url]).not_to match(/access_token=#{@args[:access_token]}/)
      end

      it "includes the other arguments if the token is the main one for the request" do
        @args[:args] = {:a => 2}
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token], nil)
        expect(params[:relative_url]).to match(/a=2/)
      end

      it "includes any arguments passed as http_options[:batch_args]" do
        batch_args = {:name => "baz", :headers => {:some_param => true}}
        @args[:http_options][:batch_args] = batch_args
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil, nil)
        expect(params).to include(batch_args)
      end

      it "includes the method" do
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token], nil)
        expect(params[:method]).to eq(@args[:method].to_s)
      end

      it "works with nil http_options" do
        expect { Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args.merge(:http_options => nil)).to_batch_params(nil, nil) }.not_to raise_exception
      end

      it "works with nil args" do
        expect { Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args.merge(:args => nil)).to_batch_params(nil, nil) }.not_to raise_exception
      end

      describe "with binary files" do
        before :each do
          @binary = double("Binary file")
          allow(Koala::HTTPService::UploadableIO).to receive(:binary_content?).and_return(false)
          allow(Koala::HTTPService::UploadableIO).to receive(:binary_content?).with(@binary).and_return(true)
          @uploadable_io = double("UploadableIO")
          allow(Koala::HTTPService::UploadableIO).to receive(:new).with(@binary).and_return(@uploadable_io)
          allow(@uploadable_io).to receive(:is_a?).with(Koala::HTTPService::UploadableIO).and_return(true)

          @batch_queue = []
          allow(Koala::Facebook::API).to receive(:batch_calls).and_return(@batch_queue)

          @args[:method] = "post" # files are always post
        end

        it "adds file identifiers as attached_files in a comma-separated list" do
          @args[:args].merge!("source" => @binary, "source2" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          file_ids = batch_op.files.find_all {|k, v| v == @uploadable_io}.map {|k, v| k}
          params = batch_op.to_batch_params(nil, nil)
          expect(params[:attached_files]).to eq(file_ids.join(","))
        end
      end
    end

  end

  describe "GraphAPI batch interface" do
    it "returns nothing for a batch operation" do
      allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, "[]", {}))
      @api.batch do |batch_api|
        expect(batch_api.get_object('me')).to be_nil
      end
    end

    describe "#batch" do
      before :each do
        @fake_response = Koala::HTTPService::Response.new(200, "[]", {})
        allow(Koala).to receive(:make_request).and_return(@fake_response)
      end

      describe "making the request" do
        context "with no calls" do
          it "does not make any requests if batch_calls is empty" do
            expect(Koala).not_to receive(:make_request)
            @api.batch {|batch_api|}
          end

          it "returns []" do
            expect(@api.batch {|batch_api|}).to eq([])
          end
        end

        it "includes the first operation's access token as the main one in the args" do
          access_token = "foo"
          expect(Koala).to receive(:make_request).with(anything, hash_including("access_token" => access_token), anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new(access_token).batch do |batch_api|
            batch_api.get_object('me')
            batch_api.get_object('me', {}, {'access_token' => 'bar'})
          end
        end

        context 'with appsecret_proof and app_secret' do
          it "includes the app_secret in the API call" do
            access_token = "foo"
            app_secret = "baz"
            app_secret_digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), app_secret, access_token)
            expect(Koala).to receive(:make_request).with(anything, hash_including("access_token" => access_token, "appsecret_proof" => app_secret_digest), anything, anything).and_return(@fake_response)
            Koala::Facebook::API.new(access_token, app_secret).batch do |batch_api|
              batch_api.get_object('me')
              batch_api.get_object('me', {}, {'access_token' => 'bar'})
            end
          end
        end

        it "sets args['batch'] to a json'd map of all the batch params" do
          access_token = "bar"
          op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(:access_token => access_token, :method => :get, :url => "/")
          allow(op).to receive(:to_batch_params).and_return({:a => 2})
          allow(Koala::Facebook::GraphBatchAPI::BatchOperation).to receive(:new).and_return(op)

          # two requests should generate two batch operations
          expected = JSON.dump([op.to_batch_params(access_token, nil), op.to_batch_params(access_token, nil)])
          expect(Koala).to receive(:make_request).with(anything, hash_including("batch" => expected), anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new(access_token).batch do |batch_api|
            batch_api.get_object('me')
            batch_api.get_object('me')
          end
        end

        it "adds any files from the batch operations to the arguments" do
          # stub the batch operation
          # we test above to ensure that files are properly assimilated into the BatchOperation instance
          # right now, we want to make sure that batch_api handles them properly
          @key = "file0_0"
          @uploadable_io = double("UploadableIO")
          batch_op = double("Koala Batch Operation", :files => {@key => @uploadable_io}, :to_batch_params => {}, :access_token => "foo")
          allow(Koala::Facebook::GraphBatchAPI::BatchOperation).to receive(:new).and_return(batch_op)

          expect(Koala).to receive(:make_request).with(anything, hash_including(@key => @uploadable_io), anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new("bar").batch do |batch_api|
            batch_api.put_picture("path/to/file", "image/jpeg")
          end
        end

        it "preserves operation order" do
          access_token = "bar"
          # two requests should generate two batch operations
          expect(Koala).to receive(:make_request) do |url, args, method, options|
            # test the batch operations to make sure they appear in the right order
            expect((args ||= {})["batch"]).to match(/.*me\/farglebarg.*otheruser\/bababa/)
            @fake_response
          end
          Koala::Facebook::API.new(access_token).batch do |batch_api|
            batch_api.get_connections('me', "farglebarg")
            batch_api.get_connections('otheruser', "bababa")
          end
        end

        it "makes a POST request" do
          expect(Koala).to receive(:make_request).with(anything, anything, "post", anything).and_return(@fake_response)
          Koala::Facebook::API.new("foo").batch do |batch_api|
            batch_api.get_object('me')
          end
        end

        it "makes a request to /" do
          expect(Koala).to receive(:make_request).with("/", anything, anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new("foo").batch do |batch_api|
            batch_api.get_object('me')
          end
        end

        it "includes any http options specified at the top level" do
          http_options = {"a" => "baz"}
          expect(Koala).to receive(:make_request).with(anything, anything, anything, hash_including(http_options)).and_return(@fake_response)
          Koala::Facebook::API.new("foo").batch(http_options) do |batch_api|
            batch_api.get_object('me')
          end
        end
      end

      describe "processing the request" do
        it "returns the result headers as a hash if http_component is headers" do
          allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, '[{"code":203,"headers":[{"name":"Content-Type","value":"text/javascript; charset=UTF-8"}],"body":"{\"id\":\"1234\"}"}]', {}))
          result = @api.batch do |batch_api|
            batch_api.get_object(KoalaTest.user1, {}, :http_component => :headers)
          end
          expect(result[0]).to eq({"Content-Type" => "text/javascript; charset=UTF-8"})
        end

        describe "if it errors" do
          it "raises an APIError if the response is not 200" do
            allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(500, "[]", {}))
            expect {
              Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
            }.to raise_exception(Koala::Facebook::APIError)
          end

          it "raises a BadFacebookResponse if the body is empty" do
            allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, "", {}))
            expect {
              Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
            }.to raise_exception(Koala::Facebook::BadFacebookResponse)
          end

          context "with error info" do
            before :each do
              allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(400, '{"error":{"message":"Request 0 cannot depend on an  unresolved request with  name f. Requests can only depend on preceding requests","type":"GraphBatchException"}}', {}))
            end

            it "throws an error" do
              expect {
                Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
              }.to raise_exception(Koala::Facebook::APIError)
            end

            it "passes all the error details" do
              begin
                Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
              rescue Koala::Facebook::APIError => err
                expect(err.fb_error_type).to eq("GraphBatchException")
                expect(err.fb_error_message).to eq("Request 0 cannot depend on an  unresolved request with  name f. Requests can only depend on preceding requests")
                err.http_status == 400
                err.response_body == '{"error":{"message":"Request 0 cannot depend on an  unresolved request with  name f. Requests can only depend on preceding requests","type":"GraphBatchException"}}'
              end
            end
          end
        end

        it "returns the result status if http_component is status" do
          allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, '[{"code":203,"headers":[{"name":"Content-Type","value":"text/javascript; charset=UTF-8"}],"body":"{\"id\":\"1234\"}"}]', {}))
          result = @api.batch do |batch_api|
            batch_api.get_object(KoalaTest.user1, {}, :http_component => :status)
          end
          expect(result[0]).to eq(203)
        end
      end

      it "is thread safe" do
        # ensure batch operations on one thread don't affect those on another
        thread_one_count = 0
        thread_two_count = 0
        first_count = 20
        second_count = 10

        allow(Koala).to receive(:make_request).and_return(@fake_response)

        thread1 = Thread.new do
          @api.batch do |batch_api|
            first_count.times {|i| batch_api.get_object("me"); sleep(0.01) }
            thread_one_count = batch_api.batch_calls.count
          end
        end

        thread2 = Thread.new do
          @api.batch do |batch_api|
            second_count.times {|i| batch_api.get_object("me"); sleep(0.01) }
            thread_two_count = batch_api.batch_calls.count
          end
        end

        thread1.join
        thread2.join

        expect(thread_one_count).to eq(first_count)
        expect(thread_two_count).to eq(second_count)
      end

    end
  end

  describe '#big_batches' do
    before :each do
      payload = [{code: 200, headers: [{name: "Content-Type", value: "text/javascript; charset=UTF-8"}], body: "{\"id\":\"1234\"}"}]
      allow(Koala).to receive(:make_request) do |_request, args, _verb, _options|
        request_count = JSON.parse(args['batch']).length
        expect(request_count).to be <= 50   # check FB's limit
        Koala::HTTPService::Response.new(200, (payload * request_count).to_json, {})
      end
    end

    it 'stays within fb limits' do
      count_calls = 0
      expected_calls = 100
      @api.batch do |batch_api|
        expected_calls.times { |_i| batch_api.get_object('me') { |_ret| count_calls += 1 } }
      end

      expect(count_calls).to eq(expected_calls)
    end

    it 'is recursive safe' do
      # ensure batch operations whose callbacks call batch operations don't resubmit
      call_count = 0
      iterations = 60
      @api.batch do |batch_api|
        # must do enough calls to provoke a batch submission
        iterations.times { |_i|
          batch_api.get_object('me') { |_ret|
            call_count += 1
            batch_api.get_object('me') { |_ret|
              call_count += 1
            }
          }
        }
      end
      expect(call_count).to eq(2 * iterations)
    end
  end

  describe "usage tests" do
    it "gets two results at once" do
      me, barackobama = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_object(KoalaTest.user1)
      end
      expect(me['id']).not_to be_nil
      expect(barackobama['id']).not_to be_nil
    end

    it 'makes mixed calls inside of a batch' do
      me, friends = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections('me', 'friends')
      end
      expect(friends).to be_a(Koala::Facebook::API::GraphCollection)
    end

    it 'turns pageable results into GraphCollections' do
      me, friends = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections('me', 'friends')
      end
      expect(me['id']).not_to be_nil
      expect(friends).to be_an(Array)
    end

    it 'makes a get_picture call inside of a batch' do
      pictures = @api.batch do |batch_api|
        batch_api.get_picture('me')
      end
      expect(pictures.first).to match(/https\:\/\//) # works both live & stubbed
    end

    it 'takes an after processing block for a get_picture call inside of a batch' do
      picture = nil
      @api.batch do |batch_api|
        batch_api.get_picture('me') { |pic| picture = pic }
      end
      expect(picture).to match(/https\:\/\//) # works both live & stubbed
    end

    it "handles requests for two different tokens" do
      me, app_event_types = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections(@app_id, 'app_event_types', {}, {"access_token" => @app_api.access_token})
      end
      expect(me['id']).not_to be_nil
      expect(app_event_types).to be_an(Koala::Facebook::API::GraphCollection)
    end

    it "handles requests passing the access token option as a symbol instead of a string" do
      me, app_event_types = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections(@app_id, 'app_event_types', {}, {:access_token => @app_api.access_token})
      end
      expect(me['id']).not_to be_nil
      expect(app_event_types).to be_an(Koala::Facebook::API::GraphCollection)
    end

    it "preserves batch-op specific access tokens in GraphCollection returned from batch" do
      # Provide an alternate token for a batch operation
      @other_access_token_args = { 'access_token' => @app_api.access_token }

      # make a batch call for app_event_types using another token
      me, app_event_types = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections(@app_id, 'app_event_types', {}, @other_access_token_args)
      end

      # The alternate token is returned with the next page parameters
      # The GraphCollection should receive a request for the next_page_params during paging
      expect(app_event_types).to receive(:next_page_params).and_return([double("base"), @other_access_token_args.dup])

      # The alternate access token should pass through to making the request
      # Koala should receive a request during paging using the alternate token
      expect(Koala).to receive(:make_request).with(
          anything,
          hash_including(@other_access_token_args.dup),
          anything,
          anything
      ).and_return(Koala::HTTPService::Response.new(200, "", {}))

      # Page the collection
      app_event_types.next_page
    end

    it "inserts errors in the appropriate place, without breaking other results" do
      failed_call, barackobama = @api.batch do |batch_api|
        batch_api.get_connection("2", "invalidconnection")
        batch_api.get_object(KoalaTest.user1, {}, {"access_token" => @app_api.access_token})
      end
      expect(failed_call).to be_a(Koala::Facebook::ClientError)
      expect(barackobama["id"]).not_to be_nil
    end

    it "handles different request methods" do
      result = @api.put_wall_post("Hello, world, from the test suite batch API!")
      wall_post = result["id"]

      wall_post, barackobama = @api.batch do |batch_api|
        batch_api.put_like(wall_post)
        batch_api.delete_object(wall_post)
      end
    end

    describe 'with post-processing callback' do
      let(:me_result) { double("me result") }
      let(:friends_result) { [double("friends result")] }

      let(:me_callback) { lambda {|arg| {"result" => me_result, "args" => arg} } }
      let(:friends_callback) { lambda {|arg| {"result" => friends_result, "args" => arg} } }

      it 'calls the callback with the appropriate data' do
        me, friends = @api.batch do |batch_api|
          batch_api.get_object('me', &me_callback)
          batch_api.get_connections('me', 'friends', &friends_callback)
        end
        expect(me["args"]).to include("id" => KoalaTest.user1)
        expect(friends["args"].first).to include("id" => KoalaTest.user2)
      end

      it 'passes GraphCollections, not raw data' do
        me, friends = @api.batch do |batch_api|
          batch_api.get_object('me')
          batch_api.get_connections('me', 'friends', &friends_callback)
        end
        expect(friends["args"]).to be_a(Koala::Facebook::API::GraphCollection)
      end

      it "returns the result of the callback" do
        expect(@api.batch do |batch_api|
          batch_api.get_object('me', &me_callback)
          batch_api.get_connections('me', 'friends', &friends_callback)
        end.map {|r| r["result"]}).to eq([me_result, friends_result])
      end
    end

    describe "binary files" do
      it "posts binary files" do
        file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))

        Koala::Facebook::GraphBatchAPI::BatchOperation.instance_variable_set(:@identifier, 0)
        result = @api.batch do |batch_api|
          batch_api.put_picture(file)
        end

        @temporary_object_id = result[0]["id"]
        expect(@temporary_object_id).not_to be_nil
      end

      it "posts binary files with multiple requests" do
        file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))
        file2 = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))

        Koala::Facebook::GraphBatchAPI::BatchOperation.instance_variable_set(:@identifier, 0)
        results = @api.batch do |batch_api|
          batch_api.put_picture(file)
          batch_api.put_picture(file2, {}, KoalaTest.user1)
        end
        expect(results[0]["id"]).not_to be_nil
        expect(results[1]["id"]).not_to be_nil
      end
    end

    describe "relating requests" do
      it "allows you create relationships between requests without omit_response_on_success" do
        results = @api.batch do |batch_api|
          batch_api.get_connections("me", "friends", {:limit => 5}, :batch_args => {:name => "get-friends"})
          batch_api.get_objects("{result=get-friends:$.data.*.id}")
        end

        expect(results[0]).to be_nil
        expect(results[1]).to be_an(Hash)
      end

      it "allows you create relationships between requests with omit_response_on_success" do
        results = @api.batch do |batch_api|
          batch_api.get_connections("me", "friends", {:limit => 5}, :batch_args => {:name => "get-friends", :omit_response_on_success => false})
          batch_api.get_objects("{result=get-friends:$.data.*.id}")
        end

        expect(results[0]).to be_an(Array)
        expect(results[1]).to be_an(Hash)
      end

      it "allows you to create dependencies" do
        me, barackobama = @api.batch do |batch_api|
          batch_api.get_object("me", {}, :batch_args => {:name => "getme"})
          batch_api.get_object(KoalaTest.user1, {}, :batch_args => {:depends_on => "getme"})
        end

        expect(me).to be_nil # gotcha!  it's omitted because it's a successfully-executed dependency
        expect(barackobama["id"]).not_to be_nil
      end

      it "properly handles dependencies that fail" do
        failed_call, barackobama = @api.batch do |batch_api|
          batch_api.get_connections("2", "invalidconnection", {}, :batch_args => {:name => "getdata"})
          batch_api.get_object(KoalaTest.user1, {}, :batch_args => {:depends_on => "getdata"})
        end

        expect(failed_call).to be_a(Koala::Facebook::ClientError)
        expect(barackobama).to be_nil
      end

      it "throws an error for badly-constructed request relationships" do
        expect {
          @api.batch do |batch_api|
            batch_api.get_connections("me", "friends", {:limit => 5})
            batch_api.get_objects("{result=i-dont-exist:$.data.*.id}")
          end
        }.to raise_exception(Koala::Facebook::ClientError)
      end
    end
  end
end
