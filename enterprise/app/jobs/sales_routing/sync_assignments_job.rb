class SalesRouting::SyncAssignmentsJob < ApplicationJob
  queue_as :low
  retry_on PG::Error, wait: :polynomially_longer, attempts: 10

  def perform
    return unless ConversationAssignmentEvent.pending.exists?

    PG.connect(ENV.fetch('HERMES_DISTRIBUTION_DATABASE_URL'), connect_timeout: 5) do |connection|
      connection.exec("SET statement_timeout = '10s'")
      ConversationAssignmentEvent.pending.order(:id).limit(100).each do |event|
        sync_event(connection, event)
      end
    end
  end

  private

  def sync_event(connection, event)
    # Hermes historically stores Chatwoot's display ID in conversation_id; retain that contract.
    connection.exec_params(<<~SQL.squish, event_values(event))
      INSERT INTO distribution_logs
        (event_key, agent_id, agent_name, conversation_id, conversation_display_id, assigned_at, date,
         chatwoot_account_id, chatwoot_inbox_id, chatwoot_conversation_id, event_kind, assignment_source,
         first_customer_message_at, routing)
      VALUES ($1, $2, $3, $4::integer, $4::text, $5::timestamptz AT TIME ZONE 'UTC', $6::date, $7, $8, $9, $10, $11, $12::timestamptz, $13::jsonb)
      ON CONFLICT (event_key) DO NOTHING
    SQL
    event.update!(synced_at: Time.current)
  end

  def event_values(event)
    ["chatwoot:#{event.account_id}:assignment:#{event.id}", event.agent_id, event.agent_name, event.conversation_display_id,
     event.assigned_at.iso8601(6), event.assigned_at.in_time_zone('America/Sao_Paulo').to_date.iso8601,
     event.account_id, event.inbox_id, event.conversation_id, event.event_kind, event.source,
     event.first_customer_message_at&.iso8601(6), event.routing.to_json]
  end
end
