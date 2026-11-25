require 'rails_helper'

RSpec.describe Migration::NativeCallPolicyJob do
  def native(connection)
    create(:channel_whatsapp, provider: 'native', sync_templates: false, validate_provider_config: false).tap do |channel|
      channel.provider_connection = connection
      channel.save!(validate: false)
    end
  end

  # The connector keeps the call policy of the last connect and stands on it when the session
  # comes back, so an inbox paired before the fix keeps refusing calls until it is asked again.
  # One that is paired but down is asked too: it resumes on the policy it was last given.
  it 'asks again every native inbox that has a session to resume, and no other' do
    open = native('connection' => 'open')
    down = native('connection' => 'close', 'phone_number' => '5541999991111')
    native('connection' => 'close')
    create(:channel_whatsapp, provider: 'uazapi', sync_templates: false, validate_provider_config: false,
                              provider_connection: { 'connection' => 'open' })

    expect { described_class.perform_now }
      .to have_enqueued_job(Whatsapp::Session::ApplyProxyJob).exactly(2).times
    expect(Whatsapp::Session::ApplyProxyJob).to have_been_enqueued.with(open.id)
    expect(Whatsapp::Session::ApplyProxyJob).to have_been_enqueued.with(down.id)
  end

  # An inbox that had calling on through the connector keeps the flag in its config after the
  # feature was withdrawn; the job clears it on the session inboxes and leaves a Cloud inbox's,
  # whose calls go through Meta, as it was.
  it 'clears the calling flag of every session inbox and of no Cloud inbox' do
    paired = native('connection' => 'open')
    paired.update_column(:provider_config, paired.provider_config.merge('calling_enabled' => true)) # rubocop:disable Rails/SkipsModelValidations
    cloud = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    cloud.update_column(:provider_config, cloud.provider_config.merge('calling_enabled' => true)) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now

    expect(paired.reload.provider_config).not_to have_key('calling_enabled')
    expect(cloud.reload.provider_config['calling_enabled']).to be(true)
  end

  # `wa:control` is one stream for the whole fleet, and every account asked dials: a deploy that
  # asks them all in the same second is the stampede the rake's pacing exists to avoid.
  it 'spreads the inboxes over time, a few at a time' do
    channels = Array.new(5) { native('connection' => 'open') }

    freeze_time do
      described_class.perform_now

      scheduled = ActiveJob::Base.queue_adapter.enqueued_jobs
                                 .select { |job| job['job_class'] == 'Whatsapp::Session::ApplyProxyJob' }
                                 .to_h { |job| [job['arguments'].first, job['scheduled_at']] }
      first_four = channels.first(4).map { |channel| scheduled[channel.id] }
      expect(first_four.uniq.size).to eq(1)
      expect(Time.zone.parse(scheduled[channels.last.id]) - Time.zone.parse(first_four.first)).to eq(10)
    end
  end

  # Nothing reads a connector call's end any more, so one ringing or under way at the upgrade
  # would stay open, block the next call and ring again whenever its message loads.
  describe 'connector calls still open' do
    let(:native_inbox) { create(:inbox, channel: native('connection' => 'close')) }
    let(:cloud_inbox) do
      create(:inbox, channel: create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false))
    end

    def open_call(inbox, status, started_at: nil)
      conversation = create(:conversation, account: inbox.account, inbox: inbox)
      message = create(:message, account: inbox.account, inbox: inbox, conversation: conversation, content_type: :voice_call,
                                 content_attributes: { 'data' => { 'status' => status.tr('_', '-') } })
      described_class::OpenCall.create!(account_id: inbox.account_id, inbox_id: inbox.id, conversation_id: conversation.id,
                                        contact_id: conversation.contact_id, message_id: message.id, provider: 1, direction: 0,
                                        provider_call_id: SecureRandom.hex(6), status: status, started_at: started_at)
    end

    it 'ends them, in the record, the message and the conversation, and leaves a Cloud call alone' do
      ringing = open_call(native_inbox, 'ringing')
      talking = open_call(native_inbox, 'in_progress', started_at: 2.minutes.ago)
      cloud = open_call(cloud_inbox, 'in_progress', started_at: 2.minutes.ago)

      described_class.perform_now

      expect(ringing.reload).to have_attributes(status: 'no_answer', end_reason: described_class::END_REASON)
      expect(ringing.message.reload.content_attributes['data']['status']).to eq('no-answer')
      expect(talking.reload).to have_attributes(status: 'completed', duration_seconds: be_within(5).of(120))
      expect(talking.message.reload.content_attributes['data']).to include('status' => 'completed')
      expect(talking.conversation.reload.additional_attributes['call_status']).to eq('completed')
      expect(cloud.reload.status).to eq('in_progress')
      expect(cloud.message.reload.content_attributes['data']['status']).to eq('in-progress')
    end

    # On CE nothing removes a deleted conversation's calls, so the call is all that is left.
    it 'ends a call whose conversation was deleted' do
      orphan = open_call(native_inbox, 'ringing')
      orphan.message.delete
      Conversation.where(id: orphan.conversation_id).delete_all

      described_class.perform_now

      expect(orphan.reload.status).to eq('no_answer')
    end

    it 'leaves a call open for the next run when what shows it cannot be written' do
      call = open_call(native_inbox, 'ringing')
      allow_any_instance_of(Message).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) # rubocop:disable RSpec/AnyInstance

      described_class.perform_now

      expect(call.reload.status).to eq('ringing')
    end
  end
end
