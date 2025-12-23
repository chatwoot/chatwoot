require "spec_helper"

module Koala
  module HTTPService
    RSpec.describe Request do
      let(:path) { "/foo" }
      let(:args) { {"a" => 2, "b" => 3, "access_token" => "a_token"} }
      let(:verb) { "get" }
      let(:options) { {an: :option} }
      let(:request) { Request.new(path: path, args: args, verb: verb, options: options) }

      shared_context post: true do
        let(:verb) { "post" }
      end

      shared_context delete: true do
        let(:verb) { "delete" }
      end

      shared_context put: true do
        let(:verb) { "put" }
      end

      it "raises an ArgumentError if no verb is supplied" do
        expect { Request.new(path: path) }.to raise_exception(ArgumentError)
      end

      it "raises an ArgumentError if no path is supplied" do
        expect { Request.new(verb: verb) }.to raise_exception(ArgumentError)
      end

      describe "#verb" do
        it "returns get for get" do
          expect(Request.new(path: path, verb: "get").verb).to eq("get")
        end

        it "returns post for post" do
          expect(Request.new(path: path, verb: "post").verb).to eq("post")
        end

        it "returns post for put" do
          expect(Request.new(path: path, verb: "put").verb).to eq("post")
        end

        it "returns post for delete" do
          expect(Request.new(path: path, verb: "delete").verb).to eq("post")
        end
      end

      describe "#path" do
        context "if there's no API version" do
          it "returns the path" do
            expect(request.path).to eq(path)
          end
        end

        context "if there's an API version" do
          shared_examples_for :including_the_version do
            it "prefixes the version appropriately when the path starts with /" do
              expect(Request.new(path: "/foo", verb: "get", options: options).path).to eq("/#{version}/foo")
            end

            it "prefixes the version appropriately when the path doesn't start with /" do
              expect(Request.new(path: "foo", verb: "get", options: options).path).to eq("/#{version}/foo")
            end
          end

          context "set by Koala.config" do
            let(:version) { "v2.7" }

            before :each do
              Koala.configure do |config|
                config.api_version = version
              end
            end

            it_should_behave_like :including_the_version
          end

          context "set in options" do
            let(:version) { "v2.8" }

            let(:options) { {api_version: version} }

            it_should_behave_like :including_the_version
          end

          context "for versions without a ." do
            let(:version) { "v21" }

            let(:options) { {api_version: version} }

            it_should_behave_like :including_the_version
          end
        end
      end

      describe "#post_args" do
        it "returns {} for get" do
          expect(request.post_args).to eq({})
        end

        it "returns args for post", :post do
          expect(request.post_args).to eq(args)
        end

        it "returns args + method: delete for delete", :delete do
          expect(request.post_args).to eq(args.merge(method: "delete"))
        end

        it "returns args + method: put for put", :put do
          expect(request.post_args).to eq(args.merge(method: "put"))
        end

        it "turns any UploadableIOs to UploadIOs" do
          # technically this is done for all requests, but you don't send GET requests with files
          upload_io = double("UploadIO")
          u = Koala::HTTPService::UploadableIO.new("/path/to/stuff", "img/jpg")
          allow(u).to receive(:to_upload_io).and_return(upload_io)
          request = Request.new(path: path, verb: "post", args: {an_upload: u})
          expect(request.post_args[:an_upload]).to eq(upload_io)
        end
      end

      describe "#json?" do
        it "returns false if the option for JSON isn't set" do
          expect(request).not_to be_json
        end

        context "if JSON is set" do
          let(:options) { {format: :json} }

          it "returns true if it is" do
            expect(request).to be_json
          end
        end
      end

      describe "#options" do
        it "returns the options provided" do
          expect(request.options).to include(options)
        end

        it "merges in any global options" do
          global_options = {some: :opts}
          HTTPService.http_options = global_options
          results = request.options
          HTTPService.http_options = {}
          expect(results).to include(global_options)
        end

        it "overwrites any global options with equivalent ones" do
          options = {foo: :bar}
          HTTPService.http_options = {foo: 2}
          results = Request.new(path: path, args: args, verb: verb, options: options).options
          HTTPService.http_options = {}
          expect(results).to include(options)
        end

        describe "get parameters" do
          it "includes the parameters for a get " do
            expect(request.options[:params]).to eq(args)
          end

          it "returns {} for post", :post do
            expect(request.options[:params]).to eq({})
          end

          it "returns {} for delete", :delete do
            expect(request.options[:params]).to eq({})
          end

          it "returns {} for put", :put do
            expect(request.options[:params]).to eq({})
          end
        end

        describe "ssl options" do
          it "includes the default SSL options even if there's no access token" do
            request_options = Request.new(path: path, args: args.delete_if {|k, _v| k == "access_token"}, verb: verb, options: options).options
            expect(request_options).to include(use_ssl: true, ssl: {verify: true})
          end

          context "if there is an access_token" do
            it "includes the default SSL options" do
              expect(request.options).to include(use_ssl: true, ssl: {verify: true})
            end

            it "incorporates any provided SSL options" do
              new_ssl_options = {an: :option2}
              request_options = Request.new(path: path, args: args, verb: verb, options: options.merge(ssl: new_ssl_options)).options
              expect(request_options[:ssl]).to include(new_ssl_options)
            end

            it "overrides default SSL options with what's provided" do
              new_ssl_options = {use_ssl: false, ssl:{verify: :dunno}}
              request_options = Request.new(path: path, args: args, verb: verb, options: options.merge(new_ssl_options)).options
              expect(request_options).to include(new_ssl_options)
            end
          end
        end

        describe "server" do
          describe "with no options" do
            it "returns the graph server by default" do
              expect(request.server).to eq("https://graph.facebook.com")
            end

            it "uses another base server if specified" do
              Koala.config.graph_server = "foo"
              expect(request.server).to eq("https://foo")
            end

            context "if there is no access token" do
              let(:args) { {"a" => "b"} }

              it "uses https" do
                expect(request.server).to eq("https://graph.facebook.com")
              end
            end

            context "if options[:use_ssl] is false" do
              let(:options) { {use_ssl: false} }

              it "uses http" do
                expect(request.server).to eq("http://graph.facebook.com")
              end
            end

            context "if options[:beta]" do
              let(:options) { {beta: true} }

              it "returns https if options[:beta]" do
                expect(request.server).to eq("https://graph.beta.facebook.com")
              end
            end

            context "if options[:video]" do
              let(:options) { {video: true} }

              it "returns https if options[:video]" do
                expect(request.server).to eq("https://graph-video.facebook.com")
              end
            end
          end
        end
      end
    end
  end
end
