class RevertCascadingIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key 'account_users', 'accounts' if foreign_key_exists? 'account_users', 'accounts'
    remove_foreign_key 'account_users', 'users' if foreign_key_exists? 'account_users', 'users'
    remove_foreign_key 'agent_bots', 'accounts' if foreign_key_exists? 'agent_bots', 'accounts'
    remove_foreign_key 'campaigns', 'accounts' if foreign_key_exists? 'campaigns', 'accounts'
    remove_foreign_key 'campaigns', 'inboxes' if foreign_key_exists? 'campaigns', 'inboxes'
    remove_foreign_key 'conversations', 'campaigns' if foreign_key_exists? 'conversations', 'campaigns'
    remove_foreign_key 'conversations', 'contact_inboxes' if foreign_key_exists? 'conversations', 'contact_inboxes'
    remove_foreign_key 'conversations', 'teams' if foreign_key_exists? 'conversations', 'teams'
    remove_foreign_key 'csat_survey_responses', 'accounts' if foreign_key_exists? 'csat_survey_responses', 'accounts'
    remove_foreign_key 'csat_survey_responses', 'contacts' if foreign_key_exists? 'csat_survey_responses', 'contacts'
    remove_foreign_key 'csat_survey_responses', 'conversations' if foreign_key_exists? 'csat_survey_responses', 'conversations'
    remove_foreign_key 'csat_survey_responses', 'messages' if foreign_key_exists? 'csat_survey_responses', 'messages'
    remove_foreign_key 'csat_survey_responses', 'users', column: 'assigned_agent_id' if foreign_key_exists? 'csat_survey_responses', 'users',
                                                                                                            column: 'assigned_agent_id'
    remove_foreign_key 'data_imports', 'accounts' if foreign_key_exists? 'data_imports', 'accounts'
    remove_foreign_key 'mentions', 'conversations' if foreign_key_exists? 'mentions', 'conversations'
    remove_foreign_key 'mentions', 'users' if foreign_key_exists? 'mentions', 'users'
    remove_foreign_key 'notes', 'accounts' if foreign_key_exists? 'notes', 'accounts'
    remove_foreign_key 'notes', 'contacts' if foreign_key_exists? 'notes', 'contacts'
    remove_foreign_key 'notes', 'users' if foreign_key_exists? 'notes', 'users'
    remove_foreign_key 'team_members', 'teams' if foreign_key_exists? 'team_members', 'teams'
    remove_foreign_key 'team_members', 'users' if foreign_key_exists? 'team_members', 'users'
    remove_foreign_key 'teams', 'accounts' if foreign_key_exists? 'teams', 'accounts'
    remove_foreign_key 'contact_inboxes', 'contacts' if foreign_key_exists? 'contact_inboxes', 'contacts'
    remove_foreign_key 'contact_inboxes', 'inboxes' if foreign_key_exists? 'contact_inboxes', 'inboxes'

    remove_foreign_key 'articles', 'articles', column: 'associated_article_id' if foreign_key_exists? 'articles', 'articles',
                                                                                                      column: 'associated_article_id'
    remove_foreign_key 'articles', 'users', column: 'author_id' if foreign_key_exists? 'articles', 'users', column: 'author_id'

    remove_foreign_key 'categories', 'categories', column: 'parent_category_id' if foreign_key_exists? 'categories', 'categories',
                                                                                                       column: 'parent_category_id'
    remove_foreign_key 'categories', 'categories', column: 'associated_category_id' if foreign_key_exists? 'categories', 'categories',
                                                                                                           column: 'associated_category_id'

    remove_foreign_key 'dashboard_apps', 'accounts' if foreign_key_exists? 'dashboard_apps', 'accounts'
    remove_foreign_key 'dashboard_apps', 'users' if foreign_key_exists? 'dashboard_apps', 'users'

    remove_foreign_key 'macros', 'users', column: 'created_by_id' if foreign_key_exists? 'macros', 'users', column: 'created_by_id'
    remove_foreign_key 'macros', 'users', column: 'updated_by_id' if foreign_key_exists? 'macros', 'users', column: 'updated_by_id'

    Migration::RemoveStaleNotificationsJob.perform_later
  end
end
