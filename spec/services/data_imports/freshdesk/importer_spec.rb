require 'rails_helper'
require 'timeout'

RSpec.describe DataImports::Freshdesk::Importer do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :freshdesk, account: account) }
  let(:client) { instance_double(DataImports::Freshdesk::Client) }
  let(:contact_payload) do
    JSON.parse(Rails.root.join('spec/fixtures/data_import/freshdesk/contact.json').read)
  end
  let(:ticket_fixture) do
    JSON.parse(Rails.root.join('spec/fixtures/data_import/freshdesk/ticket_with_conversations.json').read)
  end

  before do
    account.enable_features!('data_import')
    allow(DataImports::Freshdesk::Client).to receive(:new).with(
      domain: 'acme.freshdesk.com',
      api_key: 'freshdesk-api-key'
    ).and_return(client)
    allow(client).to receive(:list_contacts).with(page: 1, per_page: 100).and_return(
      DataImports::Freshdesk::Client::Page.new(data: [contact_payload], next_page: nil)
    )
    allow(client).to receive(:list_tickets).with(page: 1, per_page: 100).and_return(
      DataImports::Freshdesk::Client::Page.new(data: [ticket_fixture.fetch('ticket')], next_page: nil)
    )
    allow(client).to receive(:retrieve_ticket).with('2001').and_return(ticket_fixture.fetch('ticket'))
    allow(client).to receive(:list_conversations).with('2001', page: 1, per_page: 100).and_return(
      DataImports::Freshdesk::Client::Page.new(data: ticket_fixture.fetch('conversations'), next_page: nil)
    )
  end

  it 'imports Freshdesk contacts, tickets, replies, and private notes through the shared importer', :aggregate_failures do
    described_class.new(data_import: data_import).perform

    contact = account.contacts.find_by!(email: 'customer@example.com')
    expect(contact).to have_attributes(
      name: 'Customer Example',
      phone_number: '+15551234567',
      identifier: 'customer-1001'
    )
    expect(contact.custom_attributes).to include(
      'freshdesk_contact_id' => '1001',
      'freshdesk_unique_external_id' => 'customer-1001'
    )

    inbox = account.inboxes.find_by!(name: 'Freshdesk Import - Email')
    expect(inbox.channel.additional_attributes).to include(
      'source_provider' => 'freshdesk',
      'source_bucket' => 'email',
      'import_placeholder' => true
    )

    conversation = account.conversations.find_by!(identifier: 'freshdesk:2001')
    expect(conversation).to have_attributes(
      status: 'resolved',
      inbox_id: inbox.id,
      contact_id: contact.id
    )
    expect(conversation.custom_attributes).to include(
      'freshdesk_ticket_id' => '2001',
      'freshdesk_status' => 4,
      'freshdesk_priority' => 2
    )

    messages = conversation.messages.order(:created_at, :id)
    expect(messages.pluck(:content)).to eq(
      [
        "Unable to finish checkout\n\nThe checkout button is not responding.",
        'Could you try this in a private window?',
        "Payments team is investigating the browser logs.\n\n[Freshdesk attachment skipped: 1]",
        'The issue still happens in a private window.'
      ]
    )
    expect(messages.map(&:message_type)).to eq(%w[incoming outgoing outgoing incoming])
    expect(messages.pluck(:private)).to eq([false, false, true, false])
    expect(messages.third.additional_attributes.dig('source', 'conversation_source')).to eq(2)
    expect(messages.third.additional_attributes.dig('source', 'attachments', 0, 'name')).to eq('browser-log.txt')

    expect(data_import.reload).to be_completed
    expect(data_import.stats).to include(
      'contacts' => include('imported' => 1, 'skipped' => 0),
      'conversations' => include('imported' => 1, 'skipped' => 0),
      'messages' => include('imported' => 4, 'skipped' => 0, 'total' => 4),
      'errors' => { 'count' => 0 }
    )
    expect(data_import.processed_records).to eq(6)
    expect(data_import.mappings.count).to eq(6)
  end

  it 'preserves the contact that authored an incoming reply' do
    conversations = ticket_fixture.fetch('conversations').map(&:deep_dup)
    conversations.first.merge!('user_id' => 1002, 'from_email' => 'cc@example.com')
    allow(client).to receive(:list_conversations).with('2001', page: 1, per_page: 100).and_return(
      DataImports::Freshdesk::Client::Page.new(data: conversations, next_page: nil)
    )
    data_import.update!(import_types: ['conversations'])

    described_class.new(data_import: data_import).perform

    reply = account.conversations.find_by!(identifier: 'freshdesk:2001').messages.find_by!(content: 'The issue still happens in a private window.')
    expect(reply.sender).to have_attributes(email: 'cc@example.com')
    expect(reply.sender_id).not_to eq(reply.conversation.contact_id)
  end

  it 'preserves newer progress when a delayed worker persists a stale snapshot', :aggregate_failures do
    data_import.update!(
      status: :processing,
      cursor: { 'contacts' => { 'starting_after' => 'cursor-1', 'completed' => false } },
      stats: {
        'contacts' => { 'total' => 4, 'imported' => 1, 'skipped' => 0 },
        'conversations' => { 'imported' => 0, 'skipped' => 0 },
        'messages' => { 'imported' => 0, 'skipped' => 0 },
        'errors' => { 'count' => 0 }
      },
      processed_records: 1
    )
    data_import.items.create!(
      source_provider: 'freshdesk', source_object_type: 'contact', source_object_id: '1001', status: :imported
    )
    delayed_importer = described_class.new(data_import: DataImport.find(data_import.id))

    data_import.items.create!(
      source_provider: 'freshdesk', source_object_type: 'contact', source_object_id: '1002', status: :imported
    )
    data_import.reload.update!(
      cursor: { 'contacts' => { 'starting_after' => 'cursor-2', 'completed' => false } },
      stats: data_import.stats.deep_merge('contacts' => { 'imported' => 2 }),
      processed_records: 2
    )

    delayed_importer.send(:persist_stats)
    expect(delayed_importer.send(:update_cursor, 'contacts', 'cursor-1')).to eq('cursor-2')

    expect(data_import.reload.cursor.dig('contacts', 'starting_after')).to eq('cursor-2')
    expect(data_import.stats.dig('contacts', 'imported')).to eq(2)
    expect(data_import.processed_records).to eq(2)
  end

  it 'does not let an old import run overwrite its replacement cursor', :aggregate_failures do
    data_import.update!(
      status: :processing,
      source_metadata: data_import.source_metadata.merge('active_import_run_id' => 'run-1'),
      cursor: { 'conversations' => { 'starting_after' => { 'page' => 1, 'offset' => 0 }, 'completed' => false } }
    )
    delayed_importer = described_class.new(data_import: DataImport.find(data_import.id), run_id: 'run-1')
    replacement_cursor = { 'page' => 1, 'offset' => 3 }
    data_import.reload.update!(
      source_metadata: data_import.source_metadata.merge('active_import_run_id' => 'run-2'),
      cursor: { 'conversations' => { 'starting_after' => replacement_cursor, 'completed' => false } }
    )

    result = delayed_importer.send(:update_cursor, 'conversations', { 'page' => 1, 'offset' => 1 })

    expect(result).to eq(replacement_cursor)
    expect(data_import.reload.cursor.dig('conversations', 'starting_after')).to eq(replacement_cursor)
    expect(delayed_importer.send(:import_stopped?)).to be(true)
  end

  it 'serializes overlapping workers importing the same conversation', :aggregate_failures do
    started_requests = Queue.new
    release_requests = Queue.new
    allow(client).to receive(:retrieve_ticket).with('2001') do
      started_requests << true
      release_requests.pop
      ticket_fixture.fetch('ticket')
    end
    importers = Array.new(2) { described_class.new(data_import: DataImport.find(data_import.id)) }
    errors = Concurrent::Array.new
    conversation_summary = { 'id' => '2001', 'source' => { 'type' => 'email' } }
    threads = importers.map do |importer|
      Thread.new do
        importer.send(:import_conversation_from_summary, conversation_summary)
      rescue StandardError => e
        errors << e
      end
    end

    begin
      2.times { Timeout.timeout(5) { started_requests.pop } }
    ensure
      2.times { release_requests << true }
      threads.each { |thread| thread.join(10) }
    end

    expect(threads).to all(satisfy { |thread| !thread.alive? })
    expect(errors).to be_empty
    expect(account.conversations.where(identifier: 'freshdesk:2001').count).to eq(1)
    expect(account.messages.count).to eq(4)
    expect(data_import.mappings.count).to eq(6)
    expect(data_import.items.find_by!(source_object_type: 'conversation', source_object_id: '2001')).to have_attributes(
      status: 'imported', attempt_count: 2
    )
  end

  it 'recognizes a structured cursor after JSON persistence' do
    importer = described_class.new(data_import: data_import)

    importer.send(:update_cursor, 'conversations', { page: 1, offset: 2 })
    data_import.reload
    importer.send(:update_cursor, 'conversations', nil)

    expect(data_import.reload.cursor['conversations']).to include('starting_after' => nil, 'completed' => true)
  end

  it 'resumes a rate-limited ticket chunk from the last persisted checkpoint', :aggregate_failures do
    tickets = Array.new(3) { |index| { 'id' => index + 2001, 'source' => 1 } }
    allow(client).to receive(:list_tickets).with(page: 1, per_page: 100).and_return(
      DataImports::Freshdesk::Client::Page.new(data: tickets, next_page: nil)
    )
    importer = described_class.new(data_import: data_import)
    processed_ticket_ids = []
    rate_limited = true
    allow(importer).to receive(:import_conversation_from_summary) do |summary|
      processed_ticket_ids << summary['id']
      if summary['id'] == '2003' && rate_limited
        rate_limited = false
        raise DataImports::Freshdesk::Client::RateLimitError.new('Rate limited', retry_after: '42')
      end
    end

    expect do
      importer.import_conversations_page(starting_after: { 'page' => 1, 'offset' => 0 })
    end.to raise_error(DataImports::Freshdesk::Client::RateLimitError)
    expect(processed_ticket_ids).to eq(%w[2001 2002 2003])
    expect(data_import.reload.cursor.dig('conversations', 'starting_after')).to include('page' => 1, 'offset' => 2)

    processed_ticket_ids.clear
    result = importer.import_conversations_page(starting_after: { 'page' => 1, 'offset' => 0 })

    expect(processed_ticket_ids).to eq(%w[2003])
    expect(result).to be_done
    expect(data_import.reload.cursor['conversations']).to include('starting_after' => nil, 'completed' => true)
    expect(client).to have_received(:list_tickets).once
  end

  it 'stops a delayed worker when a newer per-ticket checkpoint is observed', :aggregate_failures do
    current_cursor = { 'page' => 1, 'offset' => 0, 'tickets' => [], 'next_page' => 2 }
    newer_cursor = current_cursor.merge('offset' => 3)
    summaries = Array.new(3) { |index| { 'id' => (index + 2001).to_s } }
    response = {
      'data' => summaries,
      'pages' => {
        'current' => { 'starting_after' => current_cursor },
        'next' => { 'starting_after' => { 'page' => 2, 'offset' => 0 } },
        'checkpoints' => Array.new(3) { |index| current_cursor.merge('offset' => index + 1) }
      }
    }
    importer = described_class.new(data_import: DataImport.find(data_import.id))
    allow(importer).to receive(:conversations_page).and_return(response)
    cursor_advanced = false
    allow(importer).to receive(:persist_stats).and_wrap_original do |method, *args|
      method.call(*args)
      next if cursor_advanced

      cursor_advanced = true
      concurrent_import = DataImport.find(data_import.id)
      concurrent_import.update!(
        cursor: concurrent_import.cursor.to_h.deep_merge(
          'conversations' => { 'starting_after' => newer_cursor, 'completed' => false }
        )
      )
    end

    result = importer.import_conversations_page(starting_after: current_cursor)

    expect(account.conversations.where(identifier: 'freshdesk:2001').count).to eq(1)
    expect(client).not_to have_received(:retrieve_ticket).with('2002')
    expect(result.next_cursor).to eq(newer_cursor)
    expect(data_import.reload.cursor.dig('conversations', 'starting_after')).to eq(newer_cursor)
  end

  it 'fails with an actionable error instead of completing at the REST ticket limit', :aggregate_failures do
    tickets = Array.new(100) { |index| { 'id' => index + 1, 'source' => 1 } }
    allow(client).to receive(:list_tickets).with(page: 300, per_page: 100).and_return(
      DataImports::Freshdesk::Client::Page.new(data: tickets, next_page: nil)
    )
    importer = described_class.new(data_import: data_import)
    processed_ticket_ids = []
    allow(importer).to receive(:import_conversation_from_summary) { |summary| processed_ticket_ids << summary['id'] }
    limit_error = nil

    expect { importer.import_conversations_page(starting_after: { 'page' => 300, 'offset' => 90 }) }.to raise_error do |error|
      expect(error.class.name).to eq('CustomExceptions::DataImport::FreshdeskTicketLimitError')
      limit_error = error
    end
    importer.fail!(limit_error)

    expect(processed_ticket_ids).to eq((91..100).map(&:to_s))
    expect(data_import.reload).to be_failed
    expect(data_import.cursor.dig('conversations', 'starting_after')).to include('page' => 300, 'offset' => 99)
    expect(data_import.import_errors.last).to have_attributes(
      error_code: 'CustomExceptions::DataImport::FreshdeskTicketLimitError',
      message: limit_error.message
    )
    expect(data_import.import_errors.last.details).to include(
      'kind' => 'run_error',
      'source_provider' => 'freshdesk',
      'error_class' => 'CustomExceptions::DataImport::FreshdeskTicketLimitError'
    )
  end
end
