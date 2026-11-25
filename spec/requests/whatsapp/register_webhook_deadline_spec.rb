require 'rails_helper'

# `register_webhook` makes four Graph calls in a row, and a ceiling per call composes with the number of
# calls: four answers that each arrive under the ceiling add up to four ceilings. These examples run the
# endpoint against a Graph that really takes its time, over a real socket, because what is under test is
# the wall clock of the request, and a stub that answers at once has none.
#
# The numbers are the production ones scaled down so the suite stays fast: a 3s ceiling, a 2.5s deadline
# and calls that each take 1s keep the same relationships as 10s, 12s and a slow Meta.
RSpec.describe 'register_webhook under one deadline', type: :request do
  # The deadline exists to answer before the process is cut from outside. In production `rack-timeout`
  # cuts a request at RACK_TIMEOUT_SERVICE_TIMEOUT, 15s unless an installation sets it, and it does so
  # with a Thread#raise the endpoint's own rescue cannot see. The gem is in the production group, so the
  # number is written here rather than read from it.
  it 'sits between a full ceiling for the required write and the cut rack-timeout makes' do
    deadline = Api::V1::Accounts::Concerns::InboxHealthManagement::REGISTER_WEBHOOK_DEADLINE

    expect(deadline).to be >= Whatsapp::GraphRequestOptions::GRAPH_REQUEST_OPTIONS[:timeout] + Whatsapp::GraphDeadline::MINIMUM_CALL_SECONDS
    expect(deadline).to be < 15
  end

  describe 'against a Graph that takes its time' do
    let(:account) { create(:account) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    end
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:phone_number_id) { channel.provider_config['phone_number_id'] }
    let!(:seen) { Queue.new }
    let!(:delays) { Hash.new(0) }

    # A Graph that answers every call it knows, after the delay set for it. The phone number and the business
    # account share one id in the factory, so one GET answers both health reads, the way the controller spec
    # stubs them.
    let!(:graph) do
      server = TCPServer.new('127.0.0.1', 0)
      thread = Thread.new do
        loop do
          client = server.accept
          Thread.new(client) { |socket| answer(socket) }
        end
      rescue IOError
        nil
      end
      { server: server, thread: thread, url: "http://127.0.0.1:#{server.addr[1]}" }
    end

    def answer(socket)
      head = +''
      head << socket.readpartial(4096) until head.include?("\r\n\r\n")
      request_line = head.lines.first.to_s
      kind = kind_of_call(request_line)
      seen << kind
      sleep(delays[kind])
      body = kind == :health ? health_body : { success: true }.to_json
      socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
    rescue IOError, SystemCallError
      nil
    ensure
      socket.close
    end

    def kind_of_call(request_line)
      return :subscribe if request_line.include?('/subscribed_apps')
      return :health if request_line.start_with?('GET')

      :override
    end

    def health_body
      { id: phone_number_id, display_phone_number: '+1 234 567 8911', name: 'WABA', owner_business_info: { id: 'biz', name: 'Portfolio' } }.to_json
    end

    def calls_seen
      calls = []
      calls << seen.pop until seen.empty?
      calls
    end

    def register_webhook
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/register_webhook", headers: admin.create_new_auth_token, as: :json
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end

    # The first request in the process pays for routing, authorization, the controller and the
    # first query on each table, and none of that is what the deadline governs. Production runs
    # these numbers four times larger, so there that fixed cost is a small share of the margin;
    # at this scale it is most of it, and on a loaded CI runner it is all of it: the example
    # below measured 3.39s against its 3.0s ceiling on `main`, and 3.28s and 3.36s on the branch
    # that added this comment, while the same example takes 2.5s on a warm laptop. An example
    # that measures a wall clock pays that cost before it starts measuring.
    def warm_up
      register_webhook
      calls_seen
    end

    before do
      stub_const('Whatsapp::FacebookApiClient::BASE_URI', graph[:url])
      stub_const('Whatsapp::HealthService::BASE_URI', graph[:url])
      stub_const('Whatsapp::GraphRequestOptions::GRAPH_REQUEST_OPTIONS', { timeout: 3, max_retries: 0 }.freeze)
      stub_const('Api::V1::Accounts::Concerns::InboxHealthManagement::REGISTER_WEBHOOK_DEADLINE', 2.5)
    end

    after do
      graph[:server].close
      graph[:thread].join(1)
    end

    it 'answers inside the deadline when every call answers correctly but slowly' do
      warm_up
      %i[subscribe override health].each { |kind| delays[kind] = 1.0 }

      elapsed = register_webhook

      expect(response).to have_http_status(:ok)
      expect(elapsed).to be < 3.0
      expect(response.parsed_body['callback_override_applied']).to be(true)
      expect(response.parsed_body['routing_read_back']).to be(false)
      expect(response.parsed_body).not_to have_key('health')
      expect(calls_seen).to eq(%i[subscribe override])
    end

    # The same refusal, seen from where it hurts: the endpoint answers 200 without the routing, and
    # nothing about this number was checked. Six hours of nobody looking at it is what recording it
    # as a check anyway would cost, because that is the scheduler's own window (#644).
    it 'leaves the number where the background sync still picks it up when the read is refused' do
      %i[subscribe override health].each { |kind| delays[kind] = 1.0 }
      channel.update!(phone_number_health_checked_at: 7.hours.ago)
      stamped_at = channel.reload.phone_number_health_checked_at

      register_webhook

      expect(response.parsed_body['routing_read_back']).to be(false)
      expect(channel.reload.phone_number_health_checked_at).to eq(stamped_at)
      expect { Channels::Whatsapp::HealthSyncSchedulerJob.perform_now }
        .to have_enqueued_job(Channels::Whatsapp::HealthSyncJob).with(channel).on_queue('low')
    end

    it 'cuts an optional call that hangs to what is left, instead of giving it a whole ceiling' do
      warm_up
      delays[:subscribe] = 1.0
      delays[:override] = 5.0

      elapsed = register_webhook

      expect(response).to have_http_status(:ok)
      expect(elapsed).to be < 3.0
      expect(response.parsed_body).to include('callback_override_applied' => false, 'routing_read_back' => false)
      expect(calls_seen).to eq(%i[subscribe override])
    end

    it 'still reads the routing back when a slow required write leaves the time for it' do
      delays[:subscribe] = 1.2

      register_webhook

      expect(response.parsed_body).to include('callback_override_applied' => true, 'routing_read_back' => true)
      expect(response.parsed_body.dig('health', 'business_account_name')).to eq('WABA')
      expect(calls_seen).to eq(%i[subscribe override health health])
    end

    it 'gives the next request on the same thread a deadline of its own' do
      %i[subscribe override health].each { |kind| delays[kind] = 1.0 }
      register_webhook
      calls_seen
      delays.clear

      register_webhook

      expect(response.parsed_body).to include('callback_override_applied' => true, 'routing_read_back' => true)
      expect(calls_seen).to eq(%i[subscribe override health health])
    end
  end
end
