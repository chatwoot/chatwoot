require 'rails_helper'

RSpec.describe Internal::ClassifyContactsJob do
  # contacts older than the retention period, so the walk reaches them
  let(:account) { create(:account) }
  let(:old) { { account: account, created_at: 60.days.ago } }
  let(:cursor_key) { Redis::Alfred::CONTACT_CLASSIFY_CURSOR }
  let(:paused_key) { Redis::Alfred::CONTACT_CLASSIFY_PAUSED }
  let(:running_key) { Redis::Alfred::CONTACT_CLASSIFY_RUNNING }

  after do
    [cursor_key, paused_key, running_key].each { |key| Redis::Alfred.delete(key) }
  end

  it 'runs on the migration queue' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class).on_queue('async_database_migration')
  end

  it 'classifies contacts up to the retention line and keeps the cursor for the next run' do
    contact = create(:contact, **old, name: 'Maria Lopez')
    recent = create(:contact, account: account, name: 'John Smith')

    expect { described_class.perform_now }.not_to have_enqueued_job(described_class)

    expect(contact.reload).to be_lead
    expect(recent.reload).to be_visitor
    expect(Redis::Alfred.get(cursor_key).to_i).to eq(contact.id)
    expect(Redis::Alfred.get(running_key)).to be_nil
  end

  it 'does not start a second walk while one is in progress' do
    contact = create(:contact, **old, name: 'Maria Lopez')
    Redis::Alfred.set(running_key, 1)

    described_class.perform_now

    expect(contact.reload).to be_visitor
  end

  it 'hands the rest of the table to the next run when its time is up' do
    first = create(:contact, account: account, name: 'Maria Lopez')
    last = create(:contact, account: account, name: 'John Smith')
    stub_const("#{described_class}::WINDOW", 1)
    allow(Time).to receive(:current).and_return(Time.zone.now, Time.zone.now, 1.minute.from_now)

    expect { described_class.perform_now(first.id, last.id, 1) }.to have_enqueued_job(described_class).with(first.id + 1, last.id, 1)

    expect(Redis::Alfred.get(cursor_key).to_i).to eq(first.id)
  end

  it 'resumes after the saved cursor' do
    below = create(:contact, **old, name: 'Maria Lopez')
    above = create(:contact, **old, name: 'John Smith')
    Redis::Alfred.set(cursor_key, below.id)

    described_class.perform_now

    expect(below.reload).to be_visitor
    expect(above.reload).to be_lead
  end

  it 'waits and checks again while it is paused, keeping its position' do
    contact = create(:contact, **old, name: 'Maria Lopez')
    Redis::Alfred.set(paused_key, 1)

    expect { described_class.perform_now }.to have_enqueued_job(described_class)
      .with(1, contact.id, described_class::WINDOW).at(a_value_within(1.minute).of(5.minutes.from_now))

    expect(contact.reload).to be_visitor
  end

  it 'keeps a window small enough to finish within its time budget at the current pace' do
    contact = create(:contact, account: account, name: 'Maria Lopez')
    allow(Contacts::ClassifyVisitorsService).to receive(:rows_per_second).and_return(100)
    allow(Contacts::ClassifyVisitorsService).to receive(:new).and_call_original

    described_class.perform_now(contact.id, contact.id + 2_999)

    expect(Contacts::ClassifyVisitorsService).to have_received(:new).with(from_id: contact.id, to_id: contact.id + 1_499)
    expect(Contacts::ClassifyVisitorsService).to have_received(:new).with(from_id: contact.id + 1_500, to_id: contact.id + 2_999)
  end

  it 'honours a rate too low for the timeout floor' do
    contact = create(:contact, account: account, name: 'Maria Lopez')
    allow(Contacts::ClassifyVisitorsService).to receive(:rows_per_second).and_return(10)
    allow(Contacts::ClassifyVisitorsService).to receive(:new).and_call_original

    described_class.perform_now(contact.id, contact.id + 149)

    expect(Contacts::ClassifyVisitorsService).to have_received(:new).once.with(from_id: contact.id, to_id: contact.id + 149)
  end

  it 'reads a window again at half the size it actually used when the read times out' do
    contact = create(:contact, account: account, name: 'Maria Lopez')
    service = instance_double(Contacts::ClassifyVisitorsService, perform: { visitors: 1, promoted: 1, purged: 0 })
    allow(Contacts::ClassifyVisitorsService).to receive(:new).with(from_id: contact.id, to_id: contact.id + 3_749)
                                                             .and_raise(ActiveRecord::QueryCanceled)
    allow(Contacts::ClassifyVisitorsService).to receive(:new).with(from_id: contact.id, to_id: contact.id + 1_874).and_return(service)
    allow(Contacts::ClassifyVisitorsService).to receive(:new).with(from_id: contact.id + 1_875, to_id: contact.id + 3_749).and_return(service)

    described_class.perform_now(contact.id, contact.id + 3_749)

    expect(service).to have_received(:perform).twice
  end
end
