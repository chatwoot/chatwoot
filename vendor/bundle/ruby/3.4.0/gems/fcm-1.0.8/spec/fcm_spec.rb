require "spec_helper"

describe FCM do
  let(:send_url) { "#{FCM::BASE_URI}/fcm/send" }
  let(:group_notification_base_uri) { "#{FCM::GROUP_NOTIFICATION_BASE_URI}/gcm/notification" }
  let(:api_key) { "AIzaSyB-1uEai2WiUapxCs2Q0GZYzPu7Udno5aA" }
  let(:registration_id) { "42" }
  let(:registration_ids) { ["42"] }
  let(:key_name) { "appUser-Chris" }
  let(:project_id) { "123456789" } # https://developers.google.com/cloud-messaging/gcm#senderid
  let(:notification_key) { "APA91bGHXQBB...9QgnYOEURwm0I3lmyqzk2TXQ" }
  let(:valid_topic) { "TopicA" }
  let(:invalid_topic) { "TopicA$" }
  let(:valid_condition) { "'TopicA' in topics && ('TopicB' in topics || 'TopicC' in topics)" }
  let(:invalid_condition) { "'TopicA' in topics and some other text ('TopicB' in topics || 'TopicC' in topics)" }
  let(:invalid_condition_topic) { "'TopicA$' in topics" }

  it "should raise an error if the api key is not provided" do
    expect { FCM.new }.to raise_error(ArgumentError)
  end

  it "should raise error if time_to_live is given" do
    # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#ttl
  end

  describe "#send_v1" do
    pending "should send message"
  end

  describe "sending notification" do
    let(:valid_request_body) do
      { registration_ids: registration_ids }
    end
    let(:valid_request_body_with_string) do
      { registration_ids: registration_id }
    end
    let(:valid_request_headers) do
      {
        "Content-Type" => "application/json",
        "Authorization" => "key=#{api_key}",
      }
    end

    let(:stub_fcm_send_request) do
      stub_request(:post, send_url).with(
        body: valid_request_body.to_json,
        headers: valid_request_headers,
      ).to_return(
        # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
        body: "{}",
        headers: {},
        status: 200,
      )
    end

    let(:stub_fcm_send_request_with_string) do
      stub_request(:post, send_url).with(
        body: valid_request_body_with_string.to_json,
        headers: valid_request_headers,
      ).to_return(
        body: "{}",
        headers: {},
        status: 200,
      )
    end

    let(:stub_fcm_send_request_with_basic_auth) do
      uri = URI.parse(send_url)
      uri.user = "a"
      uri.password = "b"
      stub_request(:post, uri.to_s).to_return(body: "{}", headers: {}, status: 200)
    end

    before(:each) do
      stub_fcm_send_request
      stub_fcm_send_request_with_string
      stub_fcm_send_request_with_basic_auth
    end

    it "should send notification using POST to FCM server" do
      fcm = FCM.new(api_key)
      fcm.send(registration_ids).should eq(response: "success", body: "{}", headers: {}, status_code: 200, canonical_ids: [], not_registered_ids: [])
      stub_fcm_send_request.should have_been_made.times(1)
    end

    it "should send notification using POST to FCM if id provided as string" do
      fcm = FCM.new(api_key)
      fcm.send(registration_id).should eq(response: "success", body: "{}", headers: {}, status_code: 200, canonical_ids: [], not_registered_ids: [])
      stub_fcm_send_request.should have_been_made.times(1)
    end

    context "send notification with data" do
      let!(:stub_with_data) do
        stub_request(:post, send_url)
          .with(body: '{"registration_ids":["42"],"data":{"score":"5x1","time":"15:10"}}',
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: {})
      end
      before do
      end
      it "should send the data in a post request to fcm" do
        fcm = FCM.new(api_key)
        fcm.send(registration_ids, data: { score: "5x1", time: "15:10" })
        stub_with_data.should have_been_requested
      end
    end

    context "sending notification to a topic" do
      let!(:stub_with_valid_topic) do
        stub_request(:post, send_url)
          .with(body: '{"to":"/topics/TopicA","data":{"score":"5x1","time":"15:10"}}',
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: {})
      end
      let!(:stub_with_invalid_topic) do
        stub_request(:post, send_url)
          .with(body: '{"condition":"/topics/TopicA$","data":{"score":"5x1","time":"15:10"}}',
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: {})
      end

      describe "#send_to_topic" do
        it "should send the data in a post request to fcm" do
          fcm = FCM.new(api_key)
          fcm.send_to_topic(valid_topic, data: { score: "5x1", time: "15:10" })
          stub_with_valid_topic.should have_been_requested
        end

        it "should not send to invalid topics" do
          fcm = FCM.new(api_key)
          fcm.send_to_topic(invalid_topic, data: { score: "5x1", time: "15:10" })
          stub_with_invalid_topic.should_not have_been_requested
        end
      end
    end

    context "sending notification to a topic condition" do
      let!(:stub_with_valid_condition) do
        stub_request(:post, send_url)
          .with(body: '{"condition":"\'TopicA\' in topics && (\'TopicB\' in topics || \'TopicC\' in topics)","data":{"score":"5x1","time":"15:10"}}',
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: {})
      end
      let!(:stub_with_invalid_condition) do
        stub_request(:post, send_url)
          .with(body: '{"condition":"\'TopicA\' in topics and some other text (\'TopicB\' in topics || \'TopicC\' in topics)","data":{"score":"5x1","time":"15:10"}}',
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: {})
      end
      let!(:stub_with_invalid_condition_topic) do
        stub_request(:post, send_url)
          .with(body: '{"condition":"\'TopicA$\' in topics","data":{"score":"5x1","time":"15:10"}}',
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: {})
      end

      describe "#send_to_topic_condition" do
        it "should send the data in a post request to fcm" do
          fcm = FCM.new(api_key)
          fcm.send_to_topic_condition(valid_condition, data: { score: "5x1", time: "15:10" })
          stub_with_valid_condition.should have_been_requested
        end

        it "should not send to invalid conditions" do
          fcm = FCM.new(api_key)
          fcm.send_to_topic_condition(invalid_condition, data: { score: "5x1", time: "15:10" })
          stub_with_invalid_condition.should_not have_been_requested
        end

        it "should not send to invalid topics in a condition" do
          fcm = FCM.new(api_key)
          fcm.send_to_topic_condition(invalid_condition_topic, data: { score: "5x1", time: "15:10" })
          stub_with_invalid_condition_topic.should_not have_been_requested
        end
      end
    end

    context "when send_notification responds with failure" do
      let(:mock_request_attributes) do
        {
          body: valid_request_body.to_json,
          headers: valid_request_headers,
        }
      end

      subject { FCM.new(api_key) }

      context "on failure code 400" do
        before do
          stub_request(:post, send_url).with(
            mock_request_attributes
          ).to_return(
            # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
            body: "{}",
            headers: {},
            status: 400,
          )
        end
        it "should not send notification due to 400" do
          subject.send(registration_ids).should eq(body: "{}",
                                                   headers: {},
                                                   response: "Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields.",
                                                   status_code: 400)
        end
      end

      context "on failure code 401" do
        before do
          stub_request(:post, send_url).with(
            mock_request_attributes
          ).to_return(
            # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
            body: "{}",
            headers: {},
            status: 401,
          )
        end

        it "should not send notification due to 401" do
          subject.send(registration_ids).should eq(body: "{}",
                                                   headers: {},
                                                   response: "There was an error authenticating the sender account.",
                                                   status_code: 401)
        end
      end

      context "on failure code 503" do
        before do
          stub_request(:post, send_url).with(
            mock_request_attributes
          ).to_return(
            # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
            body: "{}",
            headers: {},
            status: 503,
          )
        end

        it "should not send notification due to 503" do
          subject.send(registration_ids).should eq(body: "{}",
                                                   headers: {},
                                                   response: "Server is temporarily unavailable.",
                                                   status_code: 503)
        end
      end

      context "on failure code 5xx" do
        before do
          stub_request(:post, send_url).with(
            mock_request_attributes
          ).to_return(
            # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
            body: '{"body-key" => "Body value"}',
            headers: { "header-key" => "Header value" },
            status: 599,
          )
        end

        it "should not send notification due to 599" do
          subject.send(registration_ids).should eq(body: '{"body-key" => "Body value"}',
                                                   headers: { "header-key" => "Header value" },
                                                   response: "There was an internal error in the FCM server while trying to process the request.",
                                                   status_code: 599)
        end
      end
    end

    context "when send_notification responds canonical_ids" do
      let(:mock_request_attributes) do
        {
          body: valid_request_body.to_json,
          headers: valid_request_headers,
        }
      end

      let(:valid_response_body_with_canonical_ids) do
        {
          failure: 0, canonical_ids: 1, results: [{ registration_id: "43", message_id: "0:1385025861956342%572c22801bb3" }],
        }
      end

      subject { FCM.new(api_key) }

      before do
        stub_request(:post, send_url).with(
          mock_request_attributes
        ).to_return(
          # ref: https://firebase.google.com/docs/cloud-messaging/http-server-ref#interpret-downstream
          body: valid_response_body_with_canonical_ids.to_json,
          headers: {},
          status: 200,
        )
      end

      it "should contain canonical_ids" do
        response = subject.send(registration_ids)

        response.should eq(headers: {},
                           canonical_ids: [{ old: "42", new: "43" }],
                           not_registered_ids: [],
                           status_code: 200,
                           response: "success",
                           body: '{"failure":0,"canonical_ids":1,"results":[{"registration_id":"43","message_id":"0:1385025861956342%572c22801bb3"}]}')
      end
    end

    context "when send_notification responds with NotRegistered" do
      subject { FCM.new(api_key) }

      let(:mock_request_attributes) do
        {
          body: valid_request_body.to_json,
          headers: valid_request_headers,
        }
      end

      let(:valid_response_body_with_not_registered_ids) do
        {
          canonical_ids: 0, failure: 1, results: [{ error: "NotRegistered" }],
        }
      end

      before do
        stub_request(:post, send_url).with(
          mock_request_attributes
        ).to_return(
          body: valid_response_body_with_not_registered_ids.to_json,
          headers: {},
          status: 200,
        )
      end

      it "should contain not_registered_ids" do
        response = subject.send(registration_ids)
        response.should eq(
          headers: {},
          canonical_ids: [],
          not_registered_ids: registration_ids,
          status_code: 200,
          response: "success",
          body: '{"canonical_ids":0,"failure":1,"results":[{"error":"NotRegistered"}]}',
        )
      end
    end
  end

  describe "sending group notifications" do
    # TODO: refactor to should_behave_like
    let(:valid_request_headers) do
      {
        "Authorization" => "key=#{api_key}",
        "Content-Type" => "application/json",
        "Project-Id" => project_id,
      }
    end
    let(:valid_response_body) do
      { notification_key: "APA91bGHXQBB...9QgnYOEURwm0I3lmyqzk2TXQ" }
    end

    let(:default_valid_request_body) do
      {
        registration_ids: registration_ids,
        operation: "create",
        notification_key_name: key_name,
      }
    end

    subject { FCM.new(api_key) }

    # ref: https://firebase.google.com/docs/cloud-messaging/notifications#managing-device-groups-on-the-app-server
    context "create" do
      let(:valid_request_body) do
        default_valid_request_body.merge({
          operation: "create",
        })
      end

      let(:mock_request_attributes) do
        {
          body: valid_request_body.to_json,
          headers: valid_request_headers,
        }
      end

      before do
        stub_request(:post, group_notification_base_uri).with(
          mock_request_attributes
        ).to_return(
          body: valid_response_body.to_json,
          headers: {},
          status: 200,
        )
      end

      it "should send a post request" do
        response = subject.create(key_name, project_id, registration_ids)
        response.should eq(
          headers: {},
          status_code: 200,
          response: "success",
          body: valid_response_body.to_json,
        )
      end
    end # create context

    context "add" do
      let(:valid_request_body) do
        default_valid_request_body.merge({
          operation: "add",
          notification_key: notification_key,
        })
      end

      let(:mock_request_attributes) do
        {
          body: valid_request_body.to_json,
          headers: valid_request_headers,
        }
      end

      before do
        stub_request(:post, group_notification_base_uri).with(
          mock_request_attributes
        ).to_return(
          body: valid_response_body.to_json,
          headers: {},
          status: 200,
        )
      end

      it "should send a post request" do
        response = subject.add(key_name, project_id, notification_key, registration_ids)
        response.should eq(
          headers: {},
          status_code: 200,
          response: "success",
          body: valid_response_body.to_json,
        )
      end
    end # add context

    context "remove" do
      let(:valid_request_body) do
        default_valid_request_body.merge({
          operation: "remove",
          notification_key: notification_key,
        })
      end

      let(:mock_request_attributes) do
        {
          body: valid_request_body.to_json,
          headers: valid_request_headers,
        }
      end

      before do
        stub_request(:post, group_notification_base_uri).with(
          mock_request_attributes
        ).to_return(
          body: valid_response_body.to_json,
          headers: {},
          status: 200,
        )
      end

      it "should send a post request" do
        response = subject.remove(key_name, project_id, notification_key, registration_ids)
        response.should eq(
          headers: {},
          status_code: 200,
          response: "success",
          body: valid_response_body.to_json,
        )
      end
    end # remove context
  end

  describe "#recover_notification_key" do
    it "sends a 'retrieve notification key' request" do
      uri = "#{FCM::GROUP_NOTIFICATION_BASE_URI}/gcm/notification"
      endpoint = stub_request(:get, uri).with(
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "key=TEST_SERVER_KEY",
          "project_id" => "TEST_PROJECT_ID",
        },
        query: { notification_key_name: "TEST_KEY_NAME" },
      )
      client = FCM.new("TEST_SERVER_KEY")

      client.recover_notification_key("TEST_KEY_NAME", "TEST_PROJECT_ID")

      expect(endpoint).to have_been_requested
    end
  end

  describe "subscribing to a topic" do
    # TODO
  end

  describe 'getting instance info' do
    subject(:get_info) { client.get_instance_id_info(registration_id, options) }

    let(:options) { nil }
    let(:client) { FCM.new('TEST_SERVER_KEY') }
    let(:base_uri) { "#{FCM::INSTANCE_ID_API}/iid/info" }
    let(:uri) { "#{base_uri}/#{registration_id}" }
    let(:mock_request_attributes) do
      { headers: {
        'Authorization' => 'key=TEST_SERVER_KEY',
        'Content-Type' => 'application/json'
      } }
    end

    context 'without options' do
      it 'calls info endpoint' do
        endpoint = stub_request(:get, uri).with(mock_request_attributes)
        get_info
        expect(endpoint).to have_been_requested
      end
    end

    context 'with detail option' do
      let(:uri) { "#{base_uri}/#{registration_id}?details=true" }
      let(:options) { { details: true } }

      it 'calls info endpoint' do
        endpoint = stub_request(:get, uri).with(mock_request_attributes)
        get_info
        expect(endpoint).to have_been_requested
      end
    end
  end

  describe "credentials path" do
    it "can be a path to a file" do
      fcm = FCM.new("test", "README.md")
      expect(fcm.__send__(:json_key).class).to eq(File)
    end

    it "can be an IO object" do
      fcm = FCM.new("test", StringIO.new("hey"))
      expect(fcm.__send__(:json_key).class).to eq(StringIO)
    end
  end
end
