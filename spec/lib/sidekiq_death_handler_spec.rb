require 'rails_helper'

RSpec.describe SidekiqDeathHandler do
  let(:exception) { StandardError.new('the provider never answered') }

  def job_for(class_name, arguments)
    { 'class' => 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper',
      'wrapped' => class_name,
      'args' => [{ 'arguments' => arguments }] }
  end

  before { allow(Rails.logger).to receive(:error) }

  # The dead set held hundreds of failed sends nobody had been told about, so the bug was
  # found by the customer complaining rather than by monitoring.
  it 'reports a dead job' do
    described_class.call(job_for('SomeJob', [42]), exception)

    expect(Rails.logger).to have_received(:error).with(/\[SIDEKIQ\]\[DEAD\] SomeJob/)
  end

  # An opaque message id is not actionable at 3am; the account and inbox are.
  it 'names the account, inbox and conversation for a dead reply' do
    message = create(:message, message_type: :outgoing)

    described_class.call(job_for('SendReplyJob', [message.id]), exception)

    expect(Rails.logger).to have_received(:error).with(
      /account_id=#{message.account_id} inbox_id=#{message.inbox_id} conversation_id=#{message.conversation_id}/
    )
  end

  it 'still reports when the message is already gone' do
    described_class.call(job_for('SendReplyJob', [-1]), exception)

    expect(Rails.logger).to have_received(:error).with(/\[SIDEKIQ\]\[DEAD\] SendReplyJob/)
  end

  it 'reports a plain Sidekiq worker payload by class and jid' do
    described_class.call({ 'class' => 'PlainWorker', 'args' => [7], 'jid' => 'abc123', 'queue' => 'low' }, exception)

    expect(Rails.logger).to have_received(:error).with(/PlainWorker jid=abc123 queue=low/)
  end

  # Arguments are job payloads: WebhookJob carries the customer's message body and its
  # signing secret positionally, so dumping them here would put message content and a
  # credential into the log aggregator on any unexpected terminal failure. The jid is
  # enough to pull the full payload from the dead set, where access is already controlled.
  it 'never writes job arguments to the log' do
    described_class.call(
      { 'class' => 'WebhookJob', 'args' => ['https://hook.example', { 'content' => 'private' }, 's3cr3t'], 'jid' => 'abc123' },
      exception
    )

    expect(Rails.logger).not_to have_received(:error).with(/s3cr3t|private/)
    expect(Rails.logger).to have_received(:error).with(/WebhookJob jid=abc123/)
  end

  it 'sends the exception to the tracker with the account attached' do
    message = create(:message, message_type: :outgoing)
    tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

    described_class.call(job_for('SendReplyJob', [message.id]), exception)

    expect(ChatwootExceptionTracker).to have_received(:new).with(exception, account: message.account)
  end

  # A death handler that raises takes down the reporting for the job it was reporting.
  it 'never raises out of the handler' do
    allow(Message).to receive(:find_by).and_raise(StandardError, 'db down')

    expect { described_class.call(job_for('SendReplyJob', [1]), exception) }.not_to raise_error
  end

  # The report tells whoever watches logs and Sentry. It never told the one person who can
  # act on it: the agent looking at the conversation, for whom the reply still reads as sent.
  describe 'the message a dead reply left behind' do
    let(:reason) { I18n.with_locale(:pt_BR) { I18n.t('errors.inboxes.channel.outgoing.send_failed_after_retries') } }
    let(:account) { create(:account, locale: 'pt_BR') }
    # Not the default factory inbox: that one is a widget, where this job only sends the
    # email notification and the reply has already reached the customer over the cable.
    let(:inbox) { create(:channel_line, account: account).inbox }
    let(:message) do
      create(:message, message_type: :outgoing, account: account, inbox: inbox,
                       conversation: create(:conversation, account: account, inbox: inbox))
    end

    before do
      allow(Rails.logger).to receive(:warn)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(instance_double(ChatwootExceptionTracker, capture_exception: true))
    end

    it 'marks it failed with a sentence the agent can read' do
      described_class.call(job_for('SendReplyJob', [message.id]), exception)

      expect(message.reload).to have_attributes(status: 'failed', external_error: reason, source_id: nil)
      expect(message.external_error).not_to include('the provider never answered', 'translation missing')
    end

    it 'writes that sentence in the language of the account' do
      english = create(:account, locale: 'en')
      english_inbox = create(:channel_line, account: english).inbox
      other = create(:message, message_type: :outgoing, account: english, inbox: english_inbox,
                               conversation: create(:conversation, account: english, inbox: english_inbox))

      described_class.call(job_for('SendReplyJob', [message.id]), exception)
      described_class.call(job_for('SendReplyJob', [other.id]), exception)

      expect([message.reload.external_error, other.reload.external_error]).to all(be_present)
      expect(message.external_error).not_to eq(other.external_error)
      expect(other.external_error).to eq(I18n.with_locale(:en) do
        I18n.t('errors.inboxes.channel.outgoing.send_failed_after_retries')
      end)
    end

    # Most of the dead set is not SendReplyJob, and for those there is no message to mark:
    # reaching for one anyway would put a resolution warning under every other dead job.
    it 'leaves a message alone when a dead job of another class names it' do
      described_class.call(job_for('WebhookJob', [message.id]), exception)

      expect(message.reload).to have_attributes(status: 'sent', external_error: nil)
      expect(Rails.logger).not_to have_received(:warn)
    end

    # source_id is written only by the provider confirming the message exists, so failing it
    # would invite a resend of something the contact already has.
    it 'leaves a message alone once something proves it left' do
      message.update!(source_id: 'mid.already-out')

      described_class.call(job_for('SendReplyJob', [message.id]), exception)

      expect(message.reload).to have_attributes(status: 'sent', external_error: nil, source_id: 'mid.already-out')
    end

    it 'does not walk a terminal status back to failed' do
      message.update!(status: :delivered)

      described_class.call(job_for('SendReplyJob', [message.id]), exception)

      expect(message.reload).to have_attributes(status: 'delivered', external_error: nil)
    end

    it 'says the same thing when the same job dies twice' do
      described_class.call(job_for('SendReplyJob', [message.id]), exception)
      first = message.reload.external_error

      described_class.call(job_for('SendReplyJob', [message.id]), exception)

      expect(message.reload).to have_attributes(status: 'failed', external_error: first)
    end

    # The reply reached the customer by another path entirely: the widget broadcasts over
    # the cable and the API channel fires a webhook, both when the message is created. All
    # this job does there is queue the email-continuity notification, so a Redis blip that
    # kills it says nothing about the reply -- and marking it failed would tell the agent
    # to resend something the customer is reading on screen.
    it 'leaves a widget reply alone, where the job only sends the notification' do
      widget = create(:channel_widget, account: account)
      conversation = create(:conversation, account: account, inbox: widget.inbox)
      reply = create(:message, message_type: :outgoing, account: account, conversation: conversation, inbox: widget.inbox)

      described_class.call(job_for('SendReplyJob', [reply.id]), exception)

      expect(reply.reload).to have_attributes(status: 'sent', external_error: nil)
    end

    # This job is queued for every message that gets created -- the customer's own, the
    # agent's private notes, the activity lines -- and it is the channel service that
    # decides there is nothing to send. A job that dies before reaching that decision never
    # got to find out, so "failed to send" on one of those rows is a lie about a message
    # nobody was sending.
    it 'leaves alone a message the channel was never going to send' do
      conversation = message.conversation
      others = {
        incoming: create(:message, message_type: :incoming, account: account, inbox: inbox, conversation: conversation),
        note: create(:message, message_type: :outgoing, private: true, account: account, inbox: inbox, conversation: conversation),
        activity: create(:message, message_type: :activity, account: account, inbox: inbox, conversation: conversation)
      }

      others.each_value { |row| described_class.call(job_for('SendReplyJob', [row.id]), exception) }

      expect(others.values.map(&:reload)).to all(have_attributes(status: 'sent', external_error: nil))
    end

    # Two more rows the service would have skipped, both reachable in the same window: a
    # voice-call bubble is a call status indicator, never a send, and a message deleted
    # between its creation and the job's run already reads as removed, so failing it would
    # put an error on something the agent cannot resend and can barely see.
    it 'leaves alone a voice call bubble and a message deleted before the job ran' do
      call = create(:message, message_type: :outgoing, content_type: 'voice_call', account: account, inbox: inbox,
                              conversation: message.conversation)
      deleted = create(:message, message_type: :outgoing, account: account, inbox: inbox, conversation: message.conversation)
      deleted.update!(content_attributes: { deleted: true })

      [call, deleted].each { |row| described_class.call(job_for('SendReplyJob', [row.id]), exception) }

      expect([call.reload, deleted.reload]).to all(have_attributes(status: 'sent', external_error: nil))
    end

    # The one deleted row the channel is still supposed to send. Chatwoot reuses the
    # reaction row and marks it deleted on a toggle, and the empty content it then carries
    # is what clears the emoji on the contact's phone, so a send that never went through
    # has to say so: without it the emoji is gone here and still there for the contact.
    it 'marks a removed reaction whose send died' do
      reaction = create(:message, message_type: :outgoing, account: account, inbox: inbox, conversation: message.conversation)
      reaction.update!(content_attributes: { deleted: true, is_reaction: true })

      described_class.call(job_for('SendReplyJob', [reaction.id]), exception)

      expect(reaction.reload).to have_attributes(status: 'failed', external_error: reason)
    end

    # The tracker call sits between the report and the marking, and the outer rescue would
    # swallow the marking with it. SendReplyJob.report_exhausted_email_failure already
    # settles this order for the retry path: a tracker hiccup must not cost the agent the
    # one signal they can act on.
    it 'still marks the message when the tracker blows up' do
      allow(ChatwootExceptionTracker).to receive(:new).and_raise(StandardError, 'sentry down')

      described_class.call(job_for('SendReplyJob', [message.id]), exception)

      expect(message.reload).to have_attributes(status: 'failed', external_error: reason)
    end

    # The rule this file already lives by: the report is not best-effort and everything
    # around it is. SendReplyJob.fail_message re-raises when it cannot write, which is right
    # inside a retry_on block and would take down the report here.
    it 'still reports when the message cannot be marked' do
      allow(SendReplyJob).to receive(:fail_message).and_raise(StandardError, 'row locked')

      described_class.call(job_for('SendReplyJob', [message.id]), exception)

      expect(Rails.logger).to have_received(:error).with(/the provider never answered/)
      expect(Rails.logger).not_to have_received(:error).with(/handler failed/)
    end
  end

  # Enrichment is best-effort; the report is not. Resolving the message hits the database,
  # and the failures that fill the dead set come with a database in trouble — so an
  # exception there used to take out the line reporting the ORIGINAL error and the tracker
  # call with it, leaving monitoring with "handler failed" and nothing else.
  it 'still reports the original failure when the context lookup blows up' do
    allow(Message).to receive(:find_by).and_raise(StandardError, 'db down')
    allow(ChatwootExceptionTracker).to receive(:new).and_return(instance_double(ChatwootExceptionTracker,
                                                                                capture_exception: true))

    described_class.call(job_for('SendReplyJob', [1]), exception)

    expect(Rails.logger).to have_received(:error).with(/the provider never answered/)
    expect(Rails.logger).not_to have_received(:error).with(/handler failed/)
    expect(ChatwootExceptionTracker).to have_received(:new).with(exception, account: nil)
  end
end
