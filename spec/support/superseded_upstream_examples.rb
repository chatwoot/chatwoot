# Upstream examples under spec/enterprise that cannot pass on this fork, skipped by name so the
# files themselves stay identical to upstream. None of them is about Enterprise code the fork
# changed, since it changes none: each one runs into a CE difference of the fork, into a date
# upstream pinned, into a service the fork's suite does not run, or into an example upstream
# broke for everyone. The reason says which.
VERSION_CHECK_REASON = "the fork's version check also reads the fork's own releases (GitHub on CE, the fazer.ai hub on Pro), " \
                       'which the example does not stub'.freeze

SUPERSEDED_UPSTREAM_EXAMPLES = {
  'spec/enterprise/jobs/enterprise/internal/check_new_versions_job_spec.rb' => {
    'updates the plan info' => "the fork's CE version check reads fazer-ai/chatwoot's releases, which the example does not stub",
    'calls Internal::ReconcilePlanConfigService' => "the fork's CE version check reads fazer-ai/chatwoot's releases, which the example does not stub",
    'reports whether hub was reached' => VERSION_CHECK_REASON,
    'stores the new status and notifies every account with its own account id' => VERSION_CHECK_REASON,
    'does not notify accounts when the status is unchanged' => VERSION_CHECK_REASON,
    'keeps the last known status when an older hub omits it' => VERSION_CHECK_REASON,
    'clears the status when hub returns null' => VERSION_CHECK_REASON
  },
  'spec/enterprise/models/integrations/hook_spec.rb' => {
    'keeps monitor Slack channels when another integration is removed' =>
      "upstream's :google_translate factory saves an empty key, which upstream's own credentials check refuses, so it fails everywhere"
  },
  'spec/enterprise/services/voice/call_transcription_service_spec.rb' => {
    'reindexes before broadcasting so a retry after a reindex failure does not resend the update event' =>
      'Message defines #reindex only when OPENSEARCH_URL is set at boot, and the fork runs its suite without OpenSearch'
  },
  'spec/enterprise/models/applied_sla_spec.rb' => {
    'excludes blocked contacts and keeps conversations with missing contacts' =>
      'conversations.contact_id is NOT NULL on the fork, so a conversation without a contact cannot be built'
  },
  'spec/enterprise/models/conversation_spec.rb' => {
    'keeps existing behavior when contact is missing' =>
      'conversations.contact_id is NOT NULL on the fork, so a conversation without a contact cannot be built'
  },
  'spec/enterprise/services/conversation_monitors/evaluator_spec.rb' => {
    'holds exhausted accounts until next month and preserves full history across new input' =>
      'upstream pins the example to 2026-10-31, before the work item its before block builds, so it fails everywhere after that date',
    'preserves the monthly hold through an earlier batch provider cooldown after the reset' =>
      'upstream pins the example to 2026-10-31, before the work item its before block builds, so it fails everywhere after that date'
  }
}.freeze

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/enterprise/}) do |metadata|
    file = metadata[:file_path].to_s.delete_prefix('./')
    reason = SUPERSEDED_UPSTREAM_EXAMPLES.dig(file, metadata[:description])
    metadata[:skip] = "not run on this fork: #{reason}" if reason
  end
end
