require 'spec_helper'

module Koala
  module Facebook
    RSpec.describe GraphErrorChecker do
      it "defines a set of AUTHENTICATION_ERROR_CODES" do
        expect(GraphErrorChecker::AUTHENTICATION_ERROR_CODES).to match_array([102, 190, 450, 452, 2500])
      end

      it "defines a set of DEBUG_HEADERS" do
        expect(GraphErrorChecker::DEBUG_HEADERS).to match_array([
          "x-fb-rev",
          "x-fb-debug",
          "x-fb-trace-id",
          "x-business-use-case-usage",
          "x-ad-account-usage",
          "x-app-usage"
        ])
      end

      describe "#error_if_appropriate" do
        shared_examples_for :returning_no_error do |status|
          it "returns no error" do
            expect(GraphErrorChecker.new(status, "{}", {}).error_if_appropriate).to be_nil
          end

          it "ignores error data even if present" do
            checker = GraphErrorChecker.new(
              status,
              {"error" => {"some" => "error"}},
              {"x-fb-rev" => "data"}
            )
            expect(checker.error_if_appropriate).to be_nil
          end
        end

        context "if the status is 2xx" do
          it_should_behave_like :returning_no_error, 202
        end

        context "if the status is 3xx" do
          it_should_behave_like :returning_no_error, 302
        end

        shared_examples_for :returns_an_error do |status|
          let(:body) { "{}" }
          let(:headers) { {} }
          let(:error) { GraphErrorChecker.new(status, body, headers).error_if_appropriate }
          it "returns a ClientError for a generic error" do
            expect(error).to be_a(ClientError)
            expect(error.response_body).to eq(body)
          end

          it "returns a ClientError even if the body can't be parsed as JSON" do
            body.replace("hello from Chicago")
            expect(error).to be_a(ClientError)
            expect(error.response_body).to eq(body)
          end

          it "returns a ClientError if the body is empty" do
            body.replace("")
            expect(error).to be_a(ClientError)
            expect(error.response_body).to eq(body)
          end

          it "adds error data from the body" do
            error_data = {
              "type" => "FB error type",
              "code" => "FB error code",
              "error_subcode" => "FB error subcode",
              "message" => "An error occurred!",
              "error_user_msg" => "A user msg",
              "error_user_title" => "usr title"
            }
            body.replace({"error" => error_data}.to_json)

            expect(error.fb_error_type).to eq(error_data["type"])
            expect(error.fb_error_code).to eq(error_data["code"])
            expect(error.fb_error_subcode).to eq(error_data["error_subcode"])
            expect(error.fb_error_message).to eq(error_data["message"])
            expect(error.fb_error_user_msg).to eq(error_data["error_user_msg"])
            expect(error.fb_error_user_title).to eq(error_data["error_user_title"])
          end

          it "adds the FB debug headers to the errors" do
            headers.merge!(
              "x-fb-debug" => double("fb debug"),
              "x-fb-rev" => double("fb rev"),
              "x-fb-trace-id" => double("fb trace id"),
              "x-business-use-case-usage" => { 'a' => 1, 'b' => 2 }.to_json,
              "x-ad-account-usage" => { 'c' => 3, 'd' => 4 }.to_json,
              "x-app-usage" => { 'e' => 5, 'f' => 6 }.to_json
            )
            expect(error.fb_error_trace_id).to eq(headers["x-fb-trace-id"])
            expect(error.fb_error_debug).to eq(headers["x-fb-debug"])
            expect(error.fb_error_rev).to eq(headers["x-fb-rev"])
            expect(error.fb_buc_usage).to eq({ 'a' => 1, 'b' => 2 })
            expect(error.fb_ada_usage).to eq({ 'c' => 3, 'd' => 4 })
            expect(error.fb_app_usage).to eq({ 'e' => 5, 'f' => 6 })
          end

          it "logs if one of the FB debug headers can't be parsed" do
            headers.merge!(
              "x-app-usage" => '{invalid:json}'
            )

            expect(Koala::Utils.logger).to receive(:error).with(/JSON::ParserError:.*unexpected token at '{invalid:json}' while parsing x-app-usage = {invalid:json}/)
            expect(error.fb_app_usage).to eq(nil)
          end

          context "it returns an AuthenticationError" do
            it "if FB says it's an OAuthException and it has no code" do
              body.replace({"error" => {"type" => "OAuthException"}}.to_json)
              expect(error).to be_an(AuthenticationError)
            end

            GraphErrorChecker::AUTHENTICATION_ERROR_CODES.each do |error_code|
              it "if FB says it's an OAuthException and it has code #{error_code}" do
                body.replace({"error" => {"type" => "OAuthException", "code" => error_code}}.to_json)
                expect(error).to be_an(AuthenticationError)
              end
            end
          end

          # Note: I'm not sure why this behavior was implemented, it may be incorrect. To
          # investigate.
          it "doesn't return an AuthenticationError if FB says it's an OAuthException but the code doesn't match" do
            body.replace({"error" => {"type" => "OAuthException", "code" => 2499}}.to_json)
            expect(error).to be_an(ClientError)
          end
        end

        context "if the status is 4xx" do
          it_should_behave_like :returns_an_error, 400
        end
      end
    end
  end
end
