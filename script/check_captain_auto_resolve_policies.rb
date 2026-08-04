# Usage:
#   bundle exec rails runner script/check_captain_auto_resolve_policies.rb
#
# Optional overrides:
#   ACCOUNT_ID=1 ASSISTANT_IDS=1,184 bundle exec rails runner script/check_captain_auto_resolve_policies.rb
#
# The script runs each scenario in a database transaction and rolls it back.
# Langfuse traces are exported, but local test records and config changes are not kept.

class CaptainAutoResolvePolicyCheck
  MESSAGE_TRANSCRIPT = [
    [:incoming, 'What are your support hours?'],
    [:outgoing, 'Support is available Monday through Friday, from 9 AM to 5 PM UTC.'],
    [:incoming, 'Thanks, that answers my question.']
  ].freeze

  def initialize
    @account = Account.find(Integer(ENV.fetch('ACCOUNT_ID', '1'), 10))
    @assistant_ids = ENV.fetch('ASSISTANT_IDS', '1,184').split(',').map { |id| Integer(id, 10) }
    raise 'ASSISTANT_IDS must contain exactly two IDs' unless @assistant_ids.size == 2

    @assistants = @assistant_ids.map { |id| @account.captain_assistants.find(id) }
    @original_configs = @assistants.to_h { |assistant| [assistant.id, assistant.config.deep_dup] }
  end

  def perform
    validate_environment!
    print_starting_state

    results = scenarios.map { |scenario| run_scenario(scenario) }
    flush_langfuse
    print_results(results)
    verify_original_state!
  end

  private

  def scenarios
    first_id, second_id = @assistant_ids

    [
      { name: 'disabled and evaluated', modes: { first_id => 'disabled', second_id => 'evaluated' } },
      { name: 'legacy and evaluated', modes: { first_id => 'legacy', second_id => 'evaluated' } },
      { name: 'evaluated and disabled', modes: { first_id => 'evaluated', second_id => 'disabled' } },
      { name: 'evaluated and legacy', modes: { first_id => 'evaluated', second_id => 'legacy' } }
    ]
  end

  def validate_environment!
    raise 'This script can only run in development' unless Rails.env.development?
    raise "Account #{@account.id} must have captain_tasks enabled" unless @account.feature_enabled?('captain_tasks')
    raise 'OpenTelemetry must be enabled for Langfuse verification' unless ChatwootApp.otel_enabled?
    raise 'CAPTAIN_OPEN_AI_API_KEY must be configured' if InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.blank?
  end

  def print_starting_state
    puts JSON.pretty_generate(
      account: {
        id: @account.id,
        name: @account.name,
        captain_tasks: @account.feature_enabled?('captain_tasks'),
        account_mode: @account.settings['captain_auto_resolve_mode']
      },
      assistants: @assistants.map do |assistant|
        {
          id: assistant.id,
          name: assistant.name,
          stored_mode: assistant.config['auto_resolve_mode'],
          effective_mode: assistant.auto_resolve_mode
        }
      end
    )
  end

  def run_scenario(scenario)
    result = nil

    ActiveRecord::Base.transaction(requires_new: true) do
      scenario[:modes].each do |assistant_id, mode|
        @assistants.find { |assistant| assistant.id == assistant_id }.reload.update!(auto_resolve_mode: mode)
      end

      checks = @assistants.map do |assistant|
        run_assistant_check(assistant.reload, scenario[:modes].fetch(assistant.id), scenario[:name])
      end

      result = { scenario: scenario[:name], checks: checks }
      raise ActiveRecord::Rollback
    end

    result
  end

  def run_assistant_check(assistant, mode, scenario_name)
    inbox = create_test_inbox(assistant, scenario_name)
    conversation = create_test_conversation(inbox, assistant)
    message_count_before = conversation.messages.count

    Captain::InboxPendingConversationsResolutionJob.perform_now(inbox)
    conversation.reload

    check = {
      assistant_id: assistant.id,
      assistant_name: assistant.name,
      stored_mode: assistant.config['auto_resolve_mode'],
      account_mode: @account.settings['captain_auto_resolve_mode'],
      result_status: conversation.status,
      messages_added: conversation.messages.count - message_count_before,
      private_notes: conversation.messages.where(private: true).pluck(:content),
      langfuse_trace_expected: mode == 'evaluated',
      langfuse_session_id: "#{@account.id}_#{conversation.display_id}"
    }

    verify_check!(check, mode)
    check
  end

  def create_test_inbox(assistant, scenario_name)
    channel = Channel::Api.create!(account: @account)
    inbox = Inbox.create!(
      account: @account,
      channel: channel,
      name: "Policy check #{scenario_name} assistant #{assistant.id}"
    )
    CaptainInbox.create!(inbox: inbox, captain_assistant: assistant)
    inbox
  end

  def create_test_conversation(inbox, assistant)
    contact = Contact.create!(
      account: @account,
      name: "Policy check for assistant #{assistant.id}",
      email: "captain-policy-#{SecureRandom.hex(8)}@example.com"
    )
    contact_inbox = ContactInbox.create!(contact: contact, inbox: inbox, source_id: SecureRandom.uuid)
    conversation = Conversation.create!(
      account: @account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      status: :pending
    )

    create_test_messages(conversation, contact, assistant)
    conversation.update!(status: :pending, last_activity_at: 2.hours.ago, waiting_since: 2.hours.ago)
    conversation.reload
  end

  def create_test_messages(conversation, contact, assistant)
    MESSAGE_TRANSCRIPT.each do |message_type, content|
      sender = message_type == :incoming ? contact : assistant
      conversation.messages.create!(
        account: @account,
        inbox: conversation.inbox,
        sender: sender,
        message_type: message_type,
        content: content
      )
    end
  end

  def verify_check!(check, mode)
    raise "Policy was not stored on assistant #{check[:assistant_id]}" unless check[:stored_mode] == mode

    send("verify_#{mode}!", check)
  end

  def verify_disabled!(check)
    return if check[:result_status] == 'pending' && check[:messages_added].zero?

    raise 'Disabled mode changed the conversation'
  end

  def verify_legacy!(check)
    return if check[:result_status] == 'resolved' && check[:private_notes].empty?

    raise 'Legacy mode did not resolve by time'
  end

  def verify_evaluated!(check)
    raise 'Evaluated mode did not record an evaluation result' if check[:private_notes].empty?
  end

  def flush_langfuse
    OpenTelemetry.tracer_provider.force_flush
  end

  def print_results(results)
    puts JSON.pretty_generate(results)
  end

  def verify_original_state!
    @assistants.each do |assistant|
      assistant.reload
      next if assistant.config == @original_configs.fetch(assistant.id)

      raise "Assistant #{assistant.id} config was not rolled back"
    end

    puts 'All scenarios passed. Assistant configs and test records were rolled back.'
  end
end

CaptainAutoResolvePolicyCheck.new.perform
