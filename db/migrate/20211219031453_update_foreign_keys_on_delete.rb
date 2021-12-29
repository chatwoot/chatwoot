class UpdateForeignKeysOnDelete < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key 'account_users', 'accounts'
    add_foreign_key 'account_users', 'accounts', on_delete: :cascade

    remove_foreign_key 'account_users', 'users'
    add_foreign_key 'account_users', 'users', on_delete: :cascade

    remove_foreign_key 'agent_bots', 'accounts'
    add_foreign_key 'agent_bots', 'accounts', on_delete: :cascade

    remove_foreign_key 'campaigns', 'accounts'
    add_foreign_key 'campaigns', 'accounts', on_delete: :cascade

    remove_foreign_key 'campaigns', 'inboxes'
    add_foreign_key 'campaigns', 'inboxes', on_delete: :cascade

    remove_foreign_key 'conversations', 'campaigns'
    add_foreign_key 'conversations', 'campaigns', on_delete: :cascade

    remove_foreign_key 'conversations', 'teams'
    add_foreign_key 'conversations', 'teams', on_delete: :cascade

    remove_foreign_key 'csat_survey_responses', 'accounts'
    add_foreign_key 'csat_survey_responses', 'accounts', on_delete: :cascade

    remove_foreign_key 'csat_survey_responses', 'contacts'
    add_foreign_key 'csat_survey_responses', 'contacts', on_delete: :cascade

    remove_foreign_key 'csat_survey_responses', 'conversations'
    add_foreign_key 'csat_survey_responses', 'conversations', on_delete: :cascade

    remove_foreign_key 'csat_survey_responses', 'messages'
    add_foreign_key 'csat_survey_responses', 'messages', on_delete: :cascade

    remove_foreign_key 'csat_survey_responses', 'users', column: 'assigned_agent_id'
    add_foreign_key 'csat_survey_responses', 'users', column: 'assigned_agent_id', on_delete: :cascade

    remove_foreign_key 'data_imports', 'accounts'
    add_foreign_key 'data_imports', 'accounts', on_delete: :cascade

    remove_foreign_key 'mentions', 'conversations'
    add_foreign_key 'mentions', 'conversations', on_delete: :cascade

    remove_foreign_key 'mentions', 'users'
    add_foreign_key 'mentions', 'users', on_delete: :cascade

    remove_foreign_key 'notes', 'accounts'
    add_foreign_key 'notes', 'accounts', on_delete: :cascade

    remove_foreign_key 'notes', 'contacts'
    add_foreign_key 'notes', 'contacts', on_delete: :cascade

    remove_foreign_key 'notes', 'users'
    add_foreign_key 'notes', 'users', on_delete: :cascade

    remove_foreign_key 'team_members', 'teams'
    add_foreign_key 'team_members', 'teams', on_delete: :cascade

    remove_foreign_key 'team_members', 'users'
    add_foreign_key 'team_members', 'users', on_delete: :cascade

    remove_foreign_key 'teams', 'accounts'
    add_foreign_key 'teams', 'accounts', on_delete: :cascade
  end
end
