# frozen_string_literal: true

# Run with: bundle exec rails runner script/copilot_v2_evaluate.rb -- --case app_boundary
# This script creates and deletes only its own synthetic development account.
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
require 'optparse'
require 'English'
require 'yaml'
require 'fileutils'
require 'active_job/queue_adapters/test_adapter'

class CopilotV2Evaluation # rubocop:disable Metrics/ClassLength
  def initialize(arguments) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @options = { split: 'development', live: false, output: Rails.root.join('tmp/copilot-v2-evaluation.json').to_s }
    OptionParser.new do |parser|
      parser.on('--split NAME') { |value| @options[:split] = value }
      parser.on('--case ID') { |value| @options[:case] = value }
      parser.on('--live') { @options[:live] = true }
      parser.on('--development-frozen') { @options[:development_frozen] = true }
      parser.on('--output PATH') { |value| @options[:output] = value }
    end.parse!(arguments.reject { |arg| arg == '--' })
    raise 'Development environment required' unless Rails.env.development?
    raise 'Use development or holdout split' unless %w[development holdout].include?(@options[:split])
    if @options[:live] && @options[:split] == 'holdout' && !@options[:development_frozen]
      raise 'Freeze development prompts and reviewed labels before running holdout; then pass --development-frozen'
    end

    @corpus = YAML.safe_load_file(Rails.root.join('spec/fixtures/copilot/v2/evaluation.yml'))
    @cases = @corpus.fetch('cases').select { |entry| entry['split'] == @options[:split] && (!@options[:case] || entry['id'] == @options[:case]) }
    raise 'No cases matched' if @cases.empty?

    @report = { 'corpus_version' => @corpus.fetch('version'), 'label_status' => @corpus.fetch('label_status'),
                'mode' => @options[:live] ? 'live' : 'dry_run', 'split' => @options[:split], 'cases' => [] }
  end

  def call
    previous_adapter = ActiveJob::Base.queue_adapter
    @adapter = ActiveJob::QueueAdapters::TestAdapter.new
    ActiveJob::Base.queue_adapter = @adapter
    @cases.each { |entry| evaluate(entry) }
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter if previous_adapter
    FileUtils.mkdir_p(File.dirname(@options.fetch(:output)))
    File.write(@options.fetch(:output), JSON.pretty_generate(@report))
    puts @options.fetch(:output)
  end

  private

  def evaluate(entry)
    @case_result = { 'id' => entry.fetch('id'), 'expected_provisional' => entry.fetch('expected'),
                     'independent_review' => { 'semantic_accuracy' => 'pending', 'citation_support' => 'pending',
                                               'final_answer_completeness' => 'pending' } }
    @report['cases'] << @case_result
    setup_records(entry)
    verify_destination!
    create_run(entry)
    @case_result['sources'] = @sources
    @case_result['request'] = @run.task_spec.fetch('request')
    @case_result['initial_api_result'] = api_get(@run_url)
    if @options[:live]
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      250.times do
        break unless %w[queued running].include?(@run.reload.status)

        Copilot::V2::RunJob.perform_now(@run.id)
      end
      @case_result['elapsed_seconds'] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end
    @case_result['api_result'] = api_get(@run_url)
    @case_result['operations'] = @run.reload.checkpoint.fetch('operations', [])
    @case_result['captured_items'] = @run.copilot_run_items.order(:id).map do |item|
      item.attributes.slice('dataset_key', 'resource_type', 'resource_id', 'state', 'captured', 'result', 'reason', 'supplied')
    end
    @case_result['structural_checks'] = structural_checks
    @case_result['cost'] = { 'status' => 'not_calculated', 'reason' => 'Review token usage and approved model pricing separately.' }
  rescue StandardError => e
    @case_result['error'] = { 'class' => e.class.name, 'message' => e.message }
    raise
  ensure
    original_error = $ERROR_INFO
    begin
      cleanup
    rescue StandardError => e
      @case_result['cleanup_error'] = { 'class' => e.class.name, 'message' => e.message }
      raise unless original_error
    end
  end

  def setup_records(entry)
    @account = nil
    @user = nil
    @now = Time.current.change(usec: 0)
    @account = Account.create!(name: "Copilot synthetic evaluation #{SecureRandom.hex(6)}", locale: 'en', limits: { captain_responses: 100 })
    @case_result['synthetic_account_id'] = @account.id
    @account.enable_features!('copilot_v2')
    @user = User.create!(name: 'Synthetic evaluator', email: "copilot-eval-#{SecureRandom.hex(8)}@example.invalid",
                         password: "Aa1!#{SecureRandom.hex(16)}", confirmed_at: @now)
    @case_result['synthetic_user_id'] = @user.id
    AccountUser.create!(account: @account, user: @user, role: :administrator)
    channel = Channel::Api.create!(account: @account)
    @case_result['synthetic_channel_id'] = channel.id
    @inbox = Inbox.create!(account: @account, channel: channel, name: 'Synthetic inbox')
    @case_result['synthetic_inbox_id'] = @inbox.id
    InboxMember.create!(inbox: @inbox, user: @user)
    @contacts = @corpus.fetch('contacts').transform_values { |attributes| @account.contacts.create!(attributes) }
    @case_result['synthetic_contact_ids'] = @contacts.values.map(&:id)
    @case_result['synthetic_conversation_ids'] = []
    @case_result['synthetic_message_ids'] = []
    @sources = { 'contacts' => @contacts.transform_values { |contact| contact.attributes.slice('id', 'name', 'email') }, 'conversations' => {} }
    Array(entry['conversations']).each { |definition| create_conversation(definition) }
  end

  def create_conversation(definition)
    contact = @contacts.fetch(definition.fetch('contact'))
    contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: @inbox) { |record| record.source_id = SecureRandom.uuid }
    conversation = @account.conversations.create!(inbox: @inbox, contact: contact, contact_inbox: contact_inbox,
                                                  created_at: @now - definition.fetch('created_days_ago', 1).days)
    @case_result['synthetic_conversation_ids'] << conversation.id
    messages = definition.fetch('messages').to_h do |source|
      agent = source['speaker'] == 'agent'
      message = conversation.messages.create!(account: @account, inbox: @inbox, sender: agent ? @user : contact,
                                              message_type: agent ? :outgoing : :incoming, content: source.fetch('text'),
                                              created_at: @now - source.fetch('days_ago', 1).days)
      @case_result['synthetic_message_ids'] << message.id
      message.attachments.create!(account: @account, file_type: :file) if source['attachment']
      [source.fetch('key'), Copilot::V2::EvidenceSerializer.message(message.reload)]
    end
    @sources['conversations'][definition.fetch('key')] = { 'id' => conversation.id, 'display_id' => conversation.display_id,
                                                           'contact_id' => contact.id, 'created_at' => conversation.created_at.iso8601,
                                                           'messages' => messages }
  end

  def verify_destination!
    service = Copilot::V2::ChatService.new(account: @account, user: @user, thread: nil)
    endpoint = RubyLLM::Providers::OpenAI.new(RubyLLM.config).api_base.delete_suffix('/')
    provider = Llm::Models.provider_for(service.model)
    raise 'Only https://api.openai.com/v1 with an OpenAI model is allowed' unless endpoint == 'https://api.openai.com/v1' && provider == 'openai'

    @case_result['provider'] = { 'endpoint' => endpoint, 'model' => service.model, 'provider' => provider }
  end

  def create_run(entry)
    @session = ActionDispatch::Integration::Session.new(Rails.application)
    @session.host! 'localhost'
    @headers = @user.create_new_auth_token
    base = "/api/v1/accounts/#{@account.id}/captain/copilot_threads"
    request = format(entry.fetch('request'), since: (@now - 7.days).iso8601, until: (@now + 1.hour).iso8601)
    @session.post(base, params: { message: request }, headers: @headers, as: :json)
    raise "Thread creation returned HTTP #{@session.response.status}" unless @session.response.successful?

    thread_id = @session.response.parsed_body.fetch('id')
    messages = api_get("#{base}/#{thread_id}/copilot_messages").fetch('payload')
    run_id = messages.find { |message| message['message_type'] == 'user' }.fetch('copilot_run_id')
    @run = @account.copilot_threads.find(thread_id).copilot_runs.find(run_id)
    @run_url = "#{base}/#{thread_id}/copilot_runs/#{run_id}"
  end

  def api_get(path)
    @session.get(path, headers: @headers, as: :json)
    raise "GET returned HTTP #{@session.response.status}" unless @session.response.successful?

    @session.response.parsed_body
  end

  def structural_checks
    results = @case_result.fetch('api_result').fetch('results', [])
    checks = { 'api_matches_persisted_run' => @case_result['api_result']['run_id'] == @run.id,
               'execution_stopped' => %w[queued running].exclude?(@run.status),
               'model_calls' => @run.budget.fetch('logical_model_calls', 0),
               'dry_run_made_no_model_calls' => @options[:live] ? nil : @run.budget.empty? }
    checks['result_contracts'] = results.filter_map do |result|
      next unless result['reference_type'] == 'result'

      selected, resolved, unresolved = result.values_at('selected_ids', 'resolved_ids', 'unresolved_ids')
      { 'reference' => result['reference'], 'identity_partition' => selected.sort == (resolved + unresolved).sort && !resolved.intersect?(unresolved),
        'selected_matches_case_scope' => selected.sort == @sources.fetch('conversations').values.pluck('id').sort,
        'citations_belong_to_parent' => citations_valid?(result),
        'no_duplicate_rows' => result.fetch('rows').pluck('record_id').uniq.size == result.fetch('rows').size,
        'decision_arithmetic' => result.values_at('match_count', 'no_match_count', 'uncertain_count').sum == result.fetch('resolved_count'),
        'selected_ids' => selected, 'resolved_ids' => resolved, 'unresolved_ids' => unresolved,
        'retrieved_evidence_count' => result['retrieved_evidence_count'], 'supplied_evidence_count' => result['supplied_evidence_count'] }
    end
    checks
  end

  def citations_valid?(result)
    @run.copilot_run_items.where(dataset_key: result.fetch('reference'), state: 'resolved').all? do |item|
      sources = item.evidence.fetch('records').to_h { |record| [record.fetch('id'), Array(record['parts']).pluck('id')] }
      Array(item.result['citations']).all? do |citation|
        sources.fetch(citation.fetch('record_id'), []).include?(citation.fetch('part_id'))
      end
    end
  end

  def cleanup # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return unless @account || @user

    account_id = @account&.id
    user_id = @user&.id
    # Run only dependent-deletion jobs; notification, delivery and model jobs remain disabled.
    @adapter.filter = [ActiveRecord::DestroyAssociationAsyncJob]
    @adapter.perform_enqueued_jobs = true
    thread_ids = CopilotThread.where(account_id: account_id).pluck(:id)
    run_ids = CopilotRun.where(copilot_thread_id: thread_ids).pluck(:id)
    @account&.copilot_threads&.destroy_all
    @account&.messages&.destroy_all
    @account&.conversations&.destroy_all
    @account&.contacts&.destroy_all
    @account&.inboxes&.destroy_all
    @account&.destroy!
    @user&.destroy!
    remaining = { 'account' => Account.where(id: account_id).count, 'user' => User.where(id: user_id).count,
                  'contacts' => Contact.where(account_id: account_id).count, 'conversations' => Conversation.where(account_id: account_id).count,
                  'messages' => Message.where(account_id: account_id).count, 'threads' => CopilotThread.where(account_id: account_id).count,
                  'runs' => CopilotRun.where(copilot_thread_id: thread_ids).count,
                  'items' => CopilotRunItem.where(copilot_run_id: run_ids).count, 'attachments' => Attachment.where(account_id: account_id).count,
                  'inboxes' => Inbox.where(account_id: account_id).count, 'channels' => Channel::Api.where(account_id: account_id).count }
    @case_result['cleanup_remaining'] = remaining
    raise "Synthetic cleanup incomplete: #{remaining}" unless remaining.values.all?(&:zero?)
  ensure
    @adapter.perform_enqueued_jobs = false if @adapter
    @adapter.filter = nil if @adapter
    @adapter&.enqueued_jobs&.clear
    @account = @user = nil
  end
end

CopilotV2Evaluation.new(ARGV).call
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
