require 'rails_helper'

# Nobody gives a slot back when its holder died, or when nothing is importing at all, and
# then only this wakes the batches that are waiting.
RSpec.describe Whatsapp::Baileys::HistoryImportWakeJob do
  it 'tops the import slots up from the waiting queue' do
    allow(Whatsapp::Session::Inbound::ImportSlots).to receive(:top_up)

    described_class.perform_now

    expect(Whatsapp::Session::Inbound::ImportSlots).to have_received(:top_up)
      .with(into: Whatsapp::Baileys::HistoryImportJob.queue_name)
  end

  # A drain that could not be queued leaves its files with nobody to fetch them.
  context 'with history files left without a drain' do
    let(:inbox) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false).inbox }
    let(:idle) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false).inbox }

    after do
      [inbox, idle].each do |each_inbox|
        Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(each_inbox))
        Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(each_inbox))
        Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.requeue_key(each_inbox))
      end
    end

    it 'queues a drain for an inbox with files waiting and none for an inbox without' do
      Redis::Alfred.zadd(Whatsapp::Session::HistoryMedia.queue_key(inbox), 1.0, 42)
      idle

      described_class.perform_now

      expect(Whatsapp::Session::HistoryMediaJob).to have_been_enqueued.with(inbox).exactly(:once)
      expect(Whatsapp::Session::HistoryMediaJob).not_to have_been_enqueued.with(idle)
    end

    it 'queues a drain for a rescan request nobody picked up' do
      Redis::Alfred.set(Whatsapp::Session::HistoryMediaJob.requeue_key(inbox), 'x')

      described_class.perform_now

      expect(Whatsapp::Session::HistoryMediaJob).to have_been_enqueued.with(inbox)
    end

    # Its jobs are discarded with it, so nothing else would ever empty its keys.
    it 'drops the keys of an inbox that was deleted' do
      gone = Inbox.new(id: inbox.id)
      Redis::Alfred.zadd(Whatsapp::Session::HistoryMedia.queue_key(gone), 1.0, 42)
      Redis::Alfred.set(Whatsapp::Session::HistoryMediaJob.requeue_key(gone), 'x')
      inbox.destroy!

      described_class.perform_now

      expect(Redis::Alfred.exists?(Whatsapp::Session::HistoryMedia.queue_key(gone))).to be(false)
      expect(Redis::Alfred.exists?(Whatsapp::Session::HistoryMediaJob.requeue_key(gone))).to be(false)
      expect(Whatsapp::Session::HistoryMediaJob).not_to have_been_enqueued
    end

    it 'leaves an inbox with the automatic fetch off alone' do
      Redis::Alfred.zadd(Whatsapp::Session::HistoryMedia.queue_key(inbox), 1.0, 42)
      inbox.channel.update!(provider_config: inbox.channel.provider_config.merge('history_media_fetch' => false))

      described_class.perform_now

      expect(Whatsapp::Session::HistoryMediaJob).not_to have_been_enqueued
    end

    it 'leaves an inbox whose drain is already queued alone' do
      Redis::Alfred.zadd(Whatsapp::Session::HistoryMedia.queue_key(inbox), 1.0, 42)
      Redis::Alfred.set(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox), '1')

      described_class.perform_now

      expect(Whatsapp::Session::HistoryMediaJob).not_to have_been_enqueued
    end
  end

  it 'runs every minute' do
    schedule = YAML.safe_load(Rails.root.join('config/schedule.yml').read)
    entry = schedule.values.find { |job| job['class'] == described_class.name }

    expect(entry).to include('cron' => '* * * * *')
  end
end
